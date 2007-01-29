#
# PlanetLab standard components list
#
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2006 The Trustees of Princeton University
#
# $Id: onelab.mk,v 1.1 2007/01/27 08:39:38 thierry Exp $
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

CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs
TAG := HEAD

# Check if a tag has been checked out
ifneq ($(wildcard CVS/Root),)
# Check if we are able to access CVS
CVSTAG := $(shell cvs status planetlab.mk 2>/dev/null | sed -ne 's/[[:space:]]*Sticky Tag:[[:space:]]*\([^[:space:]]*\).*/\1/p')
ifneq ($(CVSTAG),)
CVSROOT := $(shell cat CVS/Root)
ifeq ($(CVSTAG),(none))
TAG := HEAD
else
TAG := $(CVSTAG)
endif
endif
endif

#
# kernel
#

#kernel-x86_64-MODULE := linux-2.6
#kernel-x86_64-RPMFLAGS:= --target x86_64
#kernel-x86_64-SPEC := linux-2.6/scripts/kernel-2.6-$(PLDISTRO).spec
##ALL += kernel-x86_64

kernel-i686-MODULE := linux-2.6
kernel-i686-RPMFLAGS:= --target i686
kernel-i686-SPEC := linux-2.6/scripts/kernel-2.6-$(PLDISTRO).spec
ALL += kernel-i686

#kernel-i586-MODULE := linux-2.6
#kernel-i586-RPMFLAGS:= --target i586
#kernel-i586-SPEC := linux-2.6/scripts/kernel-2.6-planetlab.spec
#ALL += kernel-i586

#kernel: kernel-i586 kernel-i686
#kernel-clean: kernel-i586-clean kernel-i686-clean
kernel: kernel-i686
kernel-clean: kernel-i686-clean

#
# vnet
#

vnet-MODULE := vnet
vnet-SPEC := vnet/vnet.spec
ALL += vnet

# Build kernel first so we can bootstrap off of its build
vnet: kernel

#
# madwifi
#

madwifi-ng-MODULE := madwifi-ng
madwifi-ng-SPEC := madwifi-ng/madwifi.spec
ALL += madwifi-ng

# Build kernel first so we can bootstrap off of its build
madwifi-ng: kernel

#
# ivtv 
#

#ivtv-MODULE := ivtv
#ivtv-SPEC := ivtv/ivtv.spec
#ALL += ivtv

#
# util-vserver
#

util-vserver-MODULE := util-vserver
util-vserver-SPEC := util-vserver/util-vserver.spec
util-vserver-RPMFLAGS:= --without dietlibc
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

NodeManager-MODULE := NodeManager
NodeManager-SPEC := NodeManager/NodeManager.spec
ALL += NodeManager

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
# PLCAPI
#

PLCAPI-MODULE := new_plc_api
PLCAPI-SPEC := new_plc_api/PLCAPI.spec
ALL += PLCAPI

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

myplc-MODULE := $(sort $(foreach module,$(ALL),$($(module)-MODULE)) myplc new_plc_www plc/scripts)
myplc-SPEC := myplc/myplc.spec
# Package must be built as root
myplc-RPMBUILD := sudo rpmbuild
ALL += myplc

# MyPLC may require current packages
myplc: $(filter-out myplc,$(ALL))

# ...and the yum manifest
myplc: RPMS/yumgroups.xml

#
# MyPLC development environment
#

###myplc-devel-MODULE := build myplc
###myplc-devel-SPEC := myplc/myplc-devel.spec
#### Package must be built as root
###myplc-devel-RPMBUILD := sudo rpmbuild
###ALL += myplc-devel

#
# Installation rules
# 

# Upload packages to boot server
SERVER		:= root@onelab-plc.inria.fr
RPMSAREA	:= /plc/data/var/www/html/install-rpms/
BOOTAREA	:= /plc/data/var/www/html/boot/

YUMGROUPS	:= $(PLDISTRO).xml
#BASE		:= onelab
BASETMP		:= planetlab-upgrading
BASEBAK		:= planetlab-bak
BASE		:= planetlab

RPMS/yumgroups.xml:
	install -D -m 644 $(YUMGROUPS) RPMS/yumgroups.xml

install: install-rpms install-index install-bootstrap

install-rpms:RPMS/yumgroups.xml
        # create repository
	ssh $(SERVER) mkdir -p $(RPMSAREA)/$(BASETMP)
	# populate
	rsync -v --perms --times --group --compress --rsh=ssh \
	   RPMS/yumgroups.xml $(wildcard RPMS/*/*.rpm) $(SERVER):$(RPMSAREA)/$(BASETMP)/

# would be better if we could run plc.d/packages on a temporary dir
# currently while we run packages clients wont be able to use the repo (nor signed nor indexed)
install-index:
	# cleanup former bak
	ssh $(SERVER) rm -rf $(RPMSAREA)/$(BASEBAK)
	# bak previous repo
	ssh $(SERVER) mv $(RPMSAREA)/$(BASE) $(RPMSAREA)/$(BASEBAK)
	# install new repo
	ssh $(SERVER) mv $(RPMSAREA)/$(BASETMP) $(RPMSAREA)/$(BASE)
	# sign and re-index
	ssh $(SERVER) chroot /plc/root service plc start packages

install-bootstrap:
	# install node image
	install_bz2=$(wildcard BUILD/bootmanager-*/bootmanager/support-files/PlanetLab-Bootstrap.tar.bz2) ; \
	  if [ -n "$$install_bz2" ] ; then rsync $$install_bz2 $(SERVER):$(BOOTAREA) ; fi
#endif

.PHONY: install
