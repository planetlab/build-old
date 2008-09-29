#
# declare the packages to be built and their dependencies
# initial version from Mark Huang
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2006 The Trustees of Princeton University
# rewritten by Thierry Parmentelat - INRIA Sophia Antipolis
#
# $Id$
#
# see doc in Makefile  
#

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
kernel-SPECVARS := iwlwifi=1
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
madwifi-MODULES := madwifi
madwifi-SPEC := madwifi.spec
madwifi-BUILD-FROM-SRPM := yes
madwifi-DEPEND-DEVEL-RPMS := kernel-devel
madwifi-SPECVARS = kernel_version=$(kernel.rpm-version) \
	kernel_release=$(kernel.rpm-release) \
	kernel_arch=$(kernel.rpm-arch)
ALL += madwifi
IN_BOOTSTRAPFS += madwifi

# 
# nozomi
# 
nozomi-MODULES := nozomi
nozomi-SPEC := nozomi.spec
nozomi-DEPEND-DEVEL-RPMS := kernel-devel
nozomi-SPECVARS = kernel_version=$(kernel.rpm-version) \
	kernel_release=$(kernel.rpm-release) \
	kernel_arch=$(kernel.rpm-arch)
IN_BOOTSTRAPFS += nozomi
ALL += nozomi

#
# comgt
# 
comgt-MODULES := comgt
comgt-SPEC := comgt.spec
IN_BOOTSTRAPFS += comgt
ALL += comgt

#
# util-vserver
#
util-vserver-MODULES := util-vserver
util-vserver-SPEC := util-vserver.spec
util-vserver-RPMFLAGS:= --without dietlibc
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
ALL += libnl
IN_BOOTSTRAPFS += libnl
endif

#
# util-vserver-pl
#
util-vserver-pl-MODULES := util-vserver-pl
util-vserver-pl-SPEC := util-vserver-pl.spec
util-vserver-pl-DEPEND-DEVEL-RPMS := util-vserver-lib util-vserver-devel util-vserver-core 
ifeq "$(local_libnl)" "true"
util-vserver-pl-DEPEND-DEVEL-RPMS += libnl libnl-devel
endif
ALL += util-vserver-pl
IN_BOOTSTRAPFS += util-vserver-pl

#
# NodeUpdate
#
nodeupdate-MODULES := NodeUpdate
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
nodemanager-MODULES := NodeManager
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
codemux-MODULES := CoDemux
codemux-SPEC   := codemux.spec
codemux-RPMBUILD := sudo bash ./rpmbuild.sh
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
iptables-DEPEND-DEVEL-RPMS := kernel-devel
ALL += iptables
IN_BOOTSTRAPFS += iptables

#
# iproute
#
iproute-MODULES := iproute2
iproute-SPEC := iproute.spec
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

ifeq "$(local_inotify_tools)" "true"
inotify-tools-MODULES := inotify-tools
inotify-tools-SPEC := inotify-tools.spec
inotify-tools-BUILD-FROM-SRPM := yes
IN_BOOTSTRAPFS += inotify-tools
ALL += inotify-tools
endif

#
# vsys
#
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
ifeq "$(local_inotify_tools)" "true"
vsys-DEPEND-DEVEL-RPMS := inotify-tools inotify-tools-devel
endif
IN_BOOTSTRAPFS += vsys
ALL += vsys

#
# dummynet_image
# 
dummynet_image-MODULES := dummynet_image
dummynet_image-SPEC := dummynet_image.spec
IN_MYPLC += dummynet_image
ALL += dummynet_image

#
# PLCAPI
#
PLCAPI-MODULES := PLCAPI
PLCAPI-SPEC := PLCAPI.spec
ALL += PLCAPI
IN_MYPLC += PLCAPI

#
# PLCWWW
#
PLCWWW-MODULES := PLCWWW
PLCWWW-SPEC := PLCWWW.spec
ALL += PLCWWW
IN_MYPLC += PLCWWW

#
# monitor
#
monitor-MODULES := Monitor
monitor-SPEC := Monitor.spec
ALL += monitor
IN_BOOTSTRAPFS += monitor

#
# monitor-server
#
monitor-server-MODULES := Monitor
monitor-server-SPEC := monitor-server.spec
ALL += monitor-server

#
# nodeconfig
#
nodeconfig-MODULES := nodeconfig build
nodeconfig-SPEC := nodeconfig.spec
ALL += nodeconfig
IN_MYPLC += nodeconfig

#
# bootmanager
#
bootmanager-MODULES := BootManager
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
# bootcd
#
bootcd-MODULES := BootCD build
bootcd-SPEC := bootcd.spec
bootcd-RPMBUILD := sudo bash ./rpmbuild.sh
bootcd-DEPEND-PACKAGES := $(IN_BOOTCD)
bootcd-DEPEND-FILES := RPMS/yumgroups.xml
bootcd-RPMDATE := yes
ALL += bootcd
IN_MYPLC += bootcd

#
# vserver : reference image for slices
#
vserver-MODULES := VserverReference build
vserver-SPEC := vserver-reference.spec
# Package must be built as root
vserver-RPMBUILD := sudo bash ./rpmbuild.sh
vserver-DEPEND-PACKAGES := $(IN_VSERVER)
vserver-DEPEND-FILES := RPMS/yumgroups.xml
vserver-RPMDATE := yes
ALL += vserver
IN_BOOTSTRAPFS += vserver

#
# bootstrapfs
#
bootstrapfs-MODULES := BootstrapFS build
bootstrapfs-SPEC := bootstrapfs.spec
bootstrapfs-RPMBUILD := sudo bash ./rpmbuild.sh
bootstrapfs-DEPEND-PACKAGES := $(IN_BOOTSTRAPFS)
bootstrapfs-DEPEND-FILES := RPMS/yumgroups.xml
bootstrapfs-RPMDATE := yes
ALL += bootstrapfs
IN_MYPLC += bootstrapfs

#
# noderepo
#
# all rpms resulting from packages marked as being in bootstrapfs and vserver
NODEREPO_RPMS = $(foreach package,$(IN_BOOTSTRAPFS) $(IN_VSERVER),$($(package).rpms))
# replace space with +++ (specvars cannot deal with spaces)
SPACE=$(subst x, ,x)
NODEREPO_RPMS_3PLUS = $(subst $(SPACE),+++,$(NODEREPO_RPMS))

noderepo-MODULES := BootstrapFS 
noderepo-SPEC := noderepo.spec
noderepo-RPMBUILD := sudo bash ./rpmbuild.sh
# package requires all regular packages
noderepo-DEPEND-PACKAGES := $(IN_BOOTSTRAPFS) $(IN_VSERVER)
noderepo-DEPEND-FILES := RPMS/yumgroups.xml
#export rpm list to the specfile
noderepo-SPECVARS = node_rpms_plus=$(NODEREPO_RPMS_3PLUS)
noderepo-RPMDATE := yes
ALL += noderepo
IN_MYPLC += noderepo

#
# MyPLC native : lightweight packaging, dependencies are yum-installed in a vserver
#
myplc-native-MODULES := MyPLC build 
myplc-native-SPEC := myplc-native.spec
# Package must be built as root
myplc-native-RPMBUILD := sudo bash ./rpmbuild.sh
myplc-native-DEPEND-FILES := myplc-release RPMS/yumgroups.xml
ALL += myplc-native

## #
## # myplc : old-fashioned, chroot-based packaging
## #
## myplc-MODULES := MyPLC build
## myplc-SPEC := myplc.spec
## # Package must be built as root
## myplc-RPMBUILD := sudo bash ./rpmbuild.sh
## # myplc may require all packages
## myplc-DEPEND-PACKAGES := $(IN_MYPLC)
## myplc-DEPEND-FILES := RPMS/yumgroups.xml myplc-release
## myplc-RPMDATE := yes
## ALL += myplc

# myplc-docs only contains docs for PLCAPI and NMAPI, but
# we still need to pull MyPLC, as it is where the specfile lies, 
# together with the utility script docbook2drupal.sh
myplc-docs-MODULES := MyPLC PLCAPI NodeManager
myplc-docs-SPEC := myplc-docs.spec
ALL += myplc-docs
