#
# Thierry Parmentelat - INRIA Sophia Antipolis 
#
### $Id$
# 
# Installation rules
# 

install:
	@echo WARNING: this target is deprecated
	@echo you might siwh to use the noderepo rpm instead
	@echo former behaviour is available throuhg make install-obsolete

# make install :
# 	uses $(PLCSSH) as an ssh address for the destination host
# 	first copies everything on a separate rpm repo, prepares it, 
#	and then renames it into planetlab

# Upload packages to boot server

# use PLCHOST if set
ifdef PLCHOST
PLCSSH:=root@$(PLCHOST)
endif
# if nothing's defined : use this default
ifndef PLCSSH
PLCSSH		:= root@private.one-lab.org
endif

RPMSAREA	:= /var/www/html/install-rpms/

BUILD_BASE	:= $(shell cat .base 2> /dev/null || echo base-undefined)
BASENEW		:= build-$(BUILD_BASE)
BASEBAK		:= planetlab-bak
BASE		:= planetlab

##########
# if make is invoked with -n, run rsync, but with --dry-run
RSYNC_COND_DRY_RUN	:= $(if $(findstring n,$(MAKEFLAGS)),--dry-run,)
RSYNC			:= rsync $(RSYNC_COND_DRY_RUN) 

INSTALL-TARGETS := install-rpms install-index install-adopt install-bootstrap
install-obsolete: $(INSTALL-TARGETS)
.PHONY: install install-obsolete $(INSTALL-TARGETS)

install-help:
	@echo install-obsolete: $(INSTALL-TARGETS)

# compute the exact set of rpms to install - we do not need bootstrapfs nor myplc here
node_packages=$(sort $(IN_VSERVER) $(IN_BOOTSTRAPFS))
node_rpms=$(foreach package,$(node_packages),$($(package).rpms))

install-rpms:RPMS/yumgroups.xml
        # create repository
	ssh $(PLCSSH) mkdir -p /plc/data/$(RPMSAREA)/$(BASENEW)
	# populate
	+$(RSYNC) -v --perms --times --group --compress --rsh=ssh \
	   RPMS/yumgroups.xml $(node_rpms) $(PLCSSH):/plc/data/$(RPMSAREA)/$(BASENEW)/

install-index:
	# sign and index new repository
	ssh $(PLCSSH) chroot /plc/root /etc/plc.d/packages start $(RPMSAREA)/$(BASENEW)/ 2>> install-index.log

install-clean-index:
	# sign and index new repository
	ssh $(PLCSSH) chroot /plc/root /etc/plc.d/packages clean $(RPMSAREA)/$(BASENEW)/ 2>> install-index.log

install-adopt:
	# cleanup former bak
	ssh $(PLCSSH) rm -rf /plc/data/$(RPMSAREA)/$(BASEBAK)
	# bak previous repo
	ssh $(PLCSSH) mv /plc/data/$(RPMSAREA)/$(BASE) /plc/data/$(RPMSAREA)/$(BASEBAK)
	# install new repo
	ssh $(PLCSSH) mv /plc/data/$(RPMSAREA)/$(BASENEW) /plc/data/$(RPMSAREA)/$(BASE)

install-bootstrap:
	# install node image
	ssh $(PLCSSH) chroot /plc/root yum -y update bootstrapfs
