# $Id$
# $URL$

# build-SVNPATH is now set by vbuild-nightly.sh to avoid duplication

linux-2.6-SVNPATH		:= http://svn.planet-lab.org/svn/linux-2.6/trunk
# this should build
ipfwsrc-SVNPATH                 := http://svn.planet-lab.org/svn/ipfw/tags/ipfw-0.9-9
madwifi-SVNPATH			:= http://svn.planet-lab.org/svn/madwifi/tags/madwifi-4099-0
# nozomi not needed anymore for 2.6.27
ALL:=$(subst nozomi,,$(ALL))
IN_BOOTSTRAPFS:=$(subst nozomi,,$(IN_BOOTSTRAPFS))
#
comgt-SVNPATH			:= http://svn.onelab.eu/comgt/imports/0.3
planetlab-umts-tools-SVNPATH	:= http://svn.onelab.eu/planetlab-umts-tools/tags/planetlab-umts-tools-0.6-4
util-vserver-SVNBRANCH		:= scholz
util-vserver-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver/tags/util-vserver-0.30.215-6
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
util-vserver-pl-SVNPATH         := http://svn.planet-lab.org/svn/util-vserver-pl/tags/util-vserver-pl-0.3-21
NodeUpdate-SVNPATH		:= http://svn.planet-lab.org/svn/NodeUpdate/trunk
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
NodeManager-SVNPATH             := http://svn.planet-lab.org/svn/NodeManager/trunk
pyplnet-SVNPATH			:= http://svn.planet-lab.org/svn/pyplnet/tags/pyplnet-4.3-4
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
CoDemux-SVNPATH			:= http://svn.planet-lab.org/svn/CoDemux/tags/CoDemux-0.1-13
fprobe-ulog-SVNPATH		:= http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-0
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
iptables-SVNPATH		:= http://svn.planet-lab.org/svn/iptables/tags/iptables-1.4.1.1-1
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.16-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-SVNBRANCH			:= 0.9
vsys-SVNPATH                    := http://svn.planet-lab.org/svn/vsys/tags/vsys-0.9-4
vsys-scripts-SVNPATH		:= http://svn.planet-lab.org/svn/vsys-scripts/tags/vsys-scripts-0.95-14
dummynet_image-SVNPATH		:= http://svn.planet-lab.org/svn/dummynet_image/tags/dummynet_image-1.0-5
PLCAPI-SVNPATH                  := http://svn.planet-lab.org/svn/PLCAPI/trunk
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-13
PLEWWW-SVNPATH                  := http://svn.planet-lab.org/svn/PLEWWW/tags/PLEWWW-4.3-41
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-1
pcucontrol-SVNPATH		:= http://svn.planet-lab.org/svn/pcucontrol/trunk
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn/Monitor/tags/Monitor-3.0-30
nodeconfig-MODULES := nodeconfig
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/trunk
BootManager-SVNPATH             := http://svn.planet-lab.org/svn/BootManager/trunk
pypcilib-SVNPATH                := http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-9
BootCD-SVNPATH                  := http://svn.planet-lab.org/svn/BootCD/trunk
VserverReference-SVNPATH	:= http://svn.planet-lab.org/svn/VserverReference/trunk
BootstrapFS-SVNPATH             := http://svn.planet-lab.org/svn/BootstrapFS/trunk
# latest trunk do not need build anymore
myplc-MODULES := MyPLC
MyPLC-SVNPATH                   := http://svn.planet-lab.org/svn/MyPLC/trunk
sfa-SVNPATH                     := http://svn.planet-lab.org/svn/sfa/tags/sfa-0.9-10
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11

# locating the right test directory - see make tests_svnpath
tests-SVNPATH                   := http://svn.planet-lab.org/svn/tests/trunk
