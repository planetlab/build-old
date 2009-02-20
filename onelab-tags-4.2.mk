# $Id$

# SVNBRANCH specifications are not used at build-time, 
# but by modules.update to refresh modules.list 
# that serves as the default for module-tools -a

linux-2.6-SVNBRANCH		:= 22
linux-2.6-SVNPATH		:= http://svn.planet-lab.org/svn/linux-2.6/tags/linux-2.6-22-32
madwifi-SVNPATH                 := http://svn.planet-lab.org/svn/madwifi/tags/madwifi-0.9.4-2
nozomi-SVNPATH			:= http://svn.onelab.eu/nozomi/tags/nozomi-2.21-1
comgt-SVNPATH			:= http://svn.onelab.eu/comgt/imports/0.3
planetlab-umts-tools-SVNPATH	:= http://svn.onelab.eu/planetlab-umts-tools/tags/planetlab-umts-tools-0.5-1
util-vserver-SVNBRANCH		:= scholz
util-vserver-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver/tags/util-vserver-0.30.215-6
util-vserver-pl-SVNPATH         := http://svn.planet-lab.org/svn/util-vserver-pl/tags/util-vserver-pl-0.3-16
NodeUpdate-SVNPATH		:= http://svn.planet-lab.org/svn/NodeUpdate/tags/NodeUpdate-0.5-3
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
NodeManager-SVNBRANCH		:= 1.7
NodeManager-SVNPATH		:= http://svn.planet-lab.org/svn/NodeManager/tags/NodeManager-1.7-43
pyplnet-SVNBRANCH		:= 4.2
pyplnet-SVNPATH			:= http://svn.planet-lab.org/svn/pyplnet/tags/pyplnet-4.2-2
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
CoDemux-SVNPATH			:= http://svn.planet-lab.org/svn/CoDemux/tags/CoDemux-0.1-13
fprobe-ulog-SVNBRANCH		:= 1.1.2
fprobe-ulog-SVNPATH		:= http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.2-6
pf2slice-SVNPATH                := http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNBRANCH			:= 2.2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.2-7
iptables-SVNPATH		:= http://svn.planet-lab.org/svn/iptables/tags/iptables-1.3.8-9
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.16-2
vsys-SVNBRANCH			:= 0.7
vsys-SVNPATH			:= http://svn.planet-lab.org/svn/vsys/tags/vsys-0.7-25
dummynet_image-SVNPATH		:= http://svn.planet-lab.org/svn/dummynet_image/tags/dummynet_image-1.0-4
PLCAPI-SVNBRANCH		:= dummynet
PLCAPI-SVNPATH			:= http://svn.planet-lab.org/svn/PLCAPI/tags/PLCAPI-dummynet-12
PLCWWW-SVNBRANCH		:= onelab.4.2
PLCWWW-SVNPATH			:= http://svn.planet-lab.org/svn/PLCWWW/tags/PLCWWW-onelab.4.2-23
Monitor-SVNBRANCH		:= 1.0
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn/Monitor/tags/Monitor-1.0-13
nodeconfig-SVNBRANCH		:= 4.2
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/tags/nodeconfig-4.2-13
BootManager-SVNBRANCH		:= 3.2
#BootManager-SVNPATH		:= http://svn.planet-lab.org/svn/BootManager/tags/BootManager-3.2-15
BootManager-SVNPATH		:= http://svn.planet-lab.org/svn/BootManager/branches/3.2
pypcilib-SVNPATH		:= http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-5
BootCD-SVNPATH                  := http://svn.planet-lab.org/svn/BootCD/tags/BootCD-4.2-8
VserverReference-SVNPATH	:= http://svn.planet-lab.org/svn/VserverReference/tags/VserverReference-4.2-11
BootstrapFS-SVNPATH		:= http://svn.planet-lab.org/svn/BootstrapFS/tags/BootstrapFS-1.0-6
MyPLC-SVNBRANCH			:= 4.2
MyPLC-SVNPATH                   := http://svn.planet-lab.org/svn/MyPLC/tags/MyPLC-4.2-19
# locating the right test directory - see make testsvnpath
TESTS_SVNPATH			:= http://svn.planet-lab.org/svn/tests/tags/tests-4.2-11
