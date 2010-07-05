# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

linux-2.6-SVNPATH		:= http://svn.planet-lab.org/svn/linux-2.6/branches/rhel6
madwifi-SVNPATH			:= http://svn.planet-lab.org/svn/madwifi/tags/madwifi-4099-0
iptables-SVNPATH		:= http://svn.planet-lab.org/svn/iptables/tags/iptables-1.4.8-0
iptables-BUILD-FROM-SRPM := yes	# tmp
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.33-2
iproute-BUILD-FROM-SRPM := yes	# tmp
util-vserver-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver/tags/util-vserver-0.30.216-3
util-vserver-BUILD-FROM-SRPM := yes	# tmp
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
util-vserver-pl-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver-pl/tags/util-vserver-pl-0.4-13
NodeUpdate-SVNPATH		:= http://svn.planet-lab.org/svn/NodeUpdate/tags/NodeUpdate-0.5-6
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
NodeManager-SVNPATH		:= http://svn.planet-lab.org/svn/NodeManager/tags/NodeManager-2.0-15
# Trellis-specific NodeManager plugins
NodeManager-topo-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-topo/trunk
NodeManager-optin-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-optin/trunk
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
CoDemux-SVNPATH			:= http://svn.planet-lab.org/svn/CoDemux/tags/CoDemux-0.1-14
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-2
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-BRANCH			:= 0.9
vsys-GITPATH			:= git://git.onelab.eu/vsys.git@vsys-0.9-5
vsys-scripts-GITPATH		:= git://git.onelab.eu/vsys-scripts@vsys-scripts-0.95-19
plcapi-GITPATH                  := git://git.onelab.eu/plcapi@PLCAPI-5.0-12
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-13
plewww-GITPATH			:= git://git.onelab.eu/plewww@plewww-4.3-46
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-3
pcucontrol-SVNPATH		:= http://svn.planet-lab.org/svn/pcucontrol/tags/pcucontrol-1.0-7
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn/Monitor/tags/Monitor-3.0-35
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
###
pyaspects-SVNPATH		:= http://svn.planet-lab.org/svn/pyaspects/tags/pyaspects-0.3-2
ejabberd-SVNPATH		:= http://svn.planet-lab.org/svn/ejabberd/tags/ejabberd-2.1.3-1
omf-GITPATH			:= git://git.onelab.eu/omf@omf-5.3-5
###
sfa-SVNPATH			:= http://svn.planet-lab.org/svn/sfa/tags/sfa-0.9-14
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/tags/nodeconfig-5.0-2
BootManager-SVNPATH		:= http://svn.planet-lab.org/svn/BootManager/tags/BootManager-5.0-5
pypcilib-SVNPATH		:= http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-9
pyplnet-SVNPATH			:= http://svn.planet-lab.org/svn/pyplnet/tags/pyplnet-4.3-6
BootCD-SVNPATH			:= http://svn.planet-lab.org/svn/BootCD/tags/BootCD-5.0-4
VserverReference-SVNPATH	:= http://svn.planet-lab.org/svn/VserverReference/tags/VserverReference-5.0-3
BootstrapFS-SVNPATH		:= http://svn.planet-lab.org/svn/BootstrapFS/tags/BootstrapFS-2.0-6
MyPLC-SVNPATH			:= http://svn.planet-lab.org/svn/MyPLC/tags/MyPLC-5.0-6
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1

# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.onelab.eu/tests.git@tests-5.0-7
