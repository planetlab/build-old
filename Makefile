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
# $Id$
#

# Default target
all:

#
# CVSROOT: CVSROOT to use
# INITIAL: CVS tag to use for Source0 tarball
# TAG: CVS tag to patch to (if not HEAD)
# MODULE: CVS module name to use (if not HEAD)
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

# Default tags
INITIAL := planetlab-3_0-rc11
TAG := planetlab-3_0-rc11

#
# kernel
#

kernel-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
kernel-MODULE := linux-2.6
kernel-SPEC := linux-2.6/scripts/kernel-2.6-planetlab.spec
ALL += kernel

#
# vnet
#

vnet-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
vnet-MODULE := vnet
vnet-SPEC := vnet/vnet.spec
ALL += vnet

# Build kernel first so we can bootstrap off of its build
vnet: kernel

#
# util-vserver
#

util-vserver-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
util-vserver-MODULE := util-vserver
util-vserver-SPEC := util-vserver/util-vserver.spec
ALL += util-vserver

# Build kernel first so we can bootstrap off of its build
util-vserver: kernel

#
# vserver-reference
#

vserver-reference-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
vserver-reference-MODULE := vserver-reference
vserver-reference-SPEC := vserver-reference/vserver-reference.spec
ALL += vserver-reference

#
# lkcdutils
#

lkcdutils-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
lkcdutils-MODULE := lkcdutils
lkcdutils-SPEC := lkcdutils/spec/lkcdutils.spec
ALL += lkcdutils

# Build kernel first so we can bootstrap off of its build
lkcdutils: kernel

#
# yum
#

yum-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
yum-MODULE := yum
yum-SPEC := yum/yum.spec
ALL += yum

#
# ksymoops
#

ksymoops-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
ksymoops-INITIAL := ksymoops-2_4_9
ksymoops-MODULE := ksymoops
ksymoops-SPEC := ksymoops/ksymoops.spec
ALL += ksymoops

#
# PlanetLabAccounts
#

PlanetLabAccounts-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
PlanetLabAccounts-MODULE := PlanetLabAccounts
PlanetLabAccounts-SPEC := PlanetLabAccounts/PlanetLabAccounts.spec
ALL += PlanetLabAccounts

#
# NodeUpdate
#

NodeUpdate-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
NodeUpdate-MODULE := NodeUpdate
NodeUpdate-SPEC := NodeUpdate/NodeUpdate.spec
ALL += NodeUpdate

#
# PlanetLabConf
#

PlanetLabConf-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
PlanetLabConf-MODULE := PlanetLabConf
PlanetLabConf-SPEC := PlanetLabConf/PlanetLabConf.spec
ALL += PlanetLabConf

#
# PlanetLabKeys
#

PlanetLabKeys-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
PlanetLabKeys-MODULE := PlanetLabKeys
PlanetLabKeys-SPEC := PlanetLabKeys/PlanetLabKeys.spec
ALL += PlanetLabKeys

#
# ipod
#

ipod-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
ipod-MODULE := ipod
ipod-SPEC := ipod/ipod.spec
ALL += ipod

#
# sudo
#

sudo-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
sudo-MODULE := sudo
sudo-SPEC := sudo/planetlab_sudo.spec
ALL += sudo

#
# pycurl
#

pycurl-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
pycurl-MODULE := pycurl
pycurl-SPEC := pycurl/pycurl.spec
ALL += pycurl

#
# BootServerRequest
#

BootServerRequest-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
BootServerRequest-MODULE := BootServerRequest
BootServerRequest-SPEC := BootServerRequest/PLBootServerRequest.spec
ALL += BootServerRequest

#
# PlanetLabID
#

PlanetLabID-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
PlanetLabID-MODULE := PlanetLabID
PlanetLabID-SPEC := PlanetLabID/PlanetLabID.spec
ALL += PlanetLabID

#
# Node Manager
#

sidewinder-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
sidewinder-MODULE := sidewinder
sidewinder-SPEC := sidewinder/sidewinder.spec
ALL += sidewinder

#
# pl_sshd
#

pl_sshd-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
pl_sshd-MODULE := pl_sshd
pl_sshd-SPEC := pl_sshd/pl_sshd.spec
ALL += pl_sshd

#
# Resource Management Tools
#

resman-CVSROOT := :pserver:anon@build.planet-lab.org:/cvs
resman-MODULE := resman
resman-SPEC := resman/resman.spec
ALL += resman

#
# Proper: Privileged Operations Service
#

proper-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
proper-MODULE := proper
proper-SPEC := proper/proper.spec
ALL += proper

#
# ulogd
#

ulogd-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
ulogd-MODULE := ulogd
ulogd-SPEC := ulogd/ulogd.spec
ALL += ulogd

ulogd: kernel proper

#
# netflow and netsummary
#

netflow-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
netflow-MODULE := netflow netsummary
netflow-SPEC := netflow/netflow.spec
ALL += netflow

#
# PlanetLab Mom: Cleans up your mess
#

pl_mom-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
pl_mom-MODULE := pl_mom
pl_mom-SPEC := pl_mom/pl_mom.spec
ALL += pl_mom

#
# iptables
#

iptables-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
iptables-MODULE := iptables
iptables-SPEC := iptables/iptables.spec
ALL += iptables

iptables: kernel

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
INITIAL := $(if $($(package)-INITIAL),$($(package)-INITIAL),$(INITIAL))
TAG := $(if $($(package)-TAG),$($(package)-TAG),$(TAG))
MODULE := $($(package)-MODULE)
SPEC := $($(package)-SPEC)
RPMFLAGS := $($(package)-RPMFLAGS)
CVS_RSH := $(if $($(package)-CVS_RSH),$($(package)-CVS_RSH),ssh)

include Makerules

endif
