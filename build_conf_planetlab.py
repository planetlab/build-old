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
# Defaults: Any values that you leave out from the above specs will get filled in by the defaults specified below
#
#

personality_to_arch={'linux32':'i386','linux64':'x86_64'}

__default_build__ = {
	'path':'/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
	'sh':'/bin/bash',
	'mailto':'build@lists.planet-lab.org',
	'build-script':'vbuild-nightly.sh',
	'webpath':'/vservers/build.planet-lab.org/var/www/html/install-rpms/archive',
	'pldistro':'planetlab',
	'date':'2009-07-21',
	'svnpath':'http://svn.planet-lab.org/svn/build/trunk',
    'personality':'linux32',
### Define lambdas at the end, because they may need the above values to be filled in for their evaluation
    'arch':lambda build: personality_to_arch[concrete_build['personality']]
}

