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
# $Id: Makefile,v 1.24 2004/04/13 22:16:32 mlh-pl_rpm Exp $
#

# Default target
all:

#
# CVSROOT: CVSROOT to use
# INITIAL: CVS tag to use for Source0 tarball
# TAG: CVS tag to patch to
# MODULE: CVS module name to use
# SPEC: RPM spec file template
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

kernel-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
kernel-INITIAL := linux-2_4_22
kernel-TAG := HEAD
kernel-MODULE := linux-2.4
kernel-SPEC := linux-2.4/scripts/kernel-planetlab.spec
ALL += kernel

#
# plkmod
#

plkmod-CVSROOT := pup-silk@cvs.planet-lab.org:/cvs
plkmod-INITIAL := HEAD
plkmod-TAG := HEAD
plkmod-MODULE := sys-v3
plkmod-SPEC := sys-v3/rpm/plkmod.spec
plkmod-RPMFLAGS = --define "kernelver $(shell rpmquery --queryformat '%{VERSION}-%{RELEASE}\n' --specfile SPECS/$(notdir $(kernel-SPEC)) | head -1)"
ALL += plkmod

# Build kernel first so we can bootstrap off of its build
plkmod: kernel

#
# vdk
#

vdk-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
vdk-INITIAL := vdk_918
vdk-TAG := HEAD
vdk-MODULE := vdk
vdk-SPEC := vdk/vtune_driver.spec
vdk-RPMFLAGS = --define "kernelver $(shell rpmquery --queryformat '%{VERSION}-%{RELEASE}\n' --specfile SPECS/$(notdir $(kernel-SPEC)) | head -1)"
ALL += vdk

# Build kernel first so we can bootstrap off of its build
vdk: kernel

#
# lkcdutils
#

lkcdutils-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
lkcdutils-INITIAL := lkcdutils-4_1
lkcdutils-TAG := HEAD
lkcdutils-MODULE := lkcdutils
lkcdutils-SPEC := lkcdutils/spec/lkcdutils.spec
ALL += lkcdutils

# Build kernel first so we can bootstrap off of its build
lkcdutils: kernel

#
# vserver
#

vserver-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
vserver-INITIAL := vserver-0_29
vserver-TAG := HEAD
vserver-MODULE := vserver
vserver-SPEC := vserver/vserver.spec
ALL += vserver

#
# vserver-init
#

vserver-init-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
vserver-init-INITIAL := HEAD
vserver-init-TAG := HEAD
vserver-init-MODULE := vserver-init
vserver-init-SPEC := vserver-init/vserver-init.spec
ALL += vserver-init

#
# vr-tools
#

vr-tools-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
vr-tools-INITIAL := HEAD
vr-tools-TAG := HEAD
vr-tools-MODULE := vr-tools
vr-tools-SPEC := vr-tools/vr-tools.spec
ALL += vr-tools

#
# vsh
#

vsh-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
vsh-INITIAL := bash-2_05
vsh-TAG := HEAD
vsh-MODULE := vsh
vsh-SPEC := vsh/vsh-planetlab.spec
ALL += vsh

# Build kernel first so we can bootstrap off of its build
vsh: kernel

#
# e2fsprogs
#

e2fsprogs-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
e2fsprogs-INITIAL := e2fsprogs-1_33
e2fsprogs-TAG := HEAD
e2fsprogs-MODULE := e2fsprogs
e2fsprogs-SPEC := e2fsprogs/e2fsprogs.spec
ALL += e2fsprogs

#
# initscripts
#

initscripts-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
initscripts-INITIAL := initscripts-7_14
initscripts-TAG := HEAD
initscripts-MODULE := initscripts
initscripts-SPEC := initscripts/initscripts.spec
ALL += initscripts

#
# cq-tools
#

cq-tools-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
cq-tools-INITIAL := HEAD
cq-tools-TAG := HEAD
cq-tools-MODULE := cq-tools
cq-tools-SPEC := cq-tools/cq-tools.spec
ALL += cq-tools

#
# yum
#

yum-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
yum-INITIAL := YUM_2_0_3
yum-TAG := HEAD
yum-MODULE := yum
yum-SPEC := yum/yum.spec
ALL += yum

#
# ksymoops
#

ksymoops-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
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
# MAKEDEV
#

MAKEDEV-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
MAKEDEV-INITIAL := MAKEDEV_3_2_2
MAKEDEV-TAG := HEAD
MAKEDEV-MODULE := MAKEDEV
MAKEDEV-SPEC := MAKEDEV/MAKEDEV.spec
ALL += MAKEDEV

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
# perl-IO-Stty
#

perl-IO-Stty-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
perl-IO-Stty-INITIAL := PERL-IO-STTY_0_2
perl-IO-Stty-TAG := HEAD
perl-IO-Stty-MODULE := perl-IO-Stty
perl-IO-Stty-SPEC := perl-IO-Stty/perl-IO-Stty.spec
ALL += perl-IO-Stty

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
# blacklist
#

blacklist-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
blacklist-INITIAL := HEAD
blacklist-TAG := HEAD
blacklist-MODULE := blacklist
blacklist-SPEC := blacklist/PlanetLab-blacklist.spec
ALL += blacklist

#
# httpd
#

httpd-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
httpd-INITIAL := HEAD
httpd-TAG := HEAD
httpd-MODULE := httpd
httpd-SPEC := httpd/httpd.spec
ALL += httpd

#
# BootServerRequest
#

BootServerRequest-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
BootServerRequest-INITIAL := HEAD
BootServerRequest-TAG := HEAD
BootServerRequest-MODULE := BootServerRequest
BootServerRequest-SPEC := BootServerRequest/PLBootServerRequest.spec
ALL += BootServerRequest

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
CVS_RSH := $(if $($(package)-CVS_RSH),$($(package)-CVS_RSH),ssh)

include Makerules

endif
