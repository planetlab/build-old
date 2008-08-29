#
# PlanetLab standard components list
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
ifeq "$(DISTRONAME)" "fc4"
kexec-tools-MODULES := kexec-tools
kexec-tools-SPEC := kexec-tools.spec
kexec-tools-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
kexec-tools-TAG := planetlab-4_1-rc2
ALL += kexec-tools
IN_BOOTCD += kexec-tools
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
util-vserver-pl-DEPEND-DEVEL-RPMS := util-vserver-lib util-vserver-devel util-vserver-core
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
IN_VSERVER += iproute

#
# vsys
#
vsys_support=yes
ifeq "$(DISTRONAME)" "fc4"
vsys_support=
endif
ifeq "$(DISTRONAME)" "fc6"
vsys_support=
endif
# cannot find the required packages (see devel.pkgs) on centos5
ifeq "$(DISTRONAME)" "centos5"
vsys_support=
endif

ifeq "$(vsys_support)" "yes"
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
IN_BOOTSTRAPFS += vsys
ALL += vsys
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
# monitor
#
Monitor-MODULES := Monitor
Monitor-SPEC := Monitor.spec
ALL += Monitor
IN_BOOTSTRAPFS += Monitor

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
# this list is useful for manual builds only, since nightly builds 
# always redo all sequentially - try to keep updated
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
# package requires all regular packages
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
# myplc : initial, chroot-based packaging
#
myplc-MODULES := MyPLC build
myplc-SPEC := myplc.spec
# Package must be built as root
myplc-RPMBUILD := sudo bash ./rpmbuild.sh
# myplc may require all packages
myplc-DEPEND-PACKAGES := $(IN_MYPLC)
myplc-DEPEND-FILES := RPMS/yumgroups.xml myplc-release
myplc-RPMDATE := yes
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

myplc-docs-MODULES := MyPLC PLCAPI NodeManager
myplc-docs-SPEC := myplc-docs.spec
ALL += myplc-docs
