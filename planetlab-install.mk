#XXX We need to rethink this installation support for several reasons:
# 1) it is pldistro specific
# 2) may involve installing files for different node groups (e.g., alpha, beta, etc.)
# 3) may involve N rpm repositories to where it should be uploaded
#
# Not clear to me at all that this should be incorporated into a
# Makefile at all.  Instead it should be something that gets wrapped
# into a myplc (sub) rpm package and then is installed by that way.

#
# Installation rules
# 

# Upload packages to boot server
SERVERA := build@boot1.planet-lab.org
SERVERB := build@boot2.planet-lab.org
ARCHIVE := /plc/data/var/www/html/install-rpms/archive

# Put nightly alpha builds in a subdirectory
ifeq ($(TAG),HEAD)
ARCHIVE := $(ARCHIVE)/planetlab-alpha
REPOS := /plc/data/var/www/html/install-rpms/planetlab-alpha
endif

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
	--resign RPMS/*/*.rpm
endif
ifneq ($(BUILDS),)
        # Remove old runs
	echo "cd $(ARCHIVE) && ls -t | sed -n $(BUILDS)~1p | xargs rm -rf" | ssh $(SERVERA) /bin/bash -s
	echo "cd $(ARCHIVE) && ls -t | sed -n $(BUILDS)~1p | xargs rm -rf" | ssh $(SERVERB) /bin/bash -s
endif
        # Create package manifest
	sh ./packages.sh -b "http://build.planet-lab.org/$(subst $(HOME)/,,$(shell pwd))/RPMS" RPMS > packages.xml
        # Update yum metadata
	yum-arch RPMS >/dev/null
	createrepo -g yumgroups.xml RPMS >/dev/null
        # Populate repository
	rsync \
	--exclude '*-debuginfo-*' \
	--recursive --links --perms --times --group --compress --rsh=ssh \
	RPMS/ $(SERVERA):$(ARCHIVE)/$(BASE)
	rsync \
	--exclude '*-debuginfo-*' \
	--recursive --links --perms --times --group --compress --rsh=ssh \
	RPMS/ $(SERVERB):$(ARCHIVE)/$(BASE)
ifeq ($(TAG),HEAD)
        # Update nightly alpha symlink if it does not exist or is broken, or it is Monday
	if ! ssh $(SERVERA) "[ -e $(REPOS) ] && exit 0 || exit 1" || [ "$(shell date +%A)" = "Monday" ] ; then \
	    ssh $(SERVERA) ln -nsf archive/$(BASE) $(REPOS) ; \
	fi
        # Update nightly alpha symlink if it does not exist or is broken, or it is Monday
	if ! ssh $(SERVERB) "[ -e $(REPOS) ] && exit 0 || exit 1" || [ "$(shell date +%A)" = "Monday" ] ; then \
	    ssh $(SERVERB) ln -nsf archive/$(BASE) $(REPOS) ; \
	fi

endif
endif

.PHONY: install
