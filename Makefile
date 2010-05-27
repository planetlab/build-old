#
# Thierry Parmentelat - INRIA Sophia Antipolis 
#
####################
# invocation:
#
# (*) make stage1=true
#     this extracts all specfiles and computes .mk from specfiles
#     you need to specify PLDISTRO here if relevant - see below
# (*) make help
#     for more info on how to invoke this stuff
#
#################### (fedora) distributions
#
# (*) as of nov. 2007, myplc-devel is deprecated
# (*) instead, we create a fresh vserver that holds required tools (see e.g. planetlab-devel.lst)
# (*) the build uses the current fedora version as a target for the produced images
# (*) so you simply need to create a fedora 8 build image for building fedora-8 images 
#     
#################### (planetlab) distributions
#
# (*) see README-pldistros.txt
# (*) then you need to run 
#     make stage1=true PLDISTRO=onelab
#
#################### 
# This build deals with 3 kinds of objects
# 
# (*) packages are named upon the RPM name; they are mostly lowercase
#     Add a package to ALL if you want it built as part of the default set.
# (*) modules are named after the subversion tree; as of this writing their names 
#     are mostly mixed case like MyPLC or VserverReference
#     (this is something we'll fix while moving to git)
# (*) rpms are named in the spec files. A package typically defines several rpms;
#     rpms are used for defining DEPEND-DEVEL-RPMS. See also package.rpmnames
# 
#################### packages
# basics: how to build a package - you need/may define the following variables
# 
# (*) package-MODULES
#     a package needs one or several modules to build. 
#     to this end, define 
# (*) package-SPEC
#     the package's specfile; this is relative to the FIRST module in package-MODULES
#
# Optional:
#
# (*) package-SPECVARS
#     space-separated list of spec variable definitions, where you can reference make variable that relate to 
#     packages defined BEFORE the current one (note: you should use = - as opposed to := - to define these)
#     e.g. mydriver-SPECVARS = foo=$(kernel-rpm-release) 
#     would let you use the %release from the kernel's package when rpmbuild'ing mydriver - see automatic below
# (*) package-DEPEND-PACKAGES
#     a set of *packages* that this package depends on
# (*) package-DEPEND-DEVEL-RPMS
#     a set of *rpms* that the build will rpm-install before building <package>
#     the build will attempt to uninstall those once the package is built, this is not fatal though
#     this is intended to denote local rpms, i.e. ones that are results of our own build
#     stock rpms should be mentioned in config.planetlab/devel.pkgs
# (*) package-DEPEND-FILES
#     a set of files that the package depends on - and that make needs to know about
#     if this contains RPMS/yumgroups.xml, then the toplevel RPMS's index 
#     is refreshed with createrepo prior to running rpmbuild
# (*) package-EXCLUDE-DEVEL-RPMS
#     a set of *rpms* that the build will rpm-uninstall before building <package>
#     this is intended to denote stock rpms, and the build will attempt to yum-install them
#     back after the package is rebuilt
# (*) package-RPMFLAGS: Miscellaneous RPM flags
# (*) package-RPMBUILD: If not rpmbuild - mostly used for sudo'ing rpmbuild
# (*) package-BUILD-FROM-SRPM: set this to any non-empty value, if your package is able to produce 
#     a source rpms by running 'make srpm'
# (*) package-RPMDATE: set this to any non-empty value to get the rpm package's release field hold the current date
#     this is useful for container packages, like e.g. bootstrapfs or vserver, that contains much more than the
#     correspondng module
#
#################### modules
# Required information about the various modules (set this in e.g. planetlab-tags.mk)
#
# (*) module-SVNPATH
#     for svn modules
#     the complete path where this module lies; 
#     you can specify the trunk or a given tag with this variable
# 
# (*) module-GITPATH
#     for git modules
#     which by analogy with svn revision scheme, is expected to be <url>@<tag>
#
#################### automatic variables
#
# the build defines some make variables that are extracted from spec files
# see for example
# (*)  $ make ulogd-pkginfo
#        to see the list f variables attached to a given package
# (*)  $ make kernel-devel-rpminfo
#        to see the list of variables attached to a given rpm
#
####################

# exported to spec files as plrelease
PLANETLAB_RELEASE = 5.0

#
# Default values
#
# minimal compat with macos, just so this does not complain 
HOSTARCH := $(shell uname -i 2> /dev/null || uname -m 2> /dev/null)
DISTRO := $(shell ./getdistro.sh)
RELEASE := $(shell ./getrelease.sh)
DISTRONAME := $(shell ./getdistroname.sh)
RPM-INSTALL-DEVEL := rpm --force -Uvh
# uninstall -- cannot force rpm -e
# need to ignore result, kernel-headers cannot be uninstalled as glibc depends on it
RPM-UNINSTALL-DEVEL := rpm -e
YUM-INSTALL-DEVEL := yum -y install

#################### Makefile
# Default target
all:
.PHONY:all

### default values
PLDISTRO := planetlab
RPMBUILD := rpmbuild

########## savedpldistro.mk holds PLDISTRO - it is generated at stage1 (see below)
ifeq "$(stage1)" ""
include savedpldistro.mk
endif

# when re-running the nightly build after failure, we need to gather the former values
# do this by running make stage1=skip +PLDISTRO
ifeq "$(stage1)" "skip"
include savedpldistro.mk
endif

#################### include onelab.mk
# describes the set of components
PLDISTROCONTENTS := $(PLDISTRO).mk
include $(PLDISTROCONTENTS)

#################### include <pldistro>-tags.mk
# describes where to fetch components
ifeq "$(PLDISTROTAGS)" ""
PLDISTROTAGS := $(PLDISTRO)-tags.mk
endif
include $(PLDISTROTAGS)

# this used to be set in the -tags.mk files, but that turned out to require
# error-prone duplicate changes 
# so now the nightly build script sets this to what it is currently using
# in case we run this manually, i.e. if neither build-SVNPATH nor build-GITPATH is set
ifeq "$(build-SVNPATH)$(build-GITPATH)" ""
build-GITPATH-local := $(shell git config remote.origin.url)
ifneq "$(build-GITPATH-local)" ""
build-GITPATH := $(build-GITPATH-local)
else
build-SVNPATH := $(lastword $(shell svn info 2> /dev/null | grep URL:))
endif
endif

#################### pldistros that are defined remotely
# fetching with svn
define remote_pldistro_fetch_svn
$(1).config.SVNPATH := $(shell grep -v "^#" config.$(1).svnpath)
config.$(1): config.$(1).svnpath
	@echo "Fetching (svn) details for remote pldistro $(1)"
	svn export $$($(1).config.SVNPATH) config.$(1)
endef

FOO=@
# fetching with git
define remote_pldistro_fetch_git
$(1).config.GITPATH := $(shell grep -v "^#" config.$(1).gitpath)
$(1).config.gitrepo := $$(firstword $$(subst @, ,$$($(1).config.GITPATH)))
$(1).config.gittag := $$(word 2,$$(subst @, ,$$($(1).config.GITPATH)))
$(1).config.gittag := $$(if $$($(1).config.gittag),$$($(1).config.gittag),master)
config.$(1): GITPATH=$(shell grep -v "^#" config.$(1).gitpath)
config.$(1): config.$(1).gitpath
	@echo "Fetching (git) details for remote pldistro $(1)"
	mkdir -p config.$(1)
	git $(GITTAG) archive --remote=$$($(1).config.gitrepo) $$($(1).config.gittag) | tar -C config.$(1) -xf -
endef


# put it together
define remote_pldistro
$(1).mk: config.$(1)/$(1).mk
	@echo 'creating $(1) from config.$(1)'
	cp config.$(1)/$(1).mk $(1).mk

$(2).mk: config.$(1)/$(2).mk
	@echo 'creating $(2) tags from config.$(1)'
	cp config.$(1)/$(2).mk $(2).mk

config.$(1)/$(1).mk: config.$(1)
config.$(1)/$(2).mk: config.$(1)

DISTCLEANS += $(1).mk $(2).mk config.$(1)
$(eval $(call remote_pldistro_fetch_$(3),$(1)))
endef

$(eval $(call remote_pldistro,wextoolbox,wextoolbox-tags,git))

########## stage1 and stage1iter
# extract specs and compute .mk files by running 
# make stage1=true
# entering stage1, we compute all the spec files
# then we use stage1iter to compute the .mk iteratively, 
# ensuring that the n-1 first makefiles are loaded when creating the n-th one
# when stage1iter is set, it is supposed to be an index (starting at 1) in $(ALL)

ALLMKS := $(foreach package, $(ALL), MAKE/$(package).mk)

### stage1iter : need some arithmetic, see
# http://www.cmcrossroads.com/articles/ask-mr.-make/learning-gnu-make-functions-with-arithmetic.html
ifneq "$(stage1iter)" ""
# the first n packages
packages := $(wordlist 1,$(words $(stage1iter)),$(ALL))
# the n-th package
package := $(word $(words $(packages)),$(packages))
# the n-1 first packages
stage1iter_1 := $(wordlist 2,$(words $(stage1iter)),$(stage1iter))
previous := $(wordlist 1,$(words $(stage1iter_1)),$(ALL))
previousmks := $(foreach package,$(previous),MAKE/$(package).mk)
include $(previousmks)
all: verbose
verbose:
	@echo "========== stage1iter : $(package)"
#	@echo "stage1iter : included .mk files : $(previousmks)"
all: $($(package).specpath)
all: MAKE/$(package).mk
else
### stage1
ifneq "$(stage1)" ""
all : verbose
verbose :
	@echo "========== stage1"
all : spec2make
all : .rpmmacros
# specs and makes are done sequentially by stage1iter
all : stage1iter
stage1iter:
	arg=""; for n in $(ALL) ; do arg="$$arg x"; $(MAKE) --no-print-directory stage1iter="$$arg"; done
### regular make
else
### once .mks are OK, you can run make normally
include $(ALLMKS)
#all : tarballs
#all : sources
#all : modules
#all : rpms
#all : srpms
# mention $(ALL) here rather than rpms 
# this is because the inter-package dependencies are expressed like
# util-vserver: util-python
all: rpms
all: repo
endif
endif

### yumgroups.xml : compute from all known .pkgs files
RPMS/yumgroups.xml: 
	mkdir -p RPMS
	./yumgroups.sh $(PLDISTRO) > $@

createrepo = createrepo --quiet -g yumgroups.xml RPMS/ 

repo: RPMS/yumgroups.xml
	$(createrepo)

.PHONY: repo

####################
# notes: 
# * we always use the first module's location (SVNPATH/GITPATH) to extract the spec file
# * no matter what SCM is used, SPEC should hold a relative path from the module's root
#
define stage1_package_vars
$(1).module := $(firstword $($(1)-MODULES))
$(1).specpath := SPECS/$(notdir $($(1)-SPEC))
$(1).moduledir := MODULES/$$($(1).module)
$(1).codespec := MODULES/$$($(1).module)/$($(1)-SPEC)
endef

$(foreach package, $(ALL), $(eval $(call stage1_package_vars,$(package))))

# compute all modules
ALL.modules := build tests
$(foreach package,$(ALL), $(eval ALL.modules+=$($(package)-MODULES)))
ALL.modules:=$(sort $(ALL.modules))

# extract revision from -SVNPATH or tag from -GITPATH
define stage1_module_vars
ifneq "$($(1)-SVNPATH)" ""
$(1)-SVNPATH := $(strip $($(1)-SVNPATH))
else
$(1)-GITPATH := $(strip $($(1)-GITPATH))
$(1).gitrepo := $(firstword $(subst @, ,$($(1)-GITPATH)))
$(1).gittag := $(word 2,$(subst @, ,$($(1)-GITPATH)))
$(1).gittag := $(if $($(1).gittag),$($(1).gittag),master)
endif
endef

$(foreach module,$(ALL.modules), $(eval $(call stage1_module_vars,$(module))))

#
# for each package, compute whether we need to set date 
# the heuristic is that we mention the date as part of the rpm release flag if
# (*) the package has requested it by setting package-RPMDATE (container packages should do that)
# (*) or SVNPATH contains 'trunk' or 'branches' 
# (*) or GITPATH has no '@' (trunk) 
# (*) or GITPATH contains a '@', and the gittag part has no '-' (this is to tell a tag from a branch..)
# 
define package_hasdate
$(1).has-date = $(if $($(1)-RPMDATE),yes, \
                  $(if $($($(1).module)-SVNPATH), \
		     $(if $(findstring /trunk,$($($(1).module)-SVNPATH)),yes, \
			$(if $(findstring /branches,$($($(1).module)-SVNPATH)),yes,)), \
		     $(if $(not $($($(1).module).gittag)), yes,\
			$(if $(findstring -,$($($(1).module).gittag)),,yes))))
endef

$(foreach package, $(ALL), $(eval $(call package_hasdate,$(package))))

### the common header for generated specfiles
# useful when trying new specfiles manually
header.spec:
	(echo -n "# Generated by planetlab build from $($(1)-SPEC) on " ; date) > $@
	echo "%define distro $(DISTRO)" >> $@
	echo "%define distrorelease $(RELEASE)" >> $@
	echo "%define distroname $(DISTRONAME)" >> $@
	echo "%define pldistro $(PLDISTRO)" >> $@
	echo "%define plrelease $(PLANETLAB_RELEASE)" >> $@
	echo "# use MD5 and gzip for binary and source files" >> $@
	echo "%global _binary_filedigest_algorithm 1" >> $@
	echo "%global _source_filedigest_algorithm 1" >> $@
	echo "%global _source_payload       w9.gzdio" >> $@
	echo "%global _binary_payload       w9.gzdio" >> $@

### make up spec file - extract module first
define target_spec
$($(1).specpath): header.spec $($(1).codespec)
	mkdir -p SPECS
	cat header.spec > $($(1).specpath)
	$(if $($(1).has-date),echo "%define date $(shell date +%Y.%m.%d)" >> $($(1).specpath),)
	$(if $($(1)-SPECVARS), \
	  $(foreach line,$($(1)-SPECVARS), \
	    echo "%define" $(word 1,$(subst =, ,$(line))) "$(word 2,$(subst =, ,$(line)))" >> $($(1).specpath) ;))
	echo "# included from $($(1)-SPEC)" >> $($(1).specpath)
	cat $($(1).codespec) >> $($(1).specpath)

$($(1).codespec): $($(1).moduledir)

endef

$(foreach package,$(ALL),$(eval $(call target_spec,$(package))))

### module extraction
define target_extract_module
MODULES/$(1):
	@(echo -n "XXXXXXXXXXXXXXX -- BEG MODULE $(1) : $@ " ; date)
	mkdir -p MODULES
	cd MODULES && \
	$(if $($(1)-SVNPATH),\
	  svn export $($(1)-SVNPATH) $(1),\
	  mkdir $(1) ; (git archive --remote=$($(1).gitrepo) $($(1).gittag) | tar -C $(1) -xf - ) \
	   || { rm -rf $(1); false; } )
	@(echo -n "XXXXXXXXXXXXXXX -- END MODULE $(1) : $@ " ; date)

$(1)-module: MODULES/$(1)
.PHONY: $(1)-module
endef

$(foreach module,$(ALL.modules),$(eval $(call target_extract_module,$(module))))

### the tests area
# use this makefile to extract tests rather than extracting manually in vbuild-nightly
tests-clean:
	rm -rf MODULES/tests
.PHONY: tests-clean

###
# Base rpmbuild in the current directory
# issues on fedora 8 : see the following posts
# http://forums.fedoraforum.org/showthread.php?t=39625 - and more specifically post#6
# https://www.redhat.com/archives/fedora-devel-list/2007-November/msg00171.html
REALROOT=/build
FAKEROOT=/longbuildroot
PWD=$(shell /bin/pwd)
ifeq "$(PWD)" "$(REALROOT)"
export HOME := $(FAKEROOT)
else
export HOME := $(PWD)
endif
.rpmmacros:
ifeq "$(shell pwd)" "/build"
	rm -f $(FAKEROOT) ; ln -s $(REALROOT) $(FAKEROOT)
endif
	rm -f $@ 
	echo "%_topdir $(HOME)" >> $@
	echo "%_tmppath $(HOME)/tmp" >> $@
	echo "%__spec_install_pre %{___build_pre}" >> $@
	./getrpmmacros.sh >> $@

### this utility allows to extract various info from a spec file
### and to define them in makefiles
spec2make: spec2make.c
	$(CC) -g -Wall $< -o $@ -lrpm -lrpmbuild

### run spec2make on the spec file and include the result
# usage: spec2make package
define target_mk
MAKE/$(1).mk: $($(1).specpath) spec2make .rpmmacros
	mkdir -p MAKE
	./spec2make $($(1)-RPMFLAGS) $($(1).specpath) $(1) > MAKE/$(1).mk || { rm MAKE/$(1).mk; exit 1; }
endef

$(foreach package,$(ALL),$(eval $(call target_mk,$(package))))

# stores PLDISTRO in a file
# this is done at stage1. later run wont get confused
SAVED_VARS=PLDISTRO PLDISTROTAGS build-SVNPATH PERSONALITY MAILTO BASE WEBPATH TESTBUILDURL WEBROOT
savedpldistro.mk:
	@echo "# do not edit" > $@
	@$(foreach var,$(SAVED_VARS),echo "$(var):=$($(var))" >> $@ ;)
	@echo "# do not edit" > aliases
	@echo -n "alias m=\"make " >> aliases
	@$(foreach var,$(SAVED_VARS),echo -n " $(var)=$($(var))" >> aliases ;)
	@echo "\"" >> aliases
	@echo "alias m1=\"m stage1=true\"" >> aliases

savedpldistro: savedpldistro.mk
.PHONY: savedpldistro

# always refresh this
all: savedpldistro

#################### regular make

define stage2_variables
### devel dependencies
$(1).rpmbuild = $(if $($(1)-RPMBUILD),$($(1)-RPMBUILD),$(RPMBUILD)) $($(1)-RPMFLAGS)
$(1).all-devel-rpm-paths := $(foreach rpm,$($(1)-DEPEND-DEVEL-RPMS),$($(rpm).rpm-path))
$(1).depend-devel-packages := $(sort $(foreach rpm,$($(1)-DEPEND-DEVEL-RPMS),$($(rpm).package)))
ALL-DEVEL-RPMS += $($(1)-DEPEND-DEVEL-RPMS)
endef

$(foreach package,$(ALL),$(eval $(call stage2_variables,$(package))))
ALL-DEVEL-RPMS := $(sort $(ALL-DEVEL-RPMS))


### pack sources into tarballs
ALLTARBALLS:= $(foreach package, $(ALL), $($(package).tarballs))
tarballs: $(ALLTARBALLS)
	@echo $(words $(ALLTARBALLS)) source tarballs OK
.PHONY: tarballs

SOURCES/%.tar.bz2: SOURCES/%
	tar chpjf $@ -C SOURCES $*

SOURCES/%.tar.gz: SOURCES/%
	tar chpzf $@ -C SOURCES $*

SOURCES/%.tgz: SOURCES/%
	tar chpzf $@ -C SOURCES $*

##
URLS/%: url=$(subst @colon@,:,$(subst @slash@,/,$(notdir $@)))
URLS/%: basename=$(notdir $(url))
URLS/%: 
	echo curl $(url) -o SOURCES/$(basename)
	touch $@

### the directory SOURCES/<package>-<version> is made 
# with a (set of) copy -rl from MODULES/<module>
# the former is $(package.source) 
ALLSOURCES:=$(foreach package, $(ALL), $($(package).source))
# so that make does not use the rule below directly for creating the tarball files
.SECONDARY: $(ALLSOURCES)

sources: $(ALLSOURCES)
	@echo $(words $(ALLSOURCES)) versioned source trees OK
.PHONY: sources

# argument is a package
# do things differently if multiple modules are mentioned (sigh..)
define target_copy_link_modules_sources
$($(1).source): $(foreach module,$($(1)-MODULES),MODULES/$(module))
	$(if $(word 2,$($(1)-MODULES)),\
	 mkdir -p $($(1).source) && $(foreach module,$($(1)-MODULES), cp -rl MODULES/$(module) $($(1).source)/$(module);) ,\
	 mkdir -p SOURCES && cp -rl MODULES/$($(1)-MODULES) $($(1).source))
endef

$(foreach package,$(ALL),$(eval $(call target_copy_link_modules_sources,$(package))))

### code extraction
ALLMODULES:=$(foreach module, $(ALL.modules), MODULES/$(module))
.SECONDARY: $(ALLMODULES)
modules: $(ALLMODULES)
	@echo $(words $(ALLMODULES)) modules OK "(fetched from scm)"
.PHONY: modules

### source rpms
ALLSRPMS:=$(foreach package,$(ALL),$($(package).srpm))
srpms: $(ALLSRPMS)
	@echo $(words $(ALLSRPMS)) source rpms OK
.PHONY: srpms

### these macro handles the DEPEND-DEVEL-RPMS and EXCLUDE-DEVEL-RPMS tags for a hiven package
# before building : rpm-install DEPEND-DEVEL-RPMS and rpm-uninstall EXCLUDE
define handle_devel_rpms_pre 
	$(if $($(1).all-devel-rpm-paths), echo "Installing for $(1)-DEPEND-DEVEL-RPMS" ; $(RPM-INSTALL-DEVEL) $($(1).all-devel-rpm-paths)) 
	$(if $($(1)-EXCLUDE-DEVEL-RPMS), echo "Uninstalling for $(1)-EXCLUDE-DEVEL-RPMS" ; $(RPM-UNINSTALL-DEVEL) $($(1)-EXCLUDE-DEVEL-RPMS))
endef

define handle_devel_rpms_post
	-$(if $($(1)-DEPEND-DEVEL-RPMS), echo "Unstalling for $(1)-DEPEND-DEVEL-RPMS" ; $(RPM-UNINSTALL-DEVEL) $($(1)-DEPEND-DEVEL-RPMS))
	$(if $($(1)-EXCLUDE-DEVEL-RPMS), "Reinstalling for $(1)-EXCLUDE-DEVEL-RPMS" ; $(YUM-INSTALL-DEVEL) $($(1)-EXCLUDE-DEVEL-RPMS) )
endef

# usage: target_source_rpm package
define target_source_rpm 
ifeq "$($(1)-BUILD-FROM-SRPM)" ""
$($(1).srpm): $($(1).specpath) .rpmmacros $($(1).tarballs) 
	mkdir -p BUILD SRPMS tmp
	@(echo -n "XXXXXXXXXXXXXXX -- BEG SRPM $(1) (using SOURCES) " ; date)
	$(call handle_devel_rpms_pre,$(1))
	$($(1).rpmbuild) -bs $($(1).specpath)
	$(call handle_devel_rpms_post,$(1))
	@(echo -n "XXXXXXXXXXXXXXX -- END SRPM $(1) " ; date)
else
$($(1).srpm): $($(1).specpath) .rpmmacros $($(1).source)
	mkdir -p BUILD SRPMS tmp
	@(echo -n "XXXXXXXXXXXXXXX -- BEG SRPM $(1) (using make srpm) " ; date)
	$(call handle_devel_rpms_pre,$(1))
	make -C $($(1).source) srpm SPECFILE=$(HOME)/$($(1).specpath) EXPECTED_SRPM=$(notdir $($(1).srpm)) && \
           rm -f SRPMS/$(notdir $($(1).srpm)) && \
           ln $($(1).source)/$(notdir $($(1).srpm)) SRPMS/$(notdir $($(1).srpm)) 
	$(call handle_devel_rpms_post,$(1))
	@(echo -n "XXXXXXXXXXXXXXX -- END SRPM $(1) " ; date)
endif
endef

$(foreach package,$(ALL),$(eval $(call target_source_rpm,$(package))))

### binary rpms are made from source rpm
ALLRPMS:=$(foreach package,$(ALL),$($(package).rpms))
# same as above, mention $(ALL) and not $(ALLRPMS)
rpms: $(ALLRPMS)
	@echo $(words $(ALLRPMS)) binary rpms OK
.PHONY: rpms

# use tmp dirs when building binary rpm so make remains idempotent 
# otherwise SOURCES/ or SPEC gets touched again - which leads to rebuilding
RPM-USE-TMP-DIRS = --define "_sourcedir $(HOME)/tmp" --define "_specdir $(HOME)/tmp"
RPM-USE-COMPILE-DIRS = --define "_sourcedir $(HOME)/COMPILE" --define "_specdir $(HOME)/COMPILE"

# usage: build_binary_rpm package
# xxx hacky - invoke createrepo if DEPEND-FILES mentions RPMS/yumgroups.xml
define target_binary_rpm 
$($(1).rpms): $($(1).srpm)
	mkdir -p RPMS tmp
	@(echo -n "XXXXXXXXXXXXXXX -- BEG RPM $(1) " ; date)
	$(if $(findstring RPMS/yumgroups.xml,$($(1)-DEPEND-FILES)), $(createrepo) , )
	$(call handle_devel_rpms_pre,$(1))
	$($(1).rpmbuild) --rebuild $(RPM-USE-TMP-DIRS) $($(1).srpm)
	$(call handle_devel_rpms_post,$(1))
	@(echo -n "XXXXXXXXXXXXXXX -- END RPM $(1) " ; date)
# for manual use only - in case we need to investigate the results of an rpmbuild
$(1)-compile: $($(1).srpm)
	mkdir -p COMPILE tmp
	@(echo -n "XXXXXXXXXXXXXXX -- BEG compile $(1) " ; date)
	$(if $(findstring RPMS/yumgroups.xml,$($(1)-DEPEND-FILES)), $(createrepo) , )
	$(call handle_devel_rpms_pre,$(1))
	$($(1).rpmbuild) --recompile $(RPM-USE-TMP-DIRS) $($(1).srpm)
	$(call handle_devel_rpms_post,$(1))
	@(echo -n "XXXXXXXXXXXXXXX -- END compile $(1) " ; date)
.PHONY: $(1)-compile
endef

$(foreach package,$(ALL),$(eval $(call target_binary_rpm,$(package))))
### shorthand target
# e.g. make proper -> does propers rpms
# usage shorthand_target package
define target_shorthand 
$(1): $($(1).rpms)
.PHONY: $(1)
$(1)-spec: $($(1)-SPEC)
.PHONY: $(1)-spec
$(1)-mk: $($(1)-MK)
.PHONY: $(1)-mk
$(1)-tarball: $($(1).tarballs)
.PHONY: $(1)-tarball
.PHONY: $(1)-source
$(1)-source: $($(1).source)
$(1)-rpms: $($(1).rpms)
.PHONY: $(1)-rpms
$(1)-srpm: $($(1).srpm)
.PHONY: $(1)-srpm
endef

$(foreach package,$(ALL),$(eval $(call target_shorthand,$(package))))

### file dependencies
define package_depends_on_file
$(1):$(2)
$($(1).srpm):$(2)
endef

define target_dependfiles
$(foreach file,$($(1)-DEPEND-FILES),$(eval $(call package_depends_on_file,$(1),$(file))))
endef

$(foreach package,$(ALL),$(eval $(call target_dependfiles,$(package))))

### package dependencies
define package_depends_on_package
$(1):$(2)
$(1):$($(2).rpms)
$($(1).srpm):$($(2).rpms)
endef

define target_depends
$(foreach package,$($(1)-DEPEND-PACKAGES) $($(1).depend-devel-packages),$(eval $(call package_depends_on_package,$(1),$(package))))
endef

$(foreach package,$(ALL),$(eval $(call target_depends,$(package))))

### clean target
# usage: target_clean package
define target_clean
$(1)-clean-modules:
	$(foreach module,$($(1)-MODULES),rm -rf MODULES/$(module);)
.PHONY: $(1)-clean-modules
CLEANS += $(1)-clean-modules
$(1)-clean-source:
	rm -rf $($(1).source)
.PHONY: $(1)-clean-source
CLEANS += $(1)-clean-source
$(1)-clean-tarball:
	rm -rf $($(1).tarballs)
.PHONY: $(1)-clean-tarball
CLEANS += $(1)-clean-tarball
$(1)-clean-build:
	rm -rf BUILD/$(notdir $($(1).source))
CLEANS += $(1)-clean-build
$(1)-clean-rpms:
	rm -rf $($(1).rpms)
.PHONY: $(1)-clean-rpms
CLEANS += $(1)-clean-rpms
$(1)-clean-srpm:
	rm -rf $($(1).srpm)
.PHONY: $(1)-clean-srpm
CLEANS += $(1)-clean-srpm
$(1)-codeclean: $(1)-clean-source $(1)-clean-tarball $(1)-clean-build $(1)-clean-rpms $(1)-clean-srpm
$(1)-clean: $(1)-clean-modules $(1)-codeclean
.PHONY: $(1)-codeclean $(1)-clean 
$(1)-clean-spec:
	rm -rf $($(1).specpath)
.PHONY: $(1)-clean-spec
$(1)-clean-make:
	rm -rf MAKE/$(1).mk
.PHONY: $(1)-clean-make
$(1)-distclean: $(1)-distclean1 $(1)-distclean2
$(1)-distclean1: $(1)-clean-spec $(1)-clean-make
$(1)-distclean2: $(1)-clean
.PHONY: $(1)-distclean $(1)-distclean1 $(1)-distclean2
endef

$(foreach package,$(ALL),$(eval $(call target_clean,$(package))))

### clean precisely
clean:
	$(MAKE) $(CLEANS)
.PHONY: clean

clean-help:
	@echo Available clean targets
	@echo $(CLEANS)

### brute force clean
distclean1:
	rm -rf savedpldistro.mk .rpmmacros spec2make header.spec SPECS MAKE $(DISTCLEANS)
distclean2:
	rm -rf MODULES SOURCES BUILD BUILDROOT RPMS SRPMS tmp
distclean: distclean1 distclean2
.PHONY: distclean1 distclean2 distclean

develclean:
	-$(RPM-UNINSTALL-DEVEL) $(ALL-DEVEL-RPMS)

####################
# gather build information for the 'About' page
# when run from crontab, INIT_CWD not properly set (says /root ..)
# so, the nightly build passes BASE here
# also store BASE in .base for any post-processing purposes
myplc-release:
	@echo 'Creating myplc-release'
	rm -f $@
	echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx build info" >> $@
	$(MAKE) --no-print-directory version-build >> $@
	echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx svn info" >> $@
	$(MAKE) --no-print-directory version-tags >> $@
	echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx rpm info" >> $@
	$(MAKE) --no-print-directory version-rpms >> $@
	@echo $(BASE) > .base

version-build:
	@echo -n 'Build build-date: ' ; date '+%Y.%m.%d'
	@echo -n 'Build build-time: ' ; date '+%H:%M-%Z'
	@echo -n 'Build build-hostname: ' ; hostname
	@echo    "Build build-base: $(BASE)"
	@echo    "Build planetlab-distro: $(PLDISTRO)"
	@echo    "Build planetlab-tags: $(PLDISTROTAGS)"
	@echo    "Build target-arch: $(HOSTARCH)"
	@echo    "Build target-distro: $(DISTRO)"
	@echo    "Build target-distroname: $(DISTRONAME)"
	@echo    "Build target-release: $(RELEASE)"	
	@echo    "Build target-personality: $(PERSONALITY)"	

#################### 
# for a given module
VFORMAT="%30s := %s\n"
define print_tag_target
$(1)-version-tag:
	@$(if $($(1)-SVNPATH),\
	   printf $(VFORMAT) $(1)-SVNPATH "$($(1)-SVNPATH)",\
	   printf $(VFORMAT) $(1)-GITPATH "$($(1)-GITPATH)" )
endef

$(foreach module,$(ALL.modules), $(eval $(call print_tag_target,$(module))))

version-tags: $(foreach module, $(ALL.modules), $(module)-version-tag)

RFORMAT="%20s :: version=%s release=%s\n"
define rpm_version_target
$(1)-version-rpm:
	@printf $(RFORMAT) $($(1).rpm-name) $($(1).rpm-version) $($(1).rpm-release)
version-rpms: $(1)-version-rpm
endef

$(foreach package,$(sort $(ALL)), $(eval $(call rpm_version_target,$(package))))

versions: myplc-release version-build version-tags version-rpms
.PHONY: versions version-build version-rpms version-tags

#################### package info
PKGKEYS := tarballs source srpm rpms rpmnames rpm-release rpm-name rpm-version rpm-subversion
%-pkginfo: package=$(subst -pkginfo,,$@)
%-pkginfo: 
	@$(foreach key,$(PKGKEYS),echo "$(package).$(key)=$($(package).$(key))";)
## rpm info
RPMKEYS := rpm-path package
%-rpminfo: rpm=$(subst -rpminfo,,$@)
%-rpminfo: 
	@$(foreach key,$(RPMKEYS),echo "$(rpm).$(key)=$($(rpm).$(key))";)

#################### various lists - designed to run with stage1=true
info-packages:
	@$(foreach package,$(ALL), echo package=$(package) ref_module=$($(package).module) modules=$($(package)-MODULES) rpmnames=$($(package).rpmnames); )

info-modules:
	@$(foreach module,$(ALL.modules), echo module=$(module) \
	   $(if $($(module)-SVNPATH),svnpath=$($(module)-SVNPATH),gitpath=$($(module)-GITPATH)) ; )

info-branches:
	@$(foreach module,$(ALL.modules), \
	  $(if $($(module)-BRANCH),echo module=$(module) branch=$($(module)-BRANCH);))

module-tools:
	@$(foreach module,$(ALL.modules), \
 	 $(if $($(module)-GITPATH), \
	  $(if $($(module)-BRANCH), \
	     echo git:$(module):$($(module)-BRANCH); , \
	     echo git:$(module); ), \
	  $(if $($(module)-BRANCH), \
	     echo $(module):$($(module)-BRANCH); , \
	     echo $(module); )))

info: info-packages info-modules info-branches 

.PHONY: info info-packages info-modules info-branches module-tools

####################
help:
	@echo "********** Run make in two stages:"
	@echo ""
	@echo "make stage1=true PLDISTRO=onelab"
	@echo " -> extracts all spec files in SPECS/ and mk files in MAKE/"
	@echo "    as well as save PLDISTRO for subsequent runs"
	@echo ""
	@echo "********** Then you can use the following targets"
	@echo 'make'
	@echo "  rebuilds everything"
	@echo 'make util-vserver'
	@echo "  makes the RPMS related to util-vserver"
	@echo "  equivalent to 'make util-vserver-rpms'"
	@echo ""
	@echo "********** Or, vertically - step-by-step for a given package"
	@echo 'make util-vserver-source'
	@echo "  creates source link in SOURCES/util-vserver-<version>"
	@echo 'make util-vserver-tarball'
	@echo "  creates source tarball in SOURCES/util-vserver-<version>.<tarextension>"
	@echo 'make util-vserver-srpm'
	@echo "  build source rpm in SRPMS/"
	@echo 'make util-vserver-rpms'
	@echo "  build rpm(s) in RPMS/"
	@echo ""
	@echo "********** Or, horizontally, reach a step for all known packages"
	@echo 'make sources'
	@echo 'make tarballs'
	@echo 'make srpms'
	@echo 'make rpms'
	@echo ""
	@echo "********** Manual targets"
	@echo "make package-compile"
	@echo "  The regular process uses rpmbuild --rebuild, that performs"
	@echo "  a compilation directory cleanup upon completion. If you need to investigate"
	@echo "  the intermediate compilation directory, use the -compile targets"
	@echo "********** Cleaning examples"
	@echo "make clean"
	@echo "  removes the files made by make"
	@echo "make distclean"
	@echo "  brute-force cleaning, removes entire directories - requires a new stage1"
	@echo "make develclean"
	@echo "  rpm-uninstalls all devel packages installed during build"
	@echo ""
	@echo "make iptables-distclean"
	@echo "  deep clean for a given package"
	@echo "make iptables-codeclean"
	@echo "  run this if you've made a local/manual change in the MODULES area for iptables"
	@echo ""
	@echo "make util-vserver-clean"
	@echo "  removes codebase, source, tarball, build, rpm and srpm for util-vserver"
	@echo "make util-vserver-clean-modules"
	@echo "  and so on for source, tarball, build, rpm and srpm"
	@echo ""
	@echo "********** Info examples"
	@echo "make ++ALL"
	@echo "  Displays the value of a given variable (here ALL)"
	@echo "  with only a single plus sign only the value is displayed"
	@echo "make info"
	@echo "  is equivalent to make packages modules branches"
	@echo "  provides various info on these objects"
	@echo "make ulogd-pkginfo"
	@echo "  Displays know attributes of a package"
	@echo "make kernel-devel-rpminfo"
	@echo "  Displays know attributes of an rpm"
	@echo "make stage1=true PLDISTROTAGS=planetlab-tags-4.2.mk packages modules branches module-tools"
	@echo "  Lists mentioned items - module-tools is used in modules.update"
	@echo ""
	@echo "********** Known pakages are"
	@echo "$(ALL)"

#################### convenience, for debugging only
# make +foo : prints the value of $(foo)
# make ++foo : idem but verbose, i.e. foo=$(foo)
++%: varname=$(subst +,,$@)
++%:
	@echo "$(varname)=$($(varname))"
+%: varname=$(subst +,,$@)
+%:
	@echo "$($(varname))"
