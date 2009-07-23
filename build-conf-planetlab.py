#!/usr/bin/python

marcs_trunk_build = {
	'tags':'planetlab-tags.mk',
	'distro':['centos5','f8'],
	'personality':['linux32','linux64'],
	'test': 0,
	'release':'k22',
}
		
sapans_k27_build = {
	'tags':'k27-tags.mk',
	'distro':'centos5',
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

__default_build__ = {

### Simple parameters

	'path':'/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
	'sh':'/bin/bash',
	'mailto':'build@lists.planet-lab.org',
	'build-script':'vbuild-nightly.sh',
	'webpath':'/vservers/build.planet-lab.org/var/www/html/install-rpms/archive',
	'pldistro':'planetlab',
	'date':'2009-07-21',
	'svnpath':'http://svn.planet-lab.org/svn/build/trunk',
    'personality':'linux32',
    'myplcversion':'4.3',


### Parameters with dependencies: define paramater mappings as lambdas here

    'arch':lambda build: __personality_to_arch__[build['personality']],
    'runtests':lambda build: __flag_to_test__[build['test']],
    'vbuildnightly':lambda build: __check_out_build_script__(build)

}
