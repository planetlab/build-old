#!/usr/bin/python
# This script makes the declaration of builds declarative. In the past, our build system involved constructing a set of command lines
# that would get executed with parameters such as the name of the distribution, the kernel version and so on. Unfortunately, the code
# that went into creating these command lines was shared between people and often when someone modified his build, other builds would 
# break. With this script, each build is declared as a Python dict, such as in the following example:
#
# caglars_k32_build = {
#         'tags':'planetlab-k32-tags.mk',
#         'fcdistro':['centos5', 'f12','f8'],
#         'personality':['linux32','linux64'],
#         'test':0,
#         'release':'k32'
# }
#
# This declaration corresponds to 6 builds - with static values of 'tags', 'test' and 'release' and every combination of the values provided for
# 'fcdistro' and 'personality', i.e. 3x2. 
#
# More complex dependencies can be added, e.g. to build linux64 only for f12, you can set the values of the options to functions:
#
# caglars_k32_build = {
#         'tags':'planetlab-k32-tags.mk',
#         'fcdistro':['centos5', 'f12','f8'],
#         'personality': lambda build: if (build['fcdistro']=='f12') then return ['linux32', 'linux64'] else return ['linux32']
#         'test':0,
#         'release':'k32'
# }
#
# Naturally, you can achieve the same result by breaking the above declaration into two dicts, rather than using only one


import os
import re
import shlex
import subprocess
import time
from optparse import OptionParser

PARALLEL_BUILD = False

# Assemble a list of builds from a single build spec
def interpret_build(build, param_names, current_concrete_build={}, concrete_build_list=[]):
    if (param_names==[]):
        concrete_build_list.extend([current_concrete_build])
    else:
        (cur_param_name,remaining_param_names)=(param_names[0],param_names[1:])
        cur_param = build[cur_param_name]

        # If it's a list, produce a concrete build for each element of the list
        if (type(cur_param)==type([])):
            for value in cur_param:
                new_concrete_build = current_concrete_build.copy()
                new_concrete_build[cur_param_name] = value
                concrete_build_list = interpret_build(build, remaining_param_names, new_concrete_build, concrete_build_list)

        # If not, just tack on the value and move on
        else:
            current_concrete_build[cur_param_name] = cur_param
            concrete_build_list = interpret_build(build, remaining_param_names, current_concrete_build,concrete_build_list)

    return concrete_build_list


# Fill in parameters that are not defined in __default_build__
def complete_build_spec_with_defaults (build, default_build):
    for default_param in default_build.keys():
        if (not build.has_key(default_param)):
            build[default_param]=default_build[default_param]
    return build


# Turn a concrete build into a commandline

def concrete_build_to_commandline(concrete_build):

    cmdline = '''%(sh)s 
        %(vbuildnightly)s
        -b pl-%(fcdistro)s-%(arch)s-%(myplcversion)s-%(release)s-%(date)s
        -f %(fcdistro)s 
        -m %(mailto)s 
        -p %(personality)s
        -r %(webpath)s
        -s %(scmpath)s
        -t %(tags)s
        -w %(webpath)s/%(pldistro)s/%(fcdistro)s
        %(runtests)s'''.replace('\n','')

    cmdline = cmdline % concrete_build

    purge_spaces = re.compile('\s+')

    return purge_spaces.sub(' ', cmdline)


# reduce dependencies in a build 
def reduce_dependencies(concrete_build):
    for b in concrete_build.keys():
        val = concrete_build[b]
        if (type(val)==type(lambda x:x)):
            concrete_build[b] = val(concrete_build)
    return concrete_build


# Turn build parameter dicts into commandlines and execute them
def process_builds (builds, build_names, default_build, options):
    for build_name in build_names:
        build = complete_build_spec_with_defaults (builds[build_name], default_build)
        concrete_builds_without_deps = interpret_build (build, build.keys(), {}, [])
        concrete_builds = map(reduce_dependencies, concrete_builds_without_deps)
        commandlines = map(concrete_build_to_commandline, concrete_builds)
        for commandline in commandlines:
            if PARALLEL_BUILD == True:
                args = shlex.split(commandline)
                subprocess.Popen(args)
                # work around the vserver race
                time.sleep(60)
            else:       
                if (build_name.startswith(options.prefix) and not options.pretend):
                    os.system(commandline)
                else:
                    print "### Skipping the following build###\n"
                    print commandline

def main():
    parser = OptionParser()
    parser.add_option("-c", "--config-file", dest="config_file",
                  help="Config file with build declarations", metavar="FILE", default = '/etc/build-conf-planetlab.py')
    parser.add_option("-p", "--pretend",
                  dest="pretend", default=False, action="store_true",
                  help="don't run only print")

    parser.add_option("-o", "--only-build", dest="prefix",
                  help="Only build declarations starting with this prefix", metavar="PREFIX", default = '')

    (options, args) = parser.parse_args ()

    config_file = options.config_file

    builds = {}
    try:
        execfile(config_file, builds)
    except IOError, e:
        raise IOError, "Could not open %s\n" % config_file


    config_file_attributes = builds.keys()
    build_names = [e for e in config_file_attributes if not e.startswith('__')]     

    try:
        default_build = builds['__default_build__']
    except KeyError:
        raise KeyError, "Please define the default build config in %s\n" % config_file

    process_builds(builds, build_names, default_build, options)


if __name__ == "__main__":
    main()

