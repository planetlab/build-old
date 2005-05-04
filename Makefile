#
# PlanetLab RPM generation
#
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2005 The Trustees of Princeton University
#
# $Id: Makefile,v 1.65 2005/05/04 19:57:08 mlhuang Exp $
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

# Default values
INITIAL := HEAD
TAG := HEAD
CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs

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
# netflow
#

netflow-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
netflow-MODULE := netflow
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

#
# kexec-tools
#

kexec-tools-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
kexec-tools-MODULE := kexec-tools
kexec-tools-SPEC := kexec-tools/kexec-tools.spec
ALL += kexec-tools

#
# Request Tracker 3
#

rt3-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
rt3-MODULE := rt3
rt3-SPEC := rt3/etc/rt.spec
ALL += rt3

#
# Mail::SpamAssassin
#

spamassassin-CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
spamassassin-MODULE := spamassassin
spamassassin-SPEC := spamassassin/spamassassin.spec
ALL += spamassassin

#
# PlanetLab Central Server Management
#

plc-CVSROOT := :ext:cvs.planet-lab.org:/cvs
plc-MODULE := plc
plc-SPEC := plc/plc.spec
# Do not build by default
# ALL += plc
PACKAGES += plc

ifeq ($(findstring $(package),$(ALL)),)

# Build all packages
all: $(ALL)
        # XXX Should check out a tagged version of yumgroups.xml
	cvs -d $(CVSROOT) checkout -p alpina/groups/v3_yumgroups.xml > RPMS/yumgroups.xml
        # Create package manifest
	sh ./packages.sh -b "http://build.planet-lab.org/$(subst $(HOME)/,,$(shell pwd))/SRPMS" SRPMS > SRPMS/packages.xml

# Recurse
$(ALL) $(PACKAGES):
	$(MAKE) package=$@

# Upload packages to boot server
SERVER := build@boot.planet-lab.org
ARCHIVE := /var/www/html/install-rpms/archive

# Put nightly alpha builds in a subdirectory
ifeq ($(TAG),HEAD)
ARCHIVE := $(ARCHIVE)/planetlab-alpha
REPOS := /var/www/html/install-rpms/planetlab-alpha
endif

install:
ifeq ($(BASE),)
	@echo make install is only meant to be called from ./build.sh
else
ifneq ($(BUILDS),)
        # Remove old runs
	echo "cd $(ARCHIVE) && ls -t | sed -n $(BUILDS)~1p | xargs rm -rf" | ssh $(SERVER) /bin/bash -s
endif
        # Populate repository
	ssh $(SERVER) mkdir -p $(ARCHIVE)/$(BASE)/RPMS $(ARCHIVE)/$(BASE)/SRPMS
	rsync --links --perms --times --group --compress --rsh=ssh \
	    RPMS/yumgroups.xml $(sort $(subst -debuginfo,,$(wildcard RPMS/*/*))) $(SERVER):$(ARCHIVE)/$(BASE)/RPMS/
	ssh $(SERVER) yum-arch $(ARCHIVE)/$(BASE)/RPMS >/dev/null
	rsync --links --perms --times --group --compress --rsh=ssh \
	    $(wildcard SRPMS/*) $(SERVER):$(ARCHIVE)/$(BASE)/SRPMS/
	ssh $(SERVER) yum-arch $(ARCHIVE)/$(BASE)/SRPMS >/dev/null
ifeq ($(TAG),HEAD)
        # Update nightly alpha symlink if it does not exist or is broken, or it is Monday
	if ! ssh $(SERVER) "[ -e $(REPOS) ] && exit 0 || exit 1" || [ "$(shell date +%A)" = "Monday" ] ; then \
	    ssh $(SERVER) ln -nsf $(ARCHIVE)/$(BASE)/RPMS/ $(REPOS) ; \
	fi
endif
endif

# Remove files generated by this package
$(foreach package,$(ALL),$(package)-clean): %-clean:
	$(MAKE) package=$* clean

# Remove all generated files
clean:
	rm -rf BUILD RPMS SOURCES SPECS SRPMS .rpmmacros .cvsps

.PHONY: all $(ALL) $(foreach package,$(ALL),$(package)-clean) clean

else

# Define variables for Makerules
CVSROOT := $(if $($(package)-CVSROOT),$($(package)-CVSROOT),$(CVSROOT))
INITIAL := $(if $($(package)-INITIAL),$($(package)-INITIAL),$(INITIAL))
TAG := $(if $($(package)-TAG),$($(package)-TAG),$(TAG))
MODULE := $($(package)-MODULE)
SPEC := $($(package)-SPEC)
RPMFLAGS := $($(package)-RPMFLAGS)
CVS_RSH := $(if $($(package)-CVS_RSH),$($(package)-CVS_RSH),ssh)

include Makerules

endif
