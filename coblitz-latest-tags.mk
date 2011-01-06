# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

linux-2.6-BRANCH                := rhel6
linux-2.6-GITPATH               := git://git.planet-lab.org/linux-2.6.git@linux-2.6-32-5
madwifi-BRANCH			:= 0.9.4
madwifi-SVNPATH			:= http://svn.planet-lab.org/svn/madwifi/tags/madwifi-0.9.4-3
util-vserver-GITPATH            := git://git.planet-lab.org/util-vserver.git@util-vserver-0.30.216-10
util-vserver-BUILD-FROM-SRPM 	:= yes     # tmp
util-vserver-pl-GITPATH         := git://git.planet-lab.org/util-vserver-pl.git@util-vserver-pl-0.4-21
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
nodeupdate-GITPATH		:= git://git.planet-lab.org/nodeupdate.git@nodeupdate-0.5-7
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
nodemanager-GITPATH     	:= git://git.planet-lab.org/nodemanager@nodemanager-1.8-29
pyplnet-GITPATH                 := git://git.planet-lab.org/pyplnet@pyplnet-4.3-7
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
CoDemux-SVNPATH			:= http://svn.planet-lab.org/svn/CoDemux/tags/CoDemux-0.1-13
fprobe-ulog-SVNPATH		:= http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-1
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
iptables-BRANCH			:= 1.3.8
iptables-SVNPATH		:= http://svn.planet-lab.org/svn/iptables/tags/iptables-1.3.8-12
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.16-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-BRANCH			:= 0.9
vsys-SVNPATH			:= http://svn.planet-lab.org/svn/vsys/tags/vsys-0.9-4
vsys-scripts-SVNPATH		:= http://svn.planet-lab.org/svn/vsys-scripts/tags/vsys-scripts-0.95-18
plcapi-GITPATH			:= git://git.planet-lab.org/plcapi@plcapi-4.3-36
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-14
plewww-GITPATH                  := git://git.onelab.eu/plewww.git@plewww-4.3-53
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn//Monitor/tags/Monitor-3.0-30/
pcucontrol-SVNPATH		:= http://svn.planet-lab.org/svn/pcucontrol/tags/pcucontrol-1.0-2/
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/tags/nodeconfig-4.3-7
BootManager-BRANCH		:= 4.3
bootmanager-GITPATH		:= git://git.planet-lab.org/bootmanager@bootmanager-4.3-19
pypcilib-SVNPATH		:= http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-9
BootCD-SVNPATH			:= http://svn.planet-lab.org/svn/BootCD/tags/BootCD-4.2-17
vserverreference-GITPATH	:= git://git.planet-lab.org/vserver-reference@vserver-reference-5.0-5
BootstrapFS-SVNPATH		:= http://svn.planet-lab.org/svn/BootstrapFS/tags/BootstrapFS-1.0-11
myplc-GITPATH                   := git://git.planet-lab.org/myplc@myplc-4.3-41
sfa-SVNPATH			:= http://svn.planet-lab.org/svn/sfa/tags/sfa-0.9-14
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11

# locating the right test directory - see make tests_gitpath
tests-GITPATH			:= git://git.onelab.eu/tests.git@tests-4.3-6
