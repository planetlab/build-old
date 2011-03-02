# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

###
linux-2.6-GITPATH		:= git://git.onelab.eu/linux-2.6.git@linux-2.6-27-34
madwifi-GITPATH                 := git://git.onelab.eu/madwifi.git@madwifi-4132-2
iptables-GITPATH                := git://git.onelab.eu/iptables.git@iptables-1.4.10-3
iptables-BUILD-FROM-SRPM        := yes	# tmp
iproute-BUILD-FROM-SRPM := yes	
iproute2-GITPATH		:= git://git.onelab.eu/iproute2.git@iproute2-2.6.35-0
###
ipfw-GITPATH                    := git://git.onelab.eu/ipfw.git@ipfw-0.9-20
###
comgt-SVNPATH			:= http://svn.onelab.eu/comgt/imports/0.3
planetlab-umts-tools-GITPATH    := git://git.onelab.eu/planetlab-umts-tools.git@planetlab-umts-tools-0.6-6
###
util-vserver-BUILD-FROM-SRPM := yes # tmp
util-vserver-GITPATH		:= git://git.onelab.eu/util-vserver.git@util-vserver-0.30.216-14
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
# as per http://svn.planet-lab.org/changeset/17973, 2.6.22 kernels shall use 0.3 branch and 2.6.27 need 0.4
util-vserver-pl-GITPATH		:= git://git.onelab.eu/util-vserver-pl.git@util-vserver-pl-0.4-23
nodeupdate-GITPATH		:= git://git.onelab.eu/nodeupdate.git@nodeupdate-0.5-8
PingOfDeath-SVNPATH		:= http://svn.planet-lab.org/svn/PingOfDeath/tags/PingOfDeath-2.2-1
nodemanager-GITPATH             := git://git.onelab.eu/nodemanager.git@nodemanager-2.0-29
pl_sshd-SVNPATH			:= http://svn.planet-lab.org/svn/pl_sshd/tags/pl_sshd-1.0-11
codemux-GITPATH			:= git://git.onelab.eu/codemux.git@codemux-0.1-15
fprobe-ulog-SVNPATH             := http://svn.planet-lab.org/svn/fprobe-ulog/tags/fprobe-ulog-1.1.3-2
pf2slice-SVNPATH		:= http://svn.planet-lab.org/svn/pf2slice/tags/pf2slice-1.0-2
Mom-SVNPATH			:= http://svn.planet-lab.org/svn/Mom/tags/Mom-2.3-2
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
openvswitch-GITPATH		:= git://git.onelab.eu/openvswitch.git@openvswitch-1.1.0pre2-1
vsys-GITPATH			:= git://git.onelab.eu/vsys.git@vsys-0.99-1
vsys-scripts-GITPATH            := git://git.onelab.eu/vsys-scripts.git@vsys-scripts-0.95-28
plcapi-GITPATH                  := git://git.onelab.eu/plcapi.git@plcapi-5.0-29
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-14
plewww-GITPATH                  := git://git.onelab.eu/plewww.git@plewww-4.3-61
www-register-wizard-SVNPATH     := http://svn.planet-lab.org/svn/www-register-wizard/tags/www-register-wizard-4.3-5
pcucontrol-GITPATH              := git://git.onelab.eu/pcucontrol.git@pcucontrol-1.0-10
Monitor-SVNPATH			:= http://svn.planet-lab.org/svn/Monitor/tags/Monitor-3.0-35
PLCRT-SVNPATH			:= http://svn.planet-lab.org/svn/PLCRT/tags/PLCRT-1.0-11
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1
###
pyaspects-GITPATH		:= git://git.onelab.eu/pyaspects.git@pyaspects-0.4.1-1
ejabberd-GITPATH		:= git://git.onelab.eu/ejabberd.git@ejabberd-2.1.3-2
omf-GITPATH                     := git://git.onelab.eu/omf.git@omf-5.3-10
oml-GITPATH                     := git://git.onelab.eu/oml.git@oml-2.5.1-1
###
sfa-GITPATH                     := git://git.onelab.eu/sfa.git@sfa-1.0-14
sface-GITPATH                   := git://git.onelab.eu/sface.git@sface-0.1-4
nodeconfig-GITPATH              := git://git.onelab.eu/nodeconfig.git@nodeconfig-5.0-5
bootmanager-GITPATH             := git://git.onelab.eu/bootmanager.git@bootmanager-5.0-17
pypcilib-GITPATH		:= git://git.onelab.eu/pypcilib.git@pypcilib-0.2-9
pyplnet-GITPATH			:= git://git.onelab.eu/pyplnet.git@pyplnet-4.3-9
bootcd-GITPATH                  := git://git.onelab.eu/bootcd.git@bootcd-5.0-9
vserver-reference-GITPATH        := git://git.onelab.eu/vserver-reference.git@vserver-reference-5.0-6
bootstrapfs-GITPATH             := git://git.onelab.eu/bootstrapfs.git@bootstrapfs-2.0-10
myplc-GITPATH                   := git://git.onelab.eu/myplc.git@myplc-5.0-15
DistributedRateLimiting-SVNPATH	:= http://svn.planet-lab.org/svn/DistributedRateLimiting/tags/DistributedRateLimiting-0.1-1

# locating the right test directory - see make tests_gitpath
tests-GITPATH                   := git://git.onelab.eu/tests.git@tests-5.0-24

### temporary
# nozomi not needed anymore for 2.6.27
ALL:=$(subst nozomi,,$(ALL))
IN_BOOTSTRAPFS:=$(subst nozomi,,$(IN_BOOTSTRAPFS))
