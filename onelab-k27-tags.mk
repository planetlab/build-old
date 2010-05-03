# $Id$
# $URL$

# build-SVNPATH is now set by vbuild-nightly.sh to avoid duplication

linux-2.6-SVNPATH		:= http://svn.planet-lab.org/svn/linux-2.6/tags/linux-2.6-27-9
madwifi-SVNPATH			:= http://svn.planet-lab.org/svn/madwifi/tags/madwifi-4099-0
iptables-SVNPATH                := http://svn.planet-lab.org/svn/iptables/tags/iptables-1.4.7-2
iptables-BUILD-FROM-SRPM := yes	# tmp
iproute2-SVNPATH		:= http://svn.planet-lab.org/svn/iproute2/tags/iproute2-2.6.16-2
###
ipfw-SVNPATH			:= http://svn.planet-lab.org/svn/ipfw/tags/ipfw-0.9-14
comgt-SVNPATH			:= http://svn.onelab.eu/comgt/imports/0.3
planetlab-umts-tools-SVNPATH	:= http://svn.onelab.eu/planetlab-umts-tools/tags/planetlab-umts-tools-0.6-4
###
util-vserver-SVNBRANCH		:= scholz
util-vserver-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver/tags/util-vserver-0.30.215-6
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
util-vserver-pl-SVNPATH		:= http://svn.planet-lab.org/svn/util-vserver-pl/tags/util-vserver-pl-0.3-23
NodeUpdate-SVNPATH		:= http://svn.planet-lab.org/svn/NodeUpdate/tags/NodeUpdate-0.5-6
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
NodeManager-SVNPATH		:= http://svn.planet-lab.org/svn/NodeManager/tags/NodeManager-2.0-6
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
CoDemux-SVNPATH			:= http://svn.planet-lab.org/svn/CoDemux/tags/CoDemux-0.1-14
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-2
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-SVNBRANCH			:= 0.9
vsys-SVNPATH			:= http://svn.planet-lab.org/svn/vsys/tags/vsys-0.9-4
vsys-scripts-SVNPATH		:= http://svn.planet-lab.org/svn/vsys-scripts/tags/vsys-scripts-0.95-17
PLCAPI-SVNPATH			:= http://svn.planet-lab.org/svn/PLCAPI/trunk
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-13
PLEWWW-SVNPATH			:= http://svn.planet-lab.org/svn/PLEWWW/tags/PLEWWW-4.3-44
www-register-wizard-SVNPATH	:= http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-3
pcucontrol-SVNPATH		:= http://svn.planet-lab.org/svn/pcucontrol/tags/pcucontrol-1.0-3
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn/Monitor/tags/Monitor-3.0-33
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
###
pyaspects-SVNPATH		:= http://svn.planet-lab.org/svn/pyaspects/tags/pyaspects-0.3-1
ejabberd-SVNPATH		:= http://svn.planet-lab.org/svn/ejabberd/tags/ejabberd-2.1.3-1
omf-SVNPATH			:= http://svn.planet-lab.org/svn/omf/tags/omf-5.3-2
###
sfa-SVNPATH			:= http://svn.planet-lab.org/svn/sfa/tags/sfa-0.9-10
nodeconfig-SVNPATH		:= http://svn.planet-lab.org/svn/nodeconfig/tags/nodeconfig-5.0-2
BootManager-SVNPATH		:= http://svn.planet-lab.org/svn/BootManager/tags/BootManager-5.0-3
pypcilib-SVNPATH		:= http://svn.planet-lab.org/svn/pypcilib/tags/pypcilib-0.2-9
pyplnet-SVNPATH			:= http://svn.planet-lab.org/svn/pyplnet/tags/pyplnet-4.3-6
BootCD-SVNPATH			:= http://svn.planet-lab.org/svn/BootCD/tags/BootCD-5.0-2
VserverReference-SVNPATH	:= http://svn.planet-lab.org/svn/VserverReference/tags/VserverReference-5.0-2
BootstrapFS-SVNPATH		:= http://svn.planet-lab.org/svn/BootstrapFS/tags/BootstrapFS-2.0-5
MyPLC-SVNPATH			:= http://svn.planet-lab.org/svn/MyPLC/tags/MyPLC-5.0-3
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1

# locating the right test directory - see make tests_svnpath
tests-SVNPATH                   := http://svn.planet-lab.org/svn/tests/tags/tests-5.0-5

### temporary
# nozomi not needed anymore for 2.6.27
ALL:=$(subst nozomi,,$(ALL))
IN_BOOTSTRAPFS:=$(subst nozomi,,$(IN_BOOTSTRAPFS))
