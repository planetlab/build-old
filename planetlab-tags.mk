# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

linux-2.6-BRANCH		:= 22
linux-2.6-GITPATH		:= git://git.onelab.eu/linux-2.6.git@linux-2.6-22-48
madwifi-BRANCH		:= 0.9.4
madwifi-SVNPATH			:= http://svn.planet-lab.org/svn/madwifi/tags/madwifi-0.9.4-3
iptables-BRANCH		:= 1.3.8
iptables-SVNPATH		:= http://svn.planet-lab.org/svn/iptables/tags/iptables-1.3.8-12
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.16-2
util-vserver-BRANCH		:= scholz
util-vserver-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver/tags/util-vserver-0.30.215-6
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
# 2.6.22 kernels need 0.3 branch and 2.6.27 need 0.4 (trunk).
util-vserver-pl-BRANCH		:= 0.3
util-vserver-pl-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver-pl/tags/util-vserver-pl-0.3-31
NodeUpdate-SVNPATH		:= http://svn.planet-lab.org/svn/NodeUpdate/tags/NodeUpdate-0.5-6
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
nodemanager-GITPATH             := git://git.onelab.eu/nodemanager.git@nodemanager-2.0-16
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
codemux-GITPATH			:= git://git.onelab.eu/codemux.git@CoDemux-0.1-14
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-2
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-BRANCH			:= 0.9
vsys-GITPATH			:= git://git.onelab.eu/vsys.git@vsys-0.9-5
vsys-scripts-GITPATH		:= git://git.onelab.eu/vsys-scripts@vsys-scripts-0.95-19
plcapi-GITPATH                  := git://git.onelab.eu/plcapi@PLCAPI-5.0-12
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-13
plewww-GITPATH			:= git://git.onelab.eu/plewww@plewww-4.3-47
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-3
pcucontrol-GITPATH              := git://git.onelab.eu/pcucontrol.git@pcucontrol-1.0-8
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn/Monitor/tags/Monitor-3.0-35
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
###
pyaspects-GITPATH		:= git://git.onelab.eu/pyaspects.git@pyaspects-0.3-2
ejabberd-GITPATH		:= git://git.onelab.eu/ejabberd.git@ejabberd-2.1.3-1
omf-GITPATH			:= git://git.onelab.eu/omf@omf-5.3-6
###
sfa-SVNPATH			:= http://svn.planet-lab.org/svn/sfa/tags/sfa-0.9-14
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/tags/nodeconfig-5.0-2
bootmanager-GITPATH             := git://git.onelab.eu/bootmanager.git@BootManager-5.0-6
pypcilib-SVNPATH		:= http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-9
pyplnet-SVNPATH			:= http://svn.planet-lab.org/svn/pyplnet/tags/pyplnet-4.3-6
bootcd-GITPATH                  := git://git.onelab.eu/bootcd.git@BootCD-5.0-4
vserver-reference-GITPATH        := git://git.onelab.eu/vserver-reference.git@VserverReference-5.0-3
bootstrapfs-GITPATH             := git://git.onelab.eu/bootstrapfs.git@BootstrapFS-2.0-6
myplc-GITPATH                   := git://git.onelab.eu/myplc.git@MyPLC-5.0-7
DistributedRateLimiting-SVNPATH			:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1

# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.onelab.eu/tests.git@tests-5.0-7
