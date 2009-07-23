#!/usr/bin/python

###
# Nightly build spec HOWTO
#
# *  To add a 'build spec', define a dictionary as in the following examples, filling in the values you would like to override in the defaults. Any values you leave out
# will get picked up from the defaults at the bottom of this fiel.
#
# *  A build spec may define multiple builds encapsulating various combinations of the available parameter options. To do so, 
# set a parameter to a list, and the parent script will automatically turn it into the combinations it encloses. e.g., the following
# build spec defines 6 separate builds:
#
# my_build = {
#   'fcdistro':['centos5','f8','f10'],
#   'personality':['linux32','linux65']
#
# * If your parameters have dependencies - e.g. you only want to build the linu64 personality on f10, then define the parameter as a lambda operating
# on the current build spec. e.g. in this case, it would be to the effect of lambda (build): if (build['fcdistro']=='f10') then ['linux32','linux64'] else ['linux32']
#


marcs_trunk_build = {
	'tags':'planetlab-tags.mk',
	'fcdistro':['centos5','f8'],
	'personality':['linux32','linux64'],
	'test': 0,
	'release':'k22',
}
		
sapans_k27_build = {
	'tags':'k27-tags.mk',
	'fcdistro':'centos5',
	'personality':'linux32',
	'test':1,
	'release':'k27'
}

###
#
# DEFAULTS 
#
# Any values that you leave out from the above specs will get filled in by the defaults specified below.
# You shouldn't need to modify these values to add new builds

__personality_to_arch__={'linux32':'i386','linux64':'x86_64'}
__flag_to_test__={0:'-B', 1:''}

def __check_out_build_script__(build):
    import os
    tmpname = os.popen('mktemp /tmp/'+build['build-script']+'.XXXXXX').read().rstrip('\n')
    os.system("svn cat %s/%s > %s 2>/dev/null"%(build['svnpath'],build['build-script'],tmpname))
    return tmpname

def __today__():
    import datetime
    return datetime.datetime.now().strftime("%Y-%m-%d")

__default_build__ = {

### Simple parameters
    'tags':'planetlabs-tags.mk',
    'fcdistro':'centos5',
    'personality':'linux32',
    'test':0,
    'release':'k22',
	'path':'/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
	'sh':'/bin/bash',
	'mailto':'build@lists.planet-lab.org',
	'build-script':'vbuild-nightly.sh',
	'webpath':'/vservers/build.planet-lab.org/var/www/html/install-rpms/archive',
	'pldistro':'planetlab',
	'date': __today__(),
	'svnpath':'http://svn.planet-lab.org/svn/build/trunk',
    'personality':'linux32',
    'myplcversion':'4.3',


### Parameters with dependencies: define paramater mappings as lambdas here

    'arch':lambda build: __personality_to_arch__[build['personality']],
    'runtests':lambda build: __flag_to_test__[build['test']],
    'vbuildnightly':lambda build: __check_out_build_script__(build)

}
