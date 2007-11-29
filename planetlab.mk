#
# PlanetLab standard components list
#
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2006 The Trustees of Princeton University
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

srpm-kernel-$(HOSTARCH)-MODULES := linux-patches
srpm-kernel-$(HOSTARCH)-SPEC := kernel-2.6-planetlab.spec
ifeq ($(HOSTARCH),i386)
srpm-kernel-$(HOSTARCH)-RPMFLAGS:= --target i686
else
srpm-kernel-$(HOSTARCH)-RPMFLAGS:= --target $(HOSTARCH)
endif
KERNELS += srpm-kernel-$(HOSTARCH)

kernel: $(KERNELS)
kernel-clean: $(foreach package,$(KERNELS),$(package)-clean)

# the first kernel package defined here for convenience
kernel_package := $(word 1,$(KERNELS))

ALL += $(KERNELS)
# this is to mark on which image a given rpm is supposed to go
IN_BOOTCD += $(KERNELS)
IN_VSERVER += $(KERNELS)
IN_BOOTSTRAPFS += $(KERNELS)
# turns out myplc installs kernel-vserver
IN_MYPLC += $(KERNELS)

#
# libnl
#
# [daniel]    wait for latest Fedora release 
# (03:29:46 PM) daniel_hozac: interfacing with the kernel directly when dealing with netlink was fugly, so... i had to find something nicer.
# (03:29:53 PM) daniel_hozac: the one in Fedora is lacking certain APIs i need.
#
libnl-MODULES := libnl
libnl-SPEC := libnl.spec
ALL += libnl

#
# util-vserver
#
util-vserver-MODULES := util-vserver
util-vserver-SPEC := util-vserver.spec
util-vserver-RPMFLAGS:= --without dietlibc
util-vserver-DEPENDDEVELS := libnl
ALL += util-vserver
IN_BOOTSTRAPFS += util-vserver

#
# NodeUpdate
#
NodeUpdate-MODULES := NodeUpdate
NodeUpdate-SPEC := NodeUpdate.spec
ALL += NodeUpdate
IN_BOOTSTRAPFS += NodeUpdate

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
NodeManager-MODULES := NodeManager
NodeManager-SPEC := NodeManager.spec
ALL += NodeManager
IN_BOOTSTRAPFS += NodeManager

#
# pl_sshd
#
pl_sshd-MODULES := pl_sshd
pl_sshd-SPEC := pl_sshd.spec
ALL += pl_sshd
IN_BOOTSTRAPFS += pl_sshd

#
# libhttpd++: 
#
# Deprecate when vsys takes over [sapan].
# keep in build for proper.
#
libhttpd-MODULES := libhttpd++
libhttpd-SPEC := libhttpd++.spec
ALL += libhttpd

#
# proper: Privileged Operations Service
#
proper-MODULES := proper
proper-SPEC := proper.spec
proper-DEPENDDEVELS := libhttpd
ALL += proper

#
# codemux: Port 80 demux
#
codemux-MODULES := CoDemux
codemux-SPEC   := codemux.spec
codemux-RPMBUILD := sudo bash ./rpmbuild.sh
ALL += codemux
IN_BOOTSTRAPFS += codemux

#
# ulogd
#
ulogd-MODULES := ulogd
ulogd-SPEC := ulogd.spec
ulogd-DEPENDDEVELS := $(kernel_package)
ulogd-DEPENDDEVELRPMS := proper-libs proper-devel
ALL += ulogd
IN_VSERVER += ulogd

#
# fprobe-ulog
#
fprobe-ulog-MODULES := fprobe-ulog
fprobe-ulog-SPEC := fprobe-ulog.spec
ALL += fprobe-ulog
IN_BOOTSTRAPFS += fprobe-ulog

#
# netflow
#
netflow-MODULES := PlanetFlow
netflow-SPEC := netflow.spec
ALL += netflow
IN_BOOTSTRAPFS += netflow

#
# PlanetLab Mom: Cleans up your mess
#
pl_mom-MODULES := Mom
pl_mom-SPEC := pl_mom.spec
ALL += pl_mom
IN_BOOTSTRAPFS += pl_mom

#
# iptables
#
iptables-MODULES := iptables
iptables-SPEC := iptables.spec
iptables-DEPENDDEVELS := $(kernel_package)
ALL += iptables
IN_BOOTSTRAPFS += iptables

#
# iproute
#
iproute-MODULES := iproute2
iproute-SPEC := iproute.spec
ALL += iproute
IN_BOOTSTRAPFS += iproute

#
# vsys
#
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
ifeq ($(DISTRO),"Fedora")
ifeq ($(RELEASE),7)
ALL += vsys
endif
ifeq ($(RELEASE),8)
ALL += vsys
endif
endif

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
PLCWWW-MODULES := WWW
PLCWWW-SPEC := PLCWWW.spec
ALL += PLCWWW
IN_MYPLC += PLCWWW

#
# bootmanager
#
bootmanager-MODULES := BootManager build
bootmanager-SPEC := bootmanager.spec
# Package must be built as root
bootmanager-RPMBUILD := sudo bash ./rpmbuild.sh
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
bootcd-MODULES := BootCD BootManager build
bootcd-SPEC := bootcd.spec
bootcd-RPMBUILD := sudo bash ./rpmbuild.sh
# package has *some* dependencies, at least these ones
bootcd-DEPENDS := $(IN_BOOTCD)
bootcd-DEPENDFILES := RPMS/yumgroups.xml
ALL += bootcd
IN_MYPLC += bootcd

#
# vserver : reference image for slices
#
vserver-MODULES := VserverReference build
vserver-SPEC := vserver-reference.spec
# Package must be built as root
vserver-RPMBUILD := sudo bash ./rpmbuild.sh
# this list is useful for manual builds only, since nightly builds 
# always redo all sequentially - try to keep updated
vserver-DEPENDS := $(IN_VSERVER)
vserver-DEPENDFILES := RPMS/yumgroups.xml
ALL += vserver
IN_BOOTSTRAPFS := vserver

#
# bootstrapfs
#
bootstrapfs-MODULES := BootstrapFS build
bootstrapfs-SPEC := bootstrapfs.spec
bootstrapfs-RPMBUILD := sudo bash ./rpmbuild.sh
# package requires all regular packages
bootstrapfs-DEPENDS := $(IN_BOOTSTRAPFS)
bootstrapfs-DEPENDFILES := RPMS/yumgroups.xml
ALL += bootstrapfs
IN_MYPLC += bootstrapfs

#
# myplc : initial, chroot-based packaging
#
myplc-MODULES := MyPLC build
myplc-SPEC := myplc.spec
# Package must be built as root
myplc-RPMBUILD := sudo bash ./rpmbuild.sh
# myplc may require all packages
myplc-DEPENDS := $(IN_MYPLC)
myplc-DEPENDFILES := RPMS/yumgroups.xml
ALL += myplc

#
# MyPLC native : lightweight packaging, dependencies are yum-installed in a vserver
#
myplc-native-MODULES := MyPLC build 
myplc-native-SPEC := myplc-native.spec
# Package must be built as root
myplc-native-RPMBUILD := sudo bash ./rpmbuild.sh
# Thierry : don't depend on these at build-time
#myplc-native-DEPENDS := $(MyPLC-DEPENDS)
# Thierry : dunno about this one, let's stay safe
myplc-native-DEPENDFILES := $(MyPLC-DEPENDFILES)
#ALL += myplc-native

#
# MyPLC development environment : chroot-based 
#
myplc-devel-MODULES := MyPLC build 
myplc-devel-SPEC := myplc-devel.spec
myplc-devel-RPMBUILD := sudo bash ./rpmbuild.sh
#ALL += myplc-devel

#
# MyPLC native development environment
#
myplc-devel-native-MODULES := MyPLC
myplc-devel-native-SPEC := myplc-devel-native.spec
#ALL += myplc-devel-native
