#
# Thierry Parmentelat - INRIA Sophia Antipolis 
#
### $Id: onelab-install.mk 685 2007-07-19 09:01:41Z thierry $
# 
# Installation rules
# 

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
BOOTAREA	:= /var/www/html/boot/

#BASE		:= onelab
BASENEW		:= build-$(notdir $(shell pwd))
BASEBAK		:= planetlab-bak
BASE		:= planetlab

##########
# if make is invoked with -n, run rsync, but with --dry-run
RSYNC_COND_DRY_RUN	:= $(if $(findstring n,$(MAKEFLAGS)),--dry-run,)
RSYNC			:= rsync $(RSYNC_COND_DRY_RUN) 

INSTALL-TARGETS := install-rpms install-index install-adopt install-bootstrap
install: $(INSTALL-TARGETS)
.PHONY: install $(INSTALL-TARGETS)

install-help:
	@echo install: $(INSTALL-TARGETS)

install-rpms:RPMS/yumgroups.xml
        # create repository
	ssh $(PLCSSH) mkdir -p /plc/data/$(RPMSAREA)/$(BASENEW)
	# populate
	+$(RSYNC) -v --perms --times --group --compress --rsh=ssh \
	   RPMS/yumgroups.xml $(wildcard RPMS/*/*.rpm) $(PLCSSH):/plc/data/$(RPMSAREA)/$(BASENEW)/

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
	install_bz2=$(wildcard BUILD/bootmanager-*/bootmanager/support-files/PlanetLab-Bootstrap.tar.bz2) ; \
	  if [ -n "$$install_bz2" ] ; then rsync $$install_bz2 $(PLCSSH):/plc/data/$(BOOTAREA) ; fi


