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
# $Id: Makefile,v 1.11 2004/04/12 14:12:41 alk-pl_rpm Exp $
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
# kernel-planetlab
#

kernel-planetlab-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
kernel-planetlab-INITIAL := linux-2_4_22
kernel-planetlab-TAG := HEAD
kernel-planetlab-MODULE := linux-2.4
kernel-planetlab-SPEC := linux-2.4/scripts/kernel-planetlab.spec
ALL += kernel-planetlab

#
# plkmod
#

plkmod-CVSROOT := pup-silk@cvs.planet-lab.org:/cvs
plkmod-INITIAL := HEAD
plkmod-TAG := HEAD
plkmod-MODULE := sys-v3
plkmod-SPEC := sys-v3/rpm/plkmod.spec
plkmod-RPMFLAGS = --define "kernelver $(shell rpmquery --queryformat '%{VERSION}-%{RELEASE}\n' --specfile SPECS/$(notdir $(kernel-planetlab-SPEC)) | head -1)"
ALL += plkmod

# Build kernel-planetlab first so we can bootstrap off of its build
plkmod: kernel-planetlab

#
# vdk
#

vdk-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
vdk-INITIAL := vdk_918
vdk-TAG := HEAD
vdk-MODULE := vdk
vdk-SPEC := vdk/vtune_driver.spec
vdk-RPMFLAGS = --define "kernelver $(shell rpmquery --queryformat '%{VERSION}-%{RELEASE}\n' --specfile SPECS/$(notdir $(kernel-planetlab-SPEC)) | head -1)"
ALL += vdk

# Build kernel-planetlab first so we can bootstrap off of its build
vdk: kernel-planetlab

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
# vsh
#

vsh-CVSROOT := pup-pl_kernel@cvs.planet-lab.org:/cvs
vsh-INITIAL := bash-2_05
vsh-TAG := HEAD
vsh-MODULE := vsh
vsh-SPEC := vsh/vsh-planetlab.spec
ALL += vsh

# Build kernel-planetlab first so we can bootstrap off of its build
vsh: kernel-planetlab

#
# yum
#

yum-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
yum-INITIAL := YUM_2_0_3
yum-TAG := YUM_2_0_3_PL_7
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
PlanetLabAccounts-INITIAL := PLANETLABACCOUNTS_0_3_R_2
PlanetLabAccounts-TAG := PLANETLABACCOUNTS_0_3_R_2
PlanetLabAccounts-MODULE := PlanetLabAccounts
PlanetLabAccounts-SPEC := PlanetLabAccounts/PlanetLabAccounts.spec
ALL += PlanetLabAccounts

#
# MAKEDEV
#

MAKEDEV-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
MAKEDEV-INITIAL := MAKEDEV_3_2_2
MAKEDEV-TAG := MAKEDEV_3_2_2_PL_6
MAKEDEV-MODULE := MAKEDEV
MAKEDEV-SPEC := MAKEDEV/MAKEDEV.spec
ALL += MAKEDEV

#
# NodeUpdate
#

NodeUpdate-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
NodeUpdate-INITIAL := NODEUPDATE_0_2_R_3
NodeUpdate-TAG := NODEUPDATE_0_2_R_3
NodeUpdate-MODULE := NodeUpdate
NodeUpdate-SPEC := NodeUpdate/NodeUpdate.spec
ALL += NodeUpdate

#
# PlanetLabConf
#

PlanetLabConf-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
PlanetLabConf-INITIAL := PLANETLABCONF_0_1_R_12
PlanetLabConf-TAG := PLANETLABCONF_0_1_R_12
PlanetLabConf-MODULE := PlanetLabConf
PlanetLabConf-SPEC := PlanetLabConf/PlanetLabConf.spec
ALL += PlanetLabConf

#
# PlanetLabKeys
#

PlanetLabKeys-CVSROOT := pup-node_pkgs@cvs.planet-lab.org:/cvs
PlanetLabKeys-INITIAL := PLANETLABKEYS_0_1_R_3
PlanetLabKeys-TAG := PLANETLABKEYS_0_1_R_3
PlanetLabKeys-MODULE := PlanetLabKeys
PlanetLabKeys-SPEC := PlanetLabKeys/PlanetLabKeys.spec
ALL += PlanetLabKeys

ifeq ($(findstring $(package),$(ALL)),)

# Build all packages
all: $(ALL)

# Recurse
$(ALL):
	$(MAKE) package=$@

.PHONY: all $(ALL)

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

# Remove generated files
clean:
	rm -rf BUILD RPMS SOURCES SPECS SRPMS .rpmmacros .cvsps

.PHONY: clean
