#
# declare the packages to be built and their dependencies
# initial version from Mark Huang
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2006 The Trustees of Princeton University
# rewritten by Thierry Parmentelat - INRIA Sophia Antipolis
#
# see doc in Makefile  
#

# mkinitrd
#
ifeq "$(PLDISTROTAGS)" "planetlab-k32-tags.mk"
ifeq "$(DISTRONAME)" "centos5"
mkinitrd-MODULES := mkinitrd
mkinitrd-SPEC := mkinitrd.spec
mkinitrd-BUILD-FROM-SRPM := yes
mkinitrd-DEVEL-RPMS += parted-devel glib2-devel libdhcp4client-devel libdhcp6client-devel libdhcp-devel 
mkinitrd-DEVEL-RPMS += device-mapper libselinux-devel libsepol-devel libnl-devel
ALL += mkinitrd
IN_BOOTCD += mkinitrd
IN_VSERVER += mkinitrd 
IN_BOOTSTRAPFS += mkinitrd
IN_MYPLC += mkinitrd
endif
endif
#
# kernel
#
# use a package name with srpm in it:
# so the source rpm is created by running make srpm in the codebase
#

kernel-MODULES := linux-2.6
kernel-SPEC := kernel-2.6.spec
kernel-BUILD-FROM-SRPM := yes
ifeq "$(HOSTARCH)" "i386"
kernel-RPMFLAGS:= --target i686
else
kernel-RPMFLAGS:= --target $(HOSTARCH)
endif
KERNELS += kernel

kernels: $(KERNELS)
kernels-clean: $(foreach package,$(KERNELS),$(package)-clean)

ALL += $(KERNELS)
# this is to mark on which image a given rpm is supposed to go
IN_BOOTCD += $(KERNELS)
IN_VSERVER += $(KERNELS)
IN_BOOTSTRAPFS += $(KERNELS)
# turns out myplc installs kernel-vserver
IN_MYPLC += $(KERNELS)

#
# madwifi
#

ifeq "$(PLDISTROTAGS)" "planetlab-k32-tags.mk"
ifneq "$(DISTRONAME)" "f8"
madwifi-MODULES := madwifi
madwifi-SPEC := madwifi.spec
madwifi-BUILD-FROM-SRPM := yes
madwifi-DEPEND-DEVEL-RPMS += kernel-devel
madwifi-SPECVARS = kernel_version=$(kernel.rpm-version) \
	kernel_release=$(kernel.rpm-release) \
	kernel_arch=$(kernel.rpm-arch)
ALL += madwifi
IN_BOOTSTRAPFS += madwifi
endif
endif

#
# util-vserver
#
util-vserver-MODULES := util-vserver
util-vserver-SPEC := util-vserver.spec
util-vserver-BUILD-FROM-SRPM := yes
util-vserver-RPMFLAGS:= --without dietlibc --without doc
ALL += util-vserver
IN_BOOTSTRAPFS += util-vserver

#
# libnl - local import
# we need either 1.1 or at least 1.0.pre6
# rebuild this on centos5 - see kexcludes in build.common
#
local_libnl=false
ifeq "$(DISTRONAME)" "centos5"
local_libnl=true
endif

ifeq "$(local_libnl)" "true"
libnl-MODULES := libnl
libnl-SPEC := libnl.spec
libnl-BUILD-FROM-SRPM := yes
# this sounds like the thing to do, but in fact linux/if_vlan.h comes with kernel-headers
libnl-DEPEND-DEVEL-RPMS += kernel-devel kernel-headers
ALL += libnl
IN_BOOTSTRAPFS += libnl
endif

#
# util-vserver-pl
#
util-vserver-pl-MODULES := util-vserver-pl
util-vserver-pl-SPEC := util-vserver-pl.spec
util-vserver-pl-DEPEND-DEVEL-RPMS += util-vserver-lib util-vserver-devel util-vserver-core 
ifeq "$(local_libnl)" "true"
util-vserver-pl-DEPEND-DEVEL-RPMS += libnl libnl-devel
endif
ALL += util-vserver-pl
IN_BOOTSTRAPFS += util-vserver-pl

#
# NodeUpdate
#
nodeupdate-MODULES := nodeupdate
nodeupdate-SPEC := NodeUpdate.spec
ALL += nodeupdate
IN_BOOTSTRAPFS += nodeupdate

#
# ipod
#
ipod-MODULES := PingOfDeath
ipod-SPEC := ipod.spec
ALL += ipod
IN_BOOTSTRAPFS += ipod

#
# NodeManager
#
nodemanager-MODULES := nodemanager
nodemanager-SPEC := NodeManager.spec
ALL += nodemanager
IN_BOOTSTRAPFS += nodemanager

#
# pl_sshd
#
sshd-MODULES := pl_sshd
sshd-SPEC := pl_sshd.spec
ALL += sshd
IN_BOOTSTRAPFS += sshd

#
# codemux: Port 80 demux
#
codemux-MODULES := codemux
codemux-SPEC   := codemux.spec
ALL += codemux
IN_BOOTSTRAPFS += codemux

#
# fprobe-ulog
#
fprobe-ulog-MODULES := fprobe-ulog
fprobe-ulog-SPEC := fprobe-ulog.spec
ALL += fprobe-ulog
IN_BOOTSTRAPFS += fprobe-ulog

#
# DistributedRateLimiting
#
DistributedRateLimiting-MODULES := DistributedRateLimiting
DistributedRateLimiting-SPEC := DistributedRateLimiting.spec
ALL += DistributedRateLimiting
IN_NODEREPO += DistributedRateLimiting

#
# pf2slice
#
pf2slice-MODULES := pf2slice
pf2slice-SPEC := pf2slice.spec
ALL += pf2slice

#
# PlanetLab Mom: Cleans up your mess
#
mom-MODULES := Mom
mom-SPEC := pl_mom.spec
ALL += mom
IN_BOOTSTRAPFS += mom

#
# iptables
#
iptables-MODULES := iptables
iptables-SPEC := iptables.spec
iptables-BUILD-FROM-SRPM := yes	
iptables-DEPEND-DEVEL-RPMS += kernel-devel kernel-headers
ALL += iptables
IN_BOOTSTRAPFS += iptables

#
# iproute
#
iproute-MODULES := iproute2
iproute-SPEC := iproute.spec
iproute-BUILD-FROM-SRPM := yes	
ALL += iproute
IN_BOOTSTRAPFS += iproute
IN_VSERVER += iproute
IN_BOOTCD += iproute

#
# inotify-tools - local import
# rebuild this on centos5 (not found) - see kexcludes in build.common
#
local_inotify_tools=false
ifeq "$(DISTRONAME)" "centos5"
local_inotify_tools=true
endif

ifeq "$(DISTRONAME)" "sl6"
local_inotify_tools=true
endif

ifeq "$(local_inotify_tools)" "true"
inotify-tools-MODULES := inotify-tools
inotify-tools-SPEC := inotify-tools.spec
inotify-tools-BUILD-FROM-SRPM := yes
IN_BOOTSTRAPFS += inotify-tools
ALL += inotify-tools
endif

#
# openvswitch
#
openvswitch-MODULES := openvswitch
openvswitch-SPEC := openvswitch.spec
openvswitch-DEPEND-DEVEL-RPMS += kernel-devel
IN_BOOTSTRAPFS += openvswitch
ALL += openvswitch

#
# vsys
#
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
# ocaml-docs is not needed anymore but keep it on a tmp basis as some tags may still have it
vsys-DEVEL-RPMS += ocaml-ocamldoc ocaml-docs
ifeq "$(local_inotify_tools)" "true"
vsys-DEPEND-DEVEL-RPMS += inotify-tools inotify-tools-devel
endif
IN_BOOTSTRAPFS += vsys
ALL += vsys

#
# vsys-scripts
#
vsys-scripts-MODULES := vsys-scripts
vsys-scripts-SPEC := vsys-scripts.spec
IN_BOOTSTRAPFS += vsys-scripts
ALL += vsys-scripts

#
# PLCAPI
#
plcapi-MODULES := plcapi
plcapi-SPEC := PLCAPI.spec
ALL += plcapi
IN_MYPLC += plcapi

#
# drupal
# 
drupal-MODULES := drupal
drupal-SPEC := drupal.spec
drupal-BUILD-FROM-SRPM := yes
ALL += drupal
IN_MYPLC += drupal

#
# use the plewww module instead
#
plewww-MODULES := plewww
plewww-SPEC := plewww.spec
ALL += plewww
IN_MYPLC += plewww

#
# www-register-wizard
#
www-register-wizard-MODULES := www-register-wizard
www-register-wizard-SPEC := www-register-wizard.spec
ALL += www-register-wizard
IN_MYPLC += www-register-wizard

#
# pcucontrol
#
pcucontrol-MODULES := pcucontrol
pcucontrol-SPEC := pcucontrol.spec
ALL += pcucontrol

#
# monitor
#
monitor-MODULES := monitor
monitor-SPEC := Monitor.spec
monitor-DEVEL-RPMS += net-snmp net-snmp-devel
ALL += monitor
IN_BOOTSTRAPFS += monitor

#
# PLC RT
#
plcrt-MODULES := PLCRT
plcrt-SPEC := plcrt.spec
ALL += plcrt

#
# pyopenssl
#
pyopenssl-MODULES := pyopenssl
pyopenssl-SPEC := pyOpenSSL.spec
pyopenssl-BUILD-FROM-SRPM := yes
ALL += pyopenssl


#
# pyaspects
#
pyaspects-MODULES := pyaspects
pyaspects-SPEC := pyaspects.spec
pyaspects-BUILD-FROM-SRPM := yes
ALL += pyaspects

#
# ejabberd
#
ejabberd-MODULES := ejabberd
ejabberd-SPEC := ejabberd.spec
ejabberd-BUILD-FROM-SRPM := yes
ejabberd-DEVEL-RPMS += erlang pam-devel hevea
# not needed anymore on f12 and above, that come with 2.1.5, and we had 2.1.3
# so, this is relevant on f8 and centos5 only
ifeq "$(DISTRONAME)" "$(filter $(DISTRONAME),f8 centos5)"
ALL += ejabberd
endif

# sfa now uses the with statement that's not supported on python-2.4 - not even through __future__
build_sfa=true
ifeq "$(DISTRONAME)" "centos5"
build_sfa=false
endif

ifeq "$(build_sfa)" "true"
#
# sfa - Slice Facility Architecture
#
sfa-MODULES := sfa
sfa-SPEC := sfa.spec
ALL += sfa
endif

#
# nodeconfig
#
# xxx needed when upgrading to 5.0
#nodeconfig-MODULES := nodeconfig
nodeconfig-MODULES := nodeconfig
nodeconfig-SPEC := nodeconfig.spec
ALL += nodeconfig
IN_MYPLC += nodeconfig

#
# bootmanager
#
bootmanager-MODULES := bootmanager
bootmanager-SPEC := bootmanager.spec
ALL += bootmanager
IN_MYPLC += bootmanager

#
# pypcilib : used in bootcd
# 
pypcilib-MODULES := pypcilib
pypcilib-SPEC := pypcilib.spec
ALL += pypcilib
IN_BOOTCD += pypcilib

#
# pyplnet
#
pyplnet-MODULES := pyplnet
pyplnet-SPEC := pyplnet.spec
ALL += pyplnet
IN_BOOTSTRAPFS += pyplnet
IN_MYPLC += pyplnet
IN_BOOTCD += pyplnet


#
# OMF resource controller
#
omf-resctl-MODULES := omf
omf-resctl-SPEC := omf-resctl.spec
ALL += omf-resctl
IN_VSERVER += omf-resctl

#
# OMF exp controller
#
omf-expctl-MODULES := omf
omf-expctl-SPEC := omf-expctl.spec
ALL += omf-expctl


#
# bootcd
#
bootcd-MODULES := bootcd build
bootcd-SPEC := bootcd.spec
bootcd-DEPEND-PACKAGES := $(IN_BOOTCD)
bootcd-DEPEND-FILES := RPMS/yumgroups.xml
bootcd-RPMDATE := yes
ALL += bootcd
IN_MYPLC += bootcd

#
# vserver : reference image for slices
#
vserver-MODULES := vserver-reference build
vserver-SPEC := vserver-reference.spec
vserver-DEPEND-PACKAGES := $(IN_VSERVER)
vserver-DEPEND-FILES := RPMS/yumgroups.xml
vserver-RPMDATE := yes
ALL += vserver
IN_BOOTSTRAPFS += vserver

#
# bootstrapfs
#
bootstrapfs-MODULES := bootstrapfs build
bootstrapfs-SPEC := bootstrapfs.spec
bootstrapfs-DEPEND-PACKAGES := $(IN_BOOTSTRAPFS)
bootstrapfs-DEPEND-FILES := RPMS/yumgroups.xml
bootstrapfs-RPMDATE := yes
ALL += bootstrapfs
IN_MYPLC += bootstrapfs

#
# noderepo
#
# all rpms resulting from packages marked as being in bootstrapfs and vserver
NODEREPO_RPMS = $(foreach package,$(IN_BOOTSTRAPFS) $(IN_NODEREPO) $(IN_VSERVER),$($(package).rpms))
# replace space with +++ (specvars cannot deal with spaces)
SPACE=$(subst x, ,x)
NODEREPO_RPMS_3PLUS = $(subst $(SPACE),+++,$(NODEREPO_RPMS))

noderepo-MODULES := bootstrapfs
noderepo-SPEC := noderepo.spec
# package requires all regular packages
noderepo-DEPEND-PACKAGES := $(IN_BOOTSTRAPFS) $(IN_NODEREPO) $(IN_VSERVER)
noderepo-DEPEND-FILES := RPMS/yumgroups.xml
#export rpm list to the specfile
noderepo-SPECVARS = node_rpms_plus=$(NODEREPO_RPMS_3PLUS)
noderepo-RPMDATE := yes
ALL += noderepo
IN_MYPLC += noderepo

#
# MyPLC : lightweight packaging, dependencies are yum-installed in a vserver
#
myplc-MODULES := myplc
myplc-SPEC := myplc.spec
myplc-DEPEND-FILES := myplc-release RPMS/yumgroups.xml
ALL += myplc

# myplc-docs only contains docs for PLCAPI and NMAPI, but
# we still need to pull MyPLC, as it is where the specfile lies, 
# together with the utility script docbook2drupal.sh
myplc-docs-MODULES := myplc plcapi nodemanager monitor
myplc-docs-SPEC := myplc-docs.spec
ALL += myplc-docs

# using some other name than myplc-release, as this is a make target already
release-MODULES := myplc
release-SPEC := myplc-release.spec
release-RPMDATE := yes
ALL += release

