#
# OneLab standard components list
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

kernel-MODULES := linux-patches
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
# kexec-tools
#
ifeq "$(DISTRO)" "Fedora"
ifeq "$(RELEASE)" "4"
kexec-tools-MODULES := kexec-tools
kexec-tools-SPEC := kexec-tools.spec
kexec-tools-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
kexec-tools-TAG := planetlab-4_1-rc2
ALL += kexec-tools
IN_BOOTCD += kexec-tools
endif
endif

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
# wireless-tools
# 
wireless-tools-MODULES := wireless-tools
wireless-tools-SPEC := wireless-tools.spec
wireless-tools-BUILD-FROM-SRPM := yes
ALL += wireless-tools
IN_BOOTSTRAPFS += wireless-tools

# 
# nozomi
# 
# does not compile against new kernel - waiting for Napoli & Vimercate
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
ALL += util-vserver
IN_BOOTSTRAPFS += util-vserver

#
# util-vserver-pl
#
util-vserver-pl-MODULES := util-vserver-pl
util-vserver-pl-SPEC := util-vserver-pl.spec
util-vserver-pl-DEPEND-DEVEL-RPMS := libnl libnl-devel util-vserver-lib util-vserver-devel util-vserver-core
ALL += util-vserver-pl
IN_BOOTSTRAPFS += util-vserver-pl

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
IN_BOOTSTRAPFS += libhttpd

#
# proper: Privileged Operations Service
#
proper-MODULES := proper
proper-SPEC := proper.spec
proper-DEPEND-DEVEL-RPMS := libhttpd++-devel
ALL += proper
IN_BOOTSTRAPFS += proper

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
ulogd-DEPEND-DEVEL-RPMS := kernel-devel proper-libs proper-devel
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

#
# vsys
#
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
IN_BOOTSTRAPFS += vsys
ifeq "$(DISTRO)" "Fedora"
ifeq "$(RELEASE)" "7"
ALL += vsys
endif
ifeq "$(RELEASE)" "8"
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
PLCWWW-MODULES := PLCWWW
PLCWWW-SPEC := PLCWWW.spec
ALL += PLCWWW
IN_MYPLC += PLCWWW

#
# nodeconfig
#
nodeconfig-MODULES := nodeconfig
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
# package has *some* dependencies, at least these ones
bootcd-DEPEND-PACKAGES := $(IN_BOOTCD)
bootcd-DEPEND-FILES := RPMS/yumgroups.xml
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
vserver-DEPEND-PACKAGES := $(IN_VSERVER)
vserver-DEPEND-FILES := RPMS/yumgroups.xml
ALL += vserver
IN_BOOTSTRAPFS += vserver

#
# bootstrapfs
#
bootstrapfs-MODULES := BootstrapFS build
bootstrapfs-SPEC := bootstrapfs.spec
bootstrapfs-RPMBUILD := sudo bash ./rpmbuild.sh
# package requires all regular packages
bootstrapfs-DEPEND-PACKAGES := $(IN_BOOTSTRAPFS)
bootstrapfs-DEPEND-FILES := RPMS/yumgroups.xml
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
myplc-DEPEND-PACKAGES := $(IN_MYPLC)
myplc-DEPEND-FILES := RPMS/yumgroups.xml myplc-release
ALL += myplc

#
# MyPLC native : lightweight packaging, dependencies are yum-installed in a vserver
#
myplc-native-MODULES := MyPLC build 
myplc-native-SPEC := myplc-native.spec
# Package must be built as root
myplc-native-RPMBUILD := sudo bash ./rpmbuild.sh
# Thierry : don't depend on anything at build-time
#myplc-native-DEPEND-PACKAGES :=
# Thierry : dunno about this one, let's stay safe
myplc-native-DEPEND-FILES := myplc-release
ALL += myplc-native

