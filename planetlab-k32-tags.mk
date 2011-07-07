# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

mkinitrd-GITPATH		:= git://git.planet-lab.org/mkinitrd.git@mkinitrd-5.1.19.6-2
linux-2.6-BRANCH		:= rhel6
linux-2.6-GITPATH		:= git://git.planet-lab.org/linux-2.6.git@linux-2.6-32-22
# help out spec2make on f8 and centos5, due to a bug in rpm
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 centos5)"
kernel-WHITELIST-RPMS	:= kernel-devel,kernel-headers
endif
kernel-DEVEL-RPMS		+= elfutils-libelf-devel
madwifi-GITPATH                 := git://git.planet-lab.org/madwifi.git@madwifi-4132-2
iptables-GITPATH                := git://git.planet-lab.org/iptables.git@iptables-1.4.10-4
iproute2-GITPATH                := git://git.planet-lab.org/iproute2.git@iproute2-2.6.37-2
util-vserver-GITPATH		:= git://git.planet-lab.org/util-vserver.git@util-vserver-0.30.216-17
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
util-vserver-pl-GITPATH		:= git://git.planet-lab.org/util-vserver-pl.git@util-vserver-pl-0.4-26
nodeupdate-GITPATH		:= git://git.planet-lab.org/nodeupdate.git@nodeupdate-0.5-9
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
nodemanager-GITPATH             := git://git.planet-lab.org/nodemanager.git@nodemanager-2.0-32
# Trellis-specific NodeManager plugins
NodeManager-topo-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-topo/trunk
NodeManager-optin-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-optin/trunk
#
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
codemux-GITPATH			:= git://git.planet-lab.org/codemux.git@codemux-0.1-15
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-2
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-4
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
openvswitch-GITPATH			:= git://git.planet-lab.org/openvswitch.git
vsys-GITPATH			:= git://git.planet-lab.org/vsys.git@vsys-0.99-1
vsys-scripts-GITPATH		:= git://git.planet-lab.org/vsys-scripts@vsys-scripts-0.95-29
plcapi-GITPATH                  := git://git.planet-lab.org/plcapi@plcapi-5.0-33
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-14
plewww-GITPATH			:= git://git.planet-lab.org/plewww@plewww-4.3-65
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
monitor-GITPATH			:= git://git.planet-lab.org/monitor@monitor-3.1-4
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
###
pyaspects-GITPATH		:= git://git.planet-lab.org/pyaspects.git@pyaspects-0.4.1-1
ejabberd-GITPATH		:= git://git.planet-lab.org/ejabberd.git@ejabberd-2.1.6-2
omf-GITPATH                     := git://git.onelab.eu/omf.git@omf-5.3-10
###
sfa-GITPATH                     := git://git.planet-lab.org/sfa.git@sfa-1.0-26
nodeconfig-GITPATH		:= git://git.planet-lab.org/nodeconfig.git@nodeconfig-5.0-5
bootmanager-GITPATH             := git://git.planet-lab.org/bootmanager.git@bootmanager-5.0-20
pypcilib-GITPATH		:= git://git.planet-lab.org/pypcilib.git@pypcilib-0.2-10
pyplnet-GITPATH                 := git://git.planet-lab.org/pyplnet.git@pyplnet-4.3-9
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1
pcucontrol-GITPATH              := git://git.planet-lab.org/pcucontrol.git@pcucontrol-1.0-11
bootcd-GITPATH                  := git://git.planet-lab.org/bootcd.git@bootcd-5.0-10
vserver-reference-GITPATH       := git://git.planet-lab.org/vserver-reference.git@vserver-reference-5.0-6
bootstrapfs-GITPATH             := git://git.planet-lab.org/bootstrapfs.git@bootstrapfs-2.0-12
myplc-GITPATH                   := git://git.planet-lab.org/myplc.git@myplc-5.0-18
# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.planet-lab.org/tests.git@tests-5.0-27
