# build-GITPATH is now set by vbuild-nightly.sh to avoid duplication

mkinitrd-GITPATH		:= git://git.verivue.com/planetlab/mkinitrd.git@mkinitrd-5.1.19.6-2
linux-2.6-BRANCH                := rhel6
linux-2.6-GITPATH               := git://git.verivue.com/planetlab/linux-2.6.git@linux-2.6-32-15
madwifi-GITPATH                 := git://git.verivue.com/planetlab/madwifi.git@madwifi-4132-2
util-vserver-GITPATH            := git://git.verivue.com/planetlab/util-vserver.git@util-vserver-0.30.216-15
util-vserver-BUILD-FROM-SRPM	:= yes     # tmp
util-vserver-pl-GITPATH         := git://git.verivue.com/planetlab/util-vserver-pl.git@util-vserver-pl-0.4-25
libnl-SVNPATH			:= http://svn.planet-lab.org/svn/libnl/tags/libnl-1.1-2
nodeupdate-GITPATH		:= git://git.verivue.com/planetlab/nodeupdate.git@nodeupdate-0.5-8
nodemanager-GITPATH		:= git://git.verivue.com/planetlab/nodemanager@nodemanager-1.8-38
pyplnet-GITPATH                 := git://git.verivue.com/planetlab/pyplnet@pyplnet-4.3-9
codemux-GITPATH                 := git://git.verivue.com/planetlab/codemux.git@CoDemux-0.1-13
iptables-BUILD-FROM-SRPM        := yes # tmp
iptables-GITPATH                := git://git.verivue.com/planetlab/iptables.git@iptables-1.4.10-4
iproute-BUILD-FROM-SRPM         := yes # tmp
iproute2-GITPATH                := git://git.verivue.com/planetlab/iproute2.git@iproute2-2.6.35-0
inotify-tools-SVNPATH		:= http://svn.planet-lab.org/svn/inotify-tools/tags/inotify-tools-3.13-2
vsys-BRANCH			:= 0.9
vsys-GITPATH			:= git://git.verivue.com/planetlab/vsys.git@vsys-0.9-4
vsys-scripts-GITPATH            := git://git.verivue.com/planetlab/vsys-scripts.git@vsys-scripts-0.95-18
plcapi-GITPATH			:= git://git.verivue.com/planetlab/plcapi@plcapi-4.3-38
drupal-SVNPATH			:= http://svn.planet-lab.org/svn/drupal/tags/drupal-4.7-14
plewww-GITPATH                  := git://git.verivue.com/planetlab/plewww@PLEWWW-4.3-53
pcucontrol-GITPATH              := git://git.verivue.com/planetlab/pcucontrol.git@pcucontrol-1.0-2
nodeconfig-GITPATH              := git://git.verivue.com/planetlab/nodeconfig.git@nodeconfig-4.3-9
bootmanager-BRANCH		:= 4.3
bootmanager-GITPATH		:= git://git.verivue.com/planetlab/bootmanager@bootmanager-4.3-24
pypcilib-GITPATH                := git://git.verivue.com/planetlab/pypcilib.git@pypcilib-0.2-10
bootcd-GITPATH                  := git://git.verivue.com/planetlab/bootcd.git@bootcd-4.2-25
vserver-reference-GITPATH	:= git://git.verivue.com/planetlab/vserver-reference@vserver-reference-4.2-18
bootstrapfs-GITPATH             := git://git.verivue.com/planetlab/bootstrapfs.git@BootstrapFS-1.0-12
myplc-GITPATH                   := git://git.verivue.com/planetlab/myplc@myplc-4.3-47
pyopenssl-SVNPATH		:= http://svn.planet-lab.org/svn/pyopenssl/tags/pyopenssl-0.9-1

# locating the right test directory - see make tests_gitpath
tests-GITPATH			:= git://git.verivue.com/tests.git@verivue
