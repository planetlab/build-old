#!/usr/bin/python
# Script to read build configs in /etc/build_conf.py, turn the configuration into command lines and execute it

import os
import re

# Assemble a list of builds from a single build spec
def interpret_build(concrete_build_list, build, param_names, current_concrete_build={}, concrete_build_list=[]):
        
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
            -b %(pldistro)s-%(fcdistro)s-%(arch)s-%(myplcversion)s-%(release)s-%(date)s
            -f %(fcdistro)s 
            -m %(mailto)s 
            -p %(personality)s
            -r %(webpath)s
            -s %(svnpath)s
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
def process_builds (builds, build_names, default_build):
        for build_name in build_names:
                import pdb
                pdb.set_trace()
                build = complete_build_spec_with_defaults (builds[build_name], default_build)
                concrete_builds_without_deps = interpret_build (build, build.keys(), {}, [])
                concrete_builds = map(reduce_dependencies, concrete_builds_without_deps)
                commandlines = map(concrete_build_to_commandline, concrete_builds)
                print "Number of builds for %s = %d\n"%(build_name,len(commandlines))
                for commandline in commandlines:
                    print commandline
        
def main():
        config_file = '/etc/build-conf-planetlab.py'
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
        
        process_builds(builds, build_names, default_build)


if __name__ == "__main__":
        main()

