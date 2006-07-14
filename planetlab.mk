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
# TAG or package-TAG: CVS tag to use
# package-MODULE: CVS module name to use
# package-SPEC: RPM spec file template
#
# Optional:
#
# package-RPMFLAGS: Miscellaneous RPM flags
# package-RPMBUILD: If not rpmbuild
# package-CVS_RSH: If not ssh
#
# Add to ALL if you want the package built as part of the default set.
#

#
# Default values
#

ifneq ($(wildcard CVS/Root),)
CVSROOT := $(shell cat CVS/Root)
TAG := $(shell cvs status planetlab.mk | sed -ne 's/[[:space:]]*Sticky Tag:[[:space:]]*\([^[:space:]]*\).*/\1/p')
ifeq ($(TAG),(none))
TAG := HEAD
endif
else
CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
TAG := HEAD
endif

#
# kernel
#

kernel-MODULE := linux-2.6
kernel-SPEC := linux-2.6/scripts/kernel-2.6-planetlab.spec
ALL += kernel

#
# vnet
#

vnet-MODULE := vnet
vnet-SPEC := vnet/vnet.spec
ALL += vnet

# Build kernel first so we can bootstrap off of its build
vnet: kernel

#
# util-vserver
#

util-vserver-MODULE := util-vserver
util-vserver-SPEC := util-vserver/util-vserver.spec
ALL += util-vserver

#
# yum
#

yum-MODULE := yum
yum-SPEC := yum/yum.spec
ALL += yum

#
# PlanetLabAccounts
#

PlanetLabAccounts-MODULE := PlanetLabAccounts
PlanetLabAccounts-SPEC := PlanetLabAccounts/PlanetLabAccounts.spec
ALL += PlanetLabAccounts

#
# NodeUpdate
#

NodeUpdate-MODULE := NodeUpdate
NodeUpdate-SPEC := NodeUpdate/NodeUpdate.spec
ALL += NodeUpdate

#
# PlanetLabConf
#

PlanetLabConf-MODULE := PlanetLabConf
PlanetLabConf-SPEC := PlanetLabConf/PlanetLabConf.spec
ALL += PlanetLabConf

#
# ipod
#

ipod-MODULE := ipod
ipod-SPEC := ipod/ipod.spec
ALL += ipod

#
# sudo
#

sudo-MODULE := sudo
sudo-SPEC := sudo/planetlab_sudo.spec
ALL += sudo

#
# pycurl
#

pycurl-MODULE := pycurl
pycurl-SPEC := pycurl/pycurl.spec
ALL += pycurl

#
# BootServerRequest
#

BootServerRequest-MODULE := BootServerRequest
BootServerRequest-SPEC := BootServerRequest/PLBootServerRequest.spec
ALL += BootServerRequest

#
# PlanetLabID
#

PlanetLabID-MODULE := PlanetLabID
PlanetLabID-SPEC := PlanetLabID/PlanetLabID.spec
ALL += PlanetLabID

#
# Node Manager
#

sidewinder-MODULE := sidewinder
sidewinder-SPEC := sidewinder/sidewinder.spec
ALL += sidewinder

#
# pl_sshd
#

pl_sshd-MODULE := pl_sshd
pl_sshd-SPEC := pl_sshd/pl_sshd.spec
ALL += pl_sshd

#
# libhttpd++: 
#

libhttpd++-MODULE := libhttpd++
libhttpd++-SPEC := libhttpd++/libhttpd++.spec
ALL += libhttpd++

#
# Proper: Privileged Operations Service
#

proper-MODULE := proper
proper-SPEC := proper/proper.spec
ALL += proper

proper: libhttpd++

#
# MySQL
#

mysql-MODULE := mysql
mysql-SPEC := mysql/mysql.spec
ALL += mysql

#
# ulogd
#

ulogd-MODULE := ulogd
ulogd-SPEC := ulogd/ulogd.spec
ALL += ulogd

ulogd: kernel proper mysql

#
# netflow
#

netflow-MODULE := netflow
netflow-SPEC := netflow/netflow.spec
ALL += netflow

netflow: mysql

#
# PlanetLab Mom: Cleans up your mess
#

pl_mom-MODULE := pl_mom
pl_mom-SPEC := pl_mom/pl_mom.spec
ALL += pl_mom

#
# iptables
#

iptables-MODULE := iptables
iptables-SPEC := iptables/iptables.spec
ALL += iptables

iptables: kernel

#
# iproute
#

iproute-MODULE := iproute2
iproute-SPEC := iproute2/iproute.spec
ALL += iproute

#
# kexec-tools
#

kexec-tools-MODULE := kexec-tools
kexec-tools-SPEC := kexec-tools/kexec-tools.spec
ALL += kexec-tools

#
# dhcp
#

dhcp-MODULE := dhcp
dhcp-SPEC := dhcp/dhcp.spec
ALL += dhcp

#
# util-python
#

util-python-MODULE := util-python
util-python-SPEC := util-python/util-python.spec
ALL += util-python

# proper and util-vserver both use scripts in util-python for building
proper: util-python
util-vserver: util-python
PlanetLabAuth: util-python

#
# PlanetLabAuth
#

PlanetLabAuth-MODULE := pl_auth
PlanetLabAuth-SPEC := pl_auth/pl_auth.spec
ALL += PlanetLabAuth

#
# plcapilib
#

plcapilib-MODULE := plcmdline
plcapilib-SPEC := plcmdline/plcapilib.spec
ALL += plcapilib

#
# vserver-reference
#

vserver-reference-MODULE := vserver-reference build
vserver-reference-SPEC := vserver-reference/vserver-reference.spec
# Package must be built as root
vserver-reference-RPMBUILD := sudo rpmbuild
ALL += vserver-reference

# vserver-reference may require current packages
vserver-reference: $(filter-out vserver-reference,$(ALL))

#
# bootmanager
#

bootmanager-MODULE := bootmanager build
bootmanager-SPEC := bootmanager/bootmanager.spec
bootmanager-RPMBUILD := sudo rpmbuild
ALL += bootmanager

# bootmanager requires current packages
bootmanager: $(filter-out bootmanager,$(ALL))

# ...and the yum manifest
bootmanager: RPMS/yumgroups.xml

#
# bootcd
#

bootcd-MODULE := bootcd build bootmanager
bootcd-SPEC := bootcd/bootcd.spec
bootcd-RPMBUILD := sudo rpmbuild
ALL += bootcd

# bootcd requires current packages
bootcd: $(filter-out bootcd,$(ALL))

#
# MyPLC
#

myplc-MODULE := $(sort $(foreach module,$(ALL),$($(module)-MODULE))) myplc
myplc-SPEC := myplc/myplc.spec
# Package must be built as root
myplc-RPMBUILD := sudo rpmbuild
ALL += myplc

# MyPLC may require current packages
myplc: $(filter-out myplc,$(ALL))

# ...and the yum manifest
myplc: RPMS/yumgroups.xml

#
# Installation rules
# 

# Upload packages to boot server
SERVER := build@boot.planet-lab.org
ARCHIVE := /var/www/html/install-rpms/archive

# Put nightly alpha builds in a subdirectory
ifeq ($(TAG),HEAD)
ARCHIVE := $(ARCHIVE)/planetlab-alpha
REPOS := /var/www/html/install-rpms/planetlab-alpha
endif

RPMS/yumgroups.xml:
	install -D -m 644 groups/v3_yumgroups.xml RPMS/yumgroups.xml

install:
ifeq ($(BASE),)
	@echo make install is only meant to be called from ./build.sh
else
ifneq ($(wildcard /etc/planetlab/secring.gpg),)
        # Sign all RPMS. setsid detaches rpm from the terminal,
        # allowing the (hopefully blank) GPG password to be entered
        # from stdin instead of /dev/tty. Obviously, the build server
        # should be secure.
	echo | setsid rpm \
	--define "_signature gpg" \
	--define "_gpg_path /etc/planetlab" \
	--define "_gpg_name PlanetLab <info@planet-lab.org>" \
	--resign RPMS/*/*.rpm SRPMS/*.rpm
endif
ifneq ($(BUILDS),)
        # Remove old runs
	echo "cd $(ARCHIVE) && ls -t | sed -n $(BUILDS)~1p | xargs rm -rf" | ssh $(SERVER) /bin/bash -s
endif
        # Create package manifest
	sh ./packages.sh -b "http://build.planet-lab.org/$(subst $(HOME)/,,$(shell pwd))/RPMS" RPMS > packages.xml
        # Populate repository
	ssh $(SERVER) mkdir -p $(ARCHIVE)/$(BASE)/RPMS $(ARCHIVE)/$(BASE)/SRPMS
	rsync --delete --links --perms --times --group --compress --rsh=ssh \
	    $(sort $(subst -debuginfo,,$(wildcard RPMS/yumgroups.xml RPMS/*/*.rpm))) $(SERVER):$(ARCHIVE)/$(BASE)/RPMS/
	ssh $(SERVER) yum-arch $(ARCHIVE)/$(BASE)/RPMS >/dev/null
	ssh $(SERVER) createrepo -g yumgroups.xml $(ARCHIVE)/$(BASE)/RPMS >/dev/null
	rsync --delete --links --perms --times --group --compress --rsh=ssh \
	    $(wildcard SRPMS/*.rpm) $(SERVER):$(ARCHIVE)/$(BASE)/SRPMS/
	ssh $(SERVER) yum-arch $(ARCHIVE)/$(BASE)/SRPMS >/dev/null
	ssh $(SERVER) createrepo $(ARCHIVE)/$(BASE)/SRPMS >/dev/null
ifeq ($(TAG),HEAD)
        # Update nightly alpha symlink if it does not exist or is broken, or it is Monday
	if ! ssh $(SERVER) "[ -e $(REPOS) ] && exit 0 || exit 1" || [ "$(shell date +%A)" = "Monday" ] ; then \
	    ssh $(SERVER) ln -nsf $(ARCHIVE)/$(BASE)/RPMS/ $(REPOS) ; \
	fi
endif
endif

.PHONY: install
