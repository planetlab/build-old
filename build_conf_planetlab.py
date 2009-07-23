#!/usr/bin/python

marcs_trunk_build = {
	'tags':['planetlab-tags.mk'],
	'distro':['centos5','f8'],
	'personality':['linux32','linux64'],
	'test': 0,
	'release':['k22']
}
		
sapans_k27_build = {
	'tags':['k27-tags.mk'],
	'distro':['centos5'],
	'personality':['linux32'],
	'test':1,
	'release':['k27']
}

###
__default_build__ = {
	'path':'/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
	'sh':'/bin/bash',
	'mailto':'build@lists.planet-lab.org',
	'build-script':'vbuild-nightly.sh',
	'webpath':'/vservers/build.planet-lab.org/var/www/html/install-rpms/archive',
	'pldistro':'planetlab',
	'date':'2009-07-21',
	'svnpath':'http://svn.planet-lab.org/svn/build/trunk'
}

