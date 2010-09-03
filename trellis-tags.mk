# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

# trying the 2.6.27 kernel
# VINI is running a prototype of a 2.6.27-based PlanetLab node (aka Trellis)
# Below we include a few Trellis versions of packages 
linux-2.6-SVNPATH		:= http://svn.planet-lab.org/svn/linux-2.6/trunk
madwifi-SVNPATH			:= http://svn.planet-lab.org/svn/madwifi/tags/madwifi-3878-0
# Trellis is using a modified util-vserver and util-vserver-pl with the 2.6.27 kernel
util-vserver-BRANCH		:= trellis
util-vserver-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver/branches/trellis
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
util-vserver-pl-BRANCH	:= trellis
util-vserver-pl-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver-pl/branches/trellis
NodeUpdate-SVNPATH		:= http://svn.planet-lab.org/svn/NodeUpdate/tags/NodeUpdate-0.5-6
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
NodeManager-SVNPATH             := http://svn.planet-lab.org/svn/NodeManager/tags/NodeManager-1.8-23
# Trellis-specific NodeManager plugins 
NodeManager-topo-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-topo/trunk
NodeManager-optin-SVNPATH	:= http://svn.planet-lab.org/svn/NodeManager-optin/trunk
pyplnet-SVNPATH			:= http://svn.planet-lab.org/svn/pyplnet/tags/pyplnet-4.3-4
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
CoDemux-SVNPATH			:= http://svn.planet-lab.org/svn/CoDemux/tags/CoDemux-0.1-14
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-2
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
iptables-SVNPATH		:= http://svn.planet-lab.org/svn/iptables/trunk
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.16-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-BRANCH			:= 0.9
vsys-GITPATH			:= git://git.onelab.eu/vsys@vsys-0.9-4
vsys-scripts-GITPATH            := git://git.onelab.eu/vsys-scripts@vsys-scripts-0.95-20
PLCAPI-SVNPATH                  := http://svn.planet-lab.org/svn/PLCAPI/tags/PLCAPI-4.3-33
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-14
PLEWWW-GITPATH                  := git://git.onelab.eu/plewww@plewww-4.3-48
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn//Monitor/tags/Monitor-3.0-30/
pcucontrol-SVNPATH		:= http://svn.planet-lab.org/svn/pcucontrol/tags/pcucontrol-1.0-4/
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/tags/nodeconfig-4.3-7
BootManager-SVNPATH		:= http://svn.planet-lab.org/svn/BootManager/tags/BootManager-4.3-13
pypcilib-SVNPATH		:= http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-9
BootCD-SVNPATH			:= http://svn.planet-lab.org/svn/BootCD/tags/BootCD-4.2-17
VserverReference-SVNPATH	:= http://svn.planet-lab.org/svn/VserverReference/tags/VserverReference-4.2-16
BootstrapFS-SVNPATH		:= http://svn.planet-lab.org/svn/BootstrapFS/tags/BootstrapFS-1.0-11
MyPLC-SVNPATH                   := http://svn.planet-lab.org/svn/MyPLC/tags/MyPLC-4.3-37
sfa-SVNPATH                     := http://svn.planet-lab.org/svn/sfa/tags/sfa-0.9-14
pyopenssl-SVNPATH               := http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
PLCRT-SVNPATH                   := http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-10

# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.onelab.eu/tests.git@tests-4.3-6
