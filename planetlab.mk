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
kernel-$(HOSTARCH)-MODULES := Linux-2.6
kernel-$(HOSTARCH)-SPEC := scripts/kernel-2.6-planetlab.spec
ifeq ($(HOSTARCH),i386)
kernel-$(HOSTARCH)-RPMFLAGS:= --target i686
else
kernel-$(HOSTARCH)-RPMFLAGS:= --target $(HOSTARCH)
endif

KERNELS += kernel-$(HOSTARCH)

kernel: $(KERNELS)
kernel-clean: $(foreach package,$(KERNELS),$(package)-clean)

ALL += $(KERNELS)

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
util-vserver-DEPENDS := libnl
ALL += util-vserver

#
# NodeUpdate
#
NodeUpdate-MODULES := NodeUpdate
NodeUpdate-SPEC := NodeUpdate.spec
ALL += NodeUpdate

#
# ipod
#
PingOfDeath-MODULES := PingOfDeath
PingOfDeath-SPEC := ipod.spec
ALL += PingOfDeath

#
# NodeManager
#
NodeManager-MODULES := NodeManager
NodeManager-SPEC := NodeManager.spec
ALL += NodeManager

#
# pl_sshd
#
pl_sshd-MODULES := pl_sshd
pl_sshd-SPEC := pl_sshd.spec
ALL += pl_sshd

#
# libhttpd++: 
#
# Deprecate when vsys takes over [sapan].
# keep in build for proper.
#
libhttpd++-MODULES := libhttpd++
libhttpd++-SPEC := libhttpd++.spec
ALL += libhttpd++

#
# proper: Privileged Operations Service
#
proper-MODULES := proper
proper-SPEC := proper.spec
proper-RPMBUILD := sudo bash ./rpmbuild.sh
# proper uses scripts in util-python for building
proper-DEPENDS := libhttpd++ util-python
ALL += proper

#
# codemux: Port 80 demux
#
codemux-MODULES := CoDemux
codemux-SPEC   := codemux.spec
codemux-RPMBUILD := sudo bash ./rpmbuild.sh
ALL += codemux

#
# ulogd
#
ulogd-MODULES := ulogd
ulogd-SPEC := ulogd.spec
ulogd-DEPENDS := $(KERNELS) proper
ALL += ulogd

#
# netflow
#
netflow-MODULES := PlanetFlow
netflow-SPEC := netflow.spec
netflow-SPECVARS := distroname=$(DISTRO) distrorelease=$(RELEASE)
ALL += netflow

#
# PlanetLab Mom: Cleans up your mess
#
pl_mom-MODULES := Mom
pl_mom-SPEC := pl_mom.spec
ALL += pl_mom

#
# iptables
#
iptables-MODULES := iptables
iptables-SPEC := iptables.spec
iptables-DEPENDS := $(KERNELS)
ALL += iptables

#
# iproute
#
iproute-MODULES := iproute2
iproute-SPEC := iproute.spec
ALL += iproute

#
# util-python
#
# [marc]    deprecate with proper
#
util-python-MODULES := util-python
util-python-SPEC := util-python.spec
ALL += util-python

#
# vsys
#
vsys-MODULES := vsys
vsys-SPEC := vsys.spec
ifeq ($(DISTRO),"Fedora")
ifeq ($(RELEASE),7)
ALL += vsys
endif
endif

#
# PLCAPI
#
PLCAPI-MODULES := PLCAPI
PLCAPI-SPEC := PLCAPI.spec
ALL += PLCAPI

#
# PLCWWW
#
PLCWWW-MODULES := WWW
PLCWWW-SPEC := PLCWWW.spec
ALL += PLCWWW

#
# bootmanager
#
bootmanager-MODULES := BootManager build
bootmanager-SPEC := bootmanager.spec
# Package must be built as root
bootmanager-RPMBUILD := sudo bash ./rpmbuild.sh
ALL += bootmanager

#
# pypcilib : used in bootcd
# 
pypcilib-MODULES := pypcilib
pypcilib-SPEC := pypcilib.spec
ALL += pypcilib

# copy the current list, so as to keep image-building rpms out
ALL-REGULARS := $(ALL)

#
# vserver : reference image for slices
#
vserver-MODULES := VserverReference build
vserver-SPEC := vserver-reference.spec
# Package must be built as root
vserver-RPMBUILD := sudo bash ./rpmbuild.sh
# package requires all regular packages
vserver-DEPENDS := $(ALL-REGULARS)
vserver-DEPENDFILES := RPMS/yumgroups.xml
ALL += vserver

#
# bootcd
#
bootcd-MODULES := BootCD BootManager build
bootcd-SPEC := bootcd.spec
bootcd-RPMBUILD := sudo bash ./rpmbuild.sh
# package has *some* dependencies, at least these ones
bootcd-DEPENDS := $(ALL-REGULARS)
bootcd-DEPENDFILES := RPMS/yumgroups.xml
ALL += bootcd

#
# bootstrapfs
#
bootstrapfs-MODULES := BootstrapFS build
bootstrapfs-SPEC := bootstrapfs.spec
bootstrapfs-RPMBUILD := sudo bash ./rpmbuild.sh
# package requires all regular packages
bootstrapfs-DEPENDS := $(ALL-REGULARS)
bootstrapfs-DEPENDFILES := RPMS/yumgroups.xml
ALL += bootstrapfs

#
# myplc : initial, chroot-based packaging
#
myplc-MODULES := MyPLC build
myplc-SPEC := myplc.spec
# Package must be built as root
myplc-RPMBUILD := sudo bash ./rpmbuild.sh
# myplc may require all packages
myplc-DEPENDS := $(filter-out vserver,$(ALL))
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
myplc-devel-native-SPECVARS := distroname=$(DISTRO) distrorelease=$(RELEASE)
#ALL += myplc-devel-native
