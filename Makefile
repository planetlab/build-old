#
# PlanetLab RPM generation
#
# Copyright (c) 2003  The Trustees of Princeton University (Trustees).
# All Rights Reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met: 
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
# 
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
# 
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE TRUSTEES OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Id: Makefile,v 1.44 2004/09/18 19:49:42 mlh-pl_rpm Exp $
#

# Default target
all:

#
# CVSROOT: CVSROOT to use
# INITIAL: CVS tag to use for Source0 tarball
# TAG: CVS tag to patch to
# MODULE: CVS module name to use
# SPEC: RPM spec file template
# RPMBUILD: If not rpmbuild
# RPMFLAGS: Miscellaneous RPM flags
# CVS_RSH: If not ssh
# ALL: default targets
#
# If INITIAL is different than TAG, PatchSets will be generated
# automatically with cvsps(1) to bring Source0 up to TAG. If TAG is
# HEAD, a %{date} variable will be defined in the generated spec
# file. If a Patch: tag in the spec file matches a generated PatchSet
# number, the name of the patch will be as specified. Otherwise, the
# name of the patch will be the PatchSet number. %patch tags in the
# spec file are generated automatically.
#

#
# kernel
#

kernel-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
kernel-INITIAL := HEAD
kernel-TAG := HEAD
kernel-MODULE := linux-2.6
kernel-SPEC := linux-2.6/scripts/kernel-2.6-planetlab.spec
ALL += kernel

#
# vnet
#

vnet-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
vnet-INITIAL := HEAD
vnet-TAG := HEAD
vnet-MODULE := vnet
vnet-SPEC := vnet/vnet.spec
vnet-RPMFLAGS := --define "kernelver $(shell rpmquery --queryformat '%{VERSION}-%{RELEASE}\n' --specfile SPECS/$(notdir $(kernel-SPEC)) | head -1)"
ALL += vnet

# Build kernel first so we can bootstrap off of its build
vnet: kernel

#
# vsh
#

vsh-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
vsh-INITIAL := HEAD
vsh-TAG := HEAD
vsh-MODULE := trampoline
vsh-SPEC := trampoline/vsh.spec
ALL += vsh

# Build kernel first so we can bootstrap off of its build
vsh: kernel

#
# util-vserver
#

util-vserver-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
util-vserver-INITIAL := HEAD
util-vserver-TAG := HEAD
util-vserver-MODULE := util-vserver
util-vserver-SPEC := util-vserver/util-vserver.spec
ALL += util-vserver

# Build kernel first so we can bootstrap off of its build
util-vserver: kernel

#
# vserver-reference
#

vserver-reference-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
vserver-reference-INITIAL := HEAD
vserver-reference-TAG := HEAD
vserver-reference-MODULE := vserver-reference
vserver-reference-SPEC := vserver-reference/vserver-reference.spec
# Package must be built as root
vserver-reference-RPMBUILD := sudo rpmbuild
ALL += vserver-reference

#
# lkcdutils
#

lkcdutils-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
lkcdutils-INITIAL := HEAD
lkcdutils-TAG := HEAD
lkcdutils-MODULE := lkcdutils
lkcdutils-SPEC := lkcdutils/spec/lkcdutils.spec
ALL += lkcdutils

# Build kernel first so we can bootstrap off of its build
lkcdutils: kernel

#
# yum
#

yum-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
yum-INITIAL := HEAD
yum-TAG := HEAD
yum-MODULE := yum
yum-SPEC := yum/yum.spec
ALL += yum

#
# ksymoops
#

ksymoops-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
ksymoops-INITIAL := ksymoops-2_4_9
ksymoops-TAG := HEAD
ksymoops-MODULE := ksymoops
ksymoops-SPEC := ksymoops/ksymoops.spec
ALL += ksymoops

#
# PlanetLabAccounts
#

PlanetLabAccounts-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
PlanetLabAccounts-INITIAL := HEAD
PlanetLabAccounts-TAG := HEAD
PlanetLabAccounts-MODULE := PlanetLabAccounts
PlanetLabAccounts-SPEC := PlanetLabAccounts/PlanetLabAccounts.spec
ALL += PlanetLabAccounts

#
# NodeUpdate
#

NodeUpdate-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
NodeUpdate-INITIAL := HEAD
NodeUpdate-TAG := HEAD
NodeUpdate-MODULE := NodeUpdate
NodeUpdate-SPEC := NodeUpdate/NodeUpdate.spec
ALL += NodeUpdate

#
# PlanetLabConf
#

PlanetLabConf-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
PlanetLabConf-INITIAL := HEAD
PlanetLabConf-TAG := HEAD
PlanetLabConf-MODULE := PlanetLabConf
PlanetLabConf-SPEC := PlanetLabConf/PlanetLabConf.spec
ALL += PlanetLabConf

#
# PlanetLabKeys
#

PlanetLabKeys-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
PlanetLabKeys-INITIAL := HEAD
PlanetLabKeys-TAG := HEAD
PlanetLabKeys-MODULE := PlanetLabKeys
PlanetLabKeys-SPEC := PlanetLabKeys/PlanetLabKeys.spec
ALL += PlanetLabKeys

#
# BWLimit
#

BWLimit-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
BWLimit-INITIAL := HEAD
BWLimit-TAG := HEAD
BWLimit-MODULE := BWLimit
BWLimit-SPEC := BWLimit/BWLimit.spec
ALL += BWLimit

#
# ipod
#

ipod-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
ipod-INITIAL := HEAD
ipod-TAG := HEAD
ipod-MODULE := ipod
ipod-SPEC := ipod/ipod.spec
ALL += ipod

#
# sudo
#

sudo-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
sudo-INITIAL := HEAD
sudo-TAG := HEAD
sudo-MODULE := sudo
sudo-SPEC := sudo/planetlab_sudo.spec
ALL += sudo

#
# pycurl
#

pycurl-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
pycurl-INITIAL := HEAD
pycurl-TAG := HEAD
pycurl-MODULE := pycurl
pycurl-SPEC := pycurl/pycurl.spec
ALL += pycurl

#
# BootServerRequest
#

BootServerRequest-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
BootServerRequest-INITIAL := HEAD
BootServerRequest-TAG := HEAD
BootServerRequest-MODULE := BootServerRequest
BootServerRequest-SPEC := BootServerRequest/PLBootServerRequest.spec
ALL += BootServerRequest

#
# PlanetLabID
#

PlanetLabID-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
PlanetLabID-INITIAL := HEAD
PlanetLabID-TAG := HEAD
PlanetLabID-MODULE := PlanetLabID
PlanetLabID-SPEC := PlanetLabID/PlanetLabID.spec
ALL += PlanetLabID

#
# Node Manager
#

sidewinder-CVSROOT := pup-sidewinder@cvs.planet-lab.org:/cvs
sidewinder-INITIAL := HEAD
sidewinder-TAG := HEAD
sidewinder-MODULE := sidewinder
sidewinder-SPEC := sidewinder/sidewinder.spec
ALL += sidewinder

#
# pl_sshd
#

pl_sshd-CVSROOT := pup-pl_sshd@cvs.planet-lab.org:/cvs
pl_sshd-INITIAL := HEAD
pl_sshd-TAG := HEAD
pl_sshd-MODULE := pl_sshd
pl_sshd-SPEC := pl_sshd/pl_sshd.spec
ALL += pl_sshd

ifeq ($(findstring $(package),$(ALL)),)

# Build all packages
all: $(ALL)

# Recurse
$(ALL):
	$(MAKE) package=$@

# Remove files generated by this package
$(foreach package,$(ALL),$(package)-clean): %-clean:
	$(MAKE) package=$* clean

# Remove all generated files
clean:
	rm -rf BUILD RPMS SOURCES SPECS SRPMS .rpmmacros .cvsps

.PHONY: all $(ALL) $(foreach package,$(ALL),$(package)-clean) clean

else

# Define variables for Makerules
CVSROOT := $($(package)-CVSROOT)
INITIAL := $($(package)-INITIAL)
TAG := $($(package)-TAG)
MODULE := $($(package)-MODULE)
SPEC := $($(package)-SPEC)
RPMFLAGS := $($(package)-RPMFLAGS)
RPMBUILD := $(if $($(package)-RPMBUILD),$($(package)-RPMBUILD),rpmbuild)
CVS_RSH := $(if $($(package)-CVS_RSH),$($(package)-CVS_RSH),ssh)

include Makerules

endif
