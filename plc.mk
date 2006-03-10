#
# PlanetLab Central components list
#
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2005 The Trustees of Princeton University
#
# $Id: plc.mk,v 1.9 2006/03/08 21:45:27 mlhuang Exp $
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

#
# plc
#

plc-CVSROOT := :ext:cvs.planet-lab.org:/cvs
plc-MODULE := plc
plc-SPEC := plc/plc.spec
ALL += plc

#
# Proper: Privileged Operations Service
#

proper-MODULE := proper
proper-SPEC := proper/proper.spec
ALL += proper

#
# util-python
#
util-python-MODULE := util-python
util-python-SPEC := util-python/util-python.spec
ALL += util-python

# proper and util-vserver both use scripts in util-python for building
proper: util-python
util-vserver: util-python

#
# ulogd
#

ulogd-MODULE := ulogd
ulogd-SPEC := ulogd/ulogd.spec
ALL += ulogd

ulogd: proper

#
# netflow
#

netflow-MODULE := netflow
netflow-SPEC := netflow/netflow.spec
ALL += netflow

#
# Request Tracker 3
#

rt3-MODULE := rt3
rt3-SPEC := rt3/etc/rt.spec
ALL += rt3

#
# Mail::SpamAssassin
#

spamassassin-MODULE := spamassassin
spamassassin-SPEC := spamassassin/spamassassin.spec
ALL += spamassassin

#
# TWiki
#

twiki-MODULE := twiki
twiki-SPEC := twiki/TWiki.spec
ALL += twiki

#
# plcapilib
#

plcapilib-MODULE := plcmdline
plcapilib-SPEC := plcmdline/plcapilib.spec
ALL += plcapilib

#
# Installation rules
# 

# Put packages in boot repository
ARCHIVE := /var/www/html/archive

# Put nightly alpha builds in a subdirectory
ifeq ($(TAG),HEAD)
ARCHIVE := $(ARCHIVE)/plc-alpha
REPOS := /var/www/html/plc-alpha
endif

install:
ifeq ($(BASE),)
	@echo make install is only meant to be called from ./build.sh
else
ifneq ($(BUILDS),)
        # Remove old runs
	cd $(ARCHIVE) && ls -t | sed -n $(BUILDS)~1p | xargs rm -rf
endif
	install -D -m 644 groups/stock_fc2_groups.xml RPMS/yumgroups.xml
        # Populate repository
	mkdir -p $(ARCHIVE)/$(BASE)
	rsync --delete --links --perms --times --group \
	    $(sort $(subst -debuginfo,,$(wildcard RPMS/yumgroups.xml RPMS/*/*))) $(ARCHIVE)/$(BASE)/
	yum-arch $(ARCHIVE)/$(BASE) >/dev/null
ifeq ($(TAG),HEAD)
	ln -nsf $(ARCHIVE)/$(BASE) $(REPOS)
endif
endif

.PHONY: install
