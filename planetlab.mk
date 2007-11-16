#
# PlanetLab standard components list
#
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2006 The Trustees of Princeton University
#
# $Id$
#

#
# Required:
#
# CVSROOT or package-CVSROOT: CVSROOT to use
# together with 
# TAG or package-TAG: CVS tag to use (only with CVSROOT)
# or
# SVNPATH or package-SVNPATH: SVNPATH to use
# Note: do not define both CVSROOT and SVNPATH
#
# package-MODULE: name(s) of cvs/svn module(s) needed for building
# package-SPEC: RPM spec file name
#
# Optional:
#
# package-RPMFLAGS: Miscellaneous RPM flags
# package-RPMBUILD: If not rpmbuild
#
# Add to ALL if you want the package built as part of the default set.
#

#
# Default values -- should be able to override these from command line
#
HOSTARCH := $(shell uname -i)
DISTRO := $(shell ./getdistro.sh)
RELEASE := $(shell ./getrelease.sh)

#
# load in a release specific tags file
# Override TAGSFILE from command line to select something else
#

#
# kernel
#
kernel-$(HOSTARCH)-MODULE := Linux-2.6
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
# util-vserver
#
util-vserver-MODULE := util-vserver
util-vserver-SPEC := util-vserver.spec
util-vserver-RPMFLAGS:= --without dietlibc
util-vserver-DEPENDS := libnl
ALL += util-vserver

#
# NodeUpdate
#
NodeUpdate-MODULE := NodeUpdate
NodeUpdate-SPEC := NodeUpdate.spec
ALL += NodeUpdate

#
# ipod
#
PingOfDeath-MODULE := PingOfDeath
PingOfDeath-SPEC := ipod.spec
ALL += PingOfDeath

#
# NodeManager
#
NodeManager-MODULE := NodeManager
NodeManager-SPEC := NodeManager.spec
ALL += NodeManager

#
# pl_sshd
#
pl_sshd-MODULE := pl_sshd
pl_sshd-SPEC := pl_sshd.spec
ALL += pl_sshd

#
# libhttpd++: 
#
# Deprecate when vsys takes over [sapan].
# keep in build for proper.
#
libhttpd++-MODULE := libhttpd++
libhttpd++-SPEC := libhttpd++.spec
ALL += libhttpd++

#
# Proper: Privileged Operations Service
#
proper-MODULE := proper
proper-SPEC := proper.spec
proper-RPMBUILD := sudo bash ./rpmbuild.sh
# proper uses scripts in util-python for building
proper-DEPENDS := libhttpd++ util-python
ALL += proper

#
# CoDemux: Port 80 demux
#
CoDemux-MODULE := CoDemux
CoDemux-SPEC   := codemux.spec
CoDemux-RPMBUILD := sudo bash ./rpmbuild.sh
ALL += CoDemux

#
# ulogd
#
ulogd-MODULE := ulogd
ulogd-SPEC := ulogd.spec
ulogd-DEPENDS := $(KERNELS) proper
ALL += ulogd

#
# PlanetFlow
#
PlanetFlow-MODULE := PlanetFlow
PlanetFlow-SPEC := netflow.spec
PlanetFlow-SPECVARS := distroname=$(DISTRO) distrorelease=$(RELEASE)
ALL += PlanetFlow

#
# PlanetLab Mom: Cleans up your mess
#
Mom-MODULE := Mom
Mom-SPEC := pl_mom.spec
ALL += Mom

#
# iptables
#
iptables-MODULE := iptables
iptables-SPEC := iptables.spec
iptables-DEPENDS := $(KERNELS)
ALL += iptables

#
# iproute
#
iproute-MODULE := iproute2
iproute-SPEC := iproute.spec
ALL += iproute

#
# util-python
#
# [marc]    deprecate with proper
#
util-python-MODULE := util-python
util-python-SPEC := util-python.spec
ALL += util-python

#
# vsys
#
vsys-MODULE := vsys
vsys-SPEC := vsys.spec
ifeq ($(DISTRO),"Fedora")
ifeq ($(RELEASE),7)
ALL += vsys
endif
endif

#
# PLCAPI
#
PLCAPI-MODULE := PLCAPI
PLCAPI-SPEC := PLCAPI.spec
ALL += PLCAPI

#
# PLCWWW
#
PLCWWW-MODULE := WWW
PLCWWW-SPEC := PLCWWW.spec
ALL += PLCWWW

#
# BootManager
#
BootManager-MODULE := BootManager build
BootManager-SPEC := bootmanager.spec
# Package must be built as root
BootManager-RPMBUILD := sudo bash ./rpmbuild.sh
ALL += BootManager

# we do not want BootCD to depend on vserver-reference, do we ?
ALL-REGULARS := $(ALL)

#
# vserver-reference
#
VserverReference-MODULE := VserverReference build
VserverReference-SPEC := vserver-reference.spec
# Package must be built as root
VserverReference-RPMBUILD := sudo bash ./rpmbuild.sh
# package requires all regular packages
VserverReference-DEPENDS := $(ALL-REGULARS)
VserverReference-DEPENDFILES := RPMS/yumgroups.xml
ALL += VserverReference

#
# BootCD
#
BootCD-MODULE := BootCD BootManager build
BootCD-SPEC := bootcd.spec
BootCD-RPMBUILD := sudo bash ./rpmbuild.sh
# package has *some* dependencies, at least these ones
BootCD-DEPENDS := $(KERNELS)
BootCD-DEPENDFILES := RPMS/yumgroups.xml
ALL += BootCD

#
# BootstrapFS
#
BootstrapFS-MODULE := BootstrapFS build
BootstrapFS-SPEC := bootstrapfs.spec
BootstrapFS-RPMBUILD := sudo bash ./rpmbuild.sh
# package requires all regular packages
BootstrapFS-DEPENDS := $(ALL-REGULARS)
BootstrapFS-DEPENDFILES := RPMS/yumgroups.xml
ALL += BootstrapFS

#
# MyPLC
#
MyPLC-MODULE := MyPLC build
MyPLC-SPEC := myplc.spec
# Package must be built as root
MyPLC-RPMBUILD := sudo bash ./rpmbuild.sh
# MyPLC may require all packages
MyPLC-DEPENDS := $(filter-out MyPLC,$(ALL))
MyPLC-DEPENDFILES := RPMS/yumgroups.xml
ALL += MyPLC

#
# MyPLC native
#
MyPLC-native-MODULE := MyPLC build 
MyPLC-native-SPEC := myplc-native.spec
# Package must be built as root
MyPLC-native-RPMBUILD := sudo bash ./rpmbuild.sh
# Thierry : I don't think we depend on these at build-time
#MyPLC-native-DEPENDS := $(MyPLC-DEPENDS)
# Thierry : dunno about this one, let's stay safe
MyPLC-native-DEPENDFILES := $(MyPLC-DEPENDFILES)
#ALL += MyPLC-native

#
# MyPLC development environment
#
MyPLC-devel-MODULE := MyPLC build 
MyPLC-devel-SPEC := myplc-devel.spec
MyPLC-devel-RPMBUILD := sudo bash ./rpmbuild.sh
#ALL += MyPLC-devel

#
# MyPLC native development environment
#
MyPLC-devel-native-MODULE := MyPLC
MyPLC-devel-native-SPECVARS := distroname=$(DISTRO) distrorelease=$(RELEASE)
MyPLC-devel-native-SPEC := myplc-devel-native.spec
#ALL += MyPLC-devel-native

#
# libnl
#
# [daniel]    wait for latest Fedora release 
# (03:29:46 PM) daniel_hozac: interfacing with the kernel directly when dealing with netlink was fugly, so... i had to find something nicer.
# (03:29:53 PM) daniel_hozac: the one in Fedora is lacking certain APIs i need.
#
libnl-MODULE := libnl
libnl-SPEC := libnl.spec
ALL += libnl

