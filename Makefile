#
# Thierry Parmentelat - INRIA Sophia Antipolis 
#
### $Id$
# 
####################
# invokation:
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
# (*) the default distribution is called 'planetlab'
# (*) you may define an alternative distribution, e.g. onelab
# in this case you need to
# (*) create onelab.mk that defines your *packages* (see below)
# (*) create onelab-tags.mk that defines where to fetch your *modules*
# (*) create your main yumgroups.xml as groups/<distro>.xml
# (*) there are also various places where a set of modules are defined.
#     check for .lst files in the various modules that build root images
#     and mimick what's done for planetlab 
# (*) then you need to run 
#     make stage1=true PLDISTRO=onelab
#
#################### 
# This build deals with 2 kinds of objects
# 
# (*) packages are named upon the RPM name; they are moslty lowercase
#     Add a package to ALL if you want it built as part of the default set.
# (*) modules are named after the subversion tree; as of this writing their names 
#     are mostly mixedcase like MyPLC or Vserverreference
# 
#################### packages
# basics: how to build a package - you need/may define the following variables
# 
# (*) package-MODULES
#     a package needs one or several modules to build. 
#     to this end, define 
# (*) package-SPEC
#     the package's specfile; this is relative to the FIRST module in package-MODULES
#     see 'codebase' below
#
# Optional:
#
# (*) package-SPECVARS
#     space-separated list of spec variable definitions, where you can reference make variable that relate to 
#     packages defined BEFORE the current one (note: you should use = - as opposed to := - to define these)
#     e.g. mydriver-SPECVARS = foo=$(kernel-rpm-release) 
#     would let you use the %release from the kernel's package when rpmbuild'ing mydriver - see automatic below
# (*) package-DEPENDS
#     a set of *packages* that this package depends on
# (*) package-DEPENDDEVELS
#     a set of *packages* that the build will rpm-install the -devel variant before building <package>
# (*) package-DEPENDFILES
#     a set of files that the package depends on - and that make needs to know about
#     if this contains RPMS/yumgroups.xml, then the toplevel RPMS's index 
#     is refreshed with createrepo prior to running rpmbuild
# (*) package-RPMFLAGS: Miscellaneous RPM flags
# (*) package-RPMBUILD: If not rpmbuild - mostly used for sudo'ing rpmbuild
#
#################### modules
# Required information about the various modules (set this in e.g. planetlab-tags.mk)
#
# (*) module-SVNPATH
#     the complete path where this module lies; 
#     you can specify the trunk or a given tag with this variable
# 
# OR if the module is managed under cvs (will be obsoleted)
# 
# (*) module-CVSROOT
# (*) module-TAG
#
#################### automatic variables
#
# the build defines the following make variables - these are extracted from spec files
# (*) package-TARBALLS : from the Source<n>: declaration
#     example: kernel-i386-TARBALLS = SOURCES/linux-2.6.20.tar.bz2
# (*) package-SOURCE : 
#     example: kernel-i386-SOURCE = SOURCES/linux-2.6.20
# (*) package-SRPM
#     example: kernel-i386-SRPM = SRPMS/kernel-2.6.20-1.2949.fc6.vs2.2.0.1.0.planetlab.src.rpm
# (*) package-RPMS
#     example: kernel-i386-RPMS = \
#	RPMS/i686/kernel-2.6.20-1.2949.fc6.vs2.2.0.1.0.planetlab.i686.rpm \
#	RPMS/i686/kernel-devel-2.6.20-1.2949.fc6.vs2.2.0.1.0.planetlab.i686.rpm \
#	RPMS/i686/kernel-vserver-2.6.20-1.2949.fc6.vs2.2.0.1.0.planetlab.i686.rpm \
#	RPMS/i686/kernel-debuginfo-2.6.20-1.2949.fc6.vs2.2.0.1.0.planetlab.i686.rpm
# (*) package-rpm-name
#     example: kernel-i386-rpm-name = kernel
# (*) package-rpm-release
#     example: kernel-i386-rpm-release = 1.2949.fc6.vs2.2.0.1.0.planetlab
# (*) package-version
#     example: kernel-i386-rpm-version = 2.6.20
# (*) package-subversion
#     example: myplc-rpm-subversion = 15
####################

#
# Default values
#
HOSTARCH := $(shell uname -i)
DISTRO := $(shell ./getdistro.sh)
RELEASE := $(shell ./getrelease.sh)

#################### Makefile
# Default target
all:
.PHONY:all

### default values
PLDISTRO := planetlab
RPMBUILD := rpmbuild
export CVS_RSH := ssh

########## pldistro.mk holds PLDISTRO - it is generated at stage1 (see below)
ifeq "$(stage1)" ""
include pldistro.mk
endif

#################### include onelab.mk
# describes the set of components
PLDISTROCONTENTS := $(PLDISTRO).mk
include $(PLDISTROCONTENTS)

#################### include <pldistro>-tags.mk
# describes where to fetch components, and the related tags if using cvs
PLDISTROTAGS := $(PLDISTRO)-tags.mk
include $(PLDISTROTAGS)

########## stage1 and stage2
# extract specs and compute .mk files by running 
# make stage1=true
# entering stage1, we compute all the spec files
# then we use stage2 to compute the .mk iteratively, 
# ensuring that the n-1 first makefiles are loaded when creating the n-th one
# when stage2 is set, it is supposed to be an index (starting at 1) in $(ALL)

ALLMKS := $(foreach package, $(ALL), MAKE/$(package).mk)

### stage2 : need some arithmetic, see
# http://www.cmcrossroads.com/articles/ask-mr.-make/learning-gnu-make-functions-with-arithmetic.html
ifneq "$(stage2)" ""
# the first n packages
packages := $(wordlist 1,$(words $(stage2)),$(ALL))
# the n-th package
package := $(word $(words $(packages)),$(packages))
# the n-1 first packages
stage2_1 := $(wordlist 2,$(words $(stage2)),$(stage2))
previous := $(wordlist 1,$(words $(stage2_1)),$(ALL))
previousmks := $(foreach package,$(previous),MAKE/$(package).mk)
include $(previousmks)
all: verbose
verbose:
	@echo "========== stage2 : $(package)"
#	@echo "stage2 : included .mk files : $(previousmks)"
all: $($(package)_specpath)
all: MAKE/$(package).mk
else
### stage1
ifneq "$(stage1)" ""
all : verbose
verbose :
	@echo "========== stage1"
all : spec2make
all : .rpmmacros
# specs and makes are done sequentially by stage2
all : stage2
stage2:
	arg=""; for n in $(ALL) ; do arg="$$arg x"; $(MAKE) --no-print-directory stage2="$$arg"; done
### regular make
else
### once .mks are OK, you can run make normally
include $(ALLMKS)
#all : tarballs
#all : sources
#all : codebases
#all : rpms
#all : srpms
# mention $(ALL) here rather than rpms 
# this is because the inter-package dependencies are expressed like
# util-vserver: util-python
all: rpms
endif
endif

####################
# gather build information for the 'About' page
SOURCES/myplc-release:
	@echo 'Creating myplc-release'
	mkdir -p SOURCES
	rm -f $@
	(echo -n 'Build bdate: ' ; date '+%Y.%m.%d') >> $@
	(echo -n 'Build btime: ' ; date '+%H:%M') >> $@
	(echo -n 'Build hostname: ' ; hostname) >> $@
	(echo -n 'Build location: ' ; pwd) >> $@
	(echo -n 'Build tags file: ' ; fgrep '$$''Id' $(PLDISTROTAGS)) >> $@
	echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx modules versions info" >> $@
	$(MAKE) --no-print-directory versions >> $@

####################
# notes: 
# * to make configuration easier, we always use the first module's
# definitions (CVSROOT,TAG, or SVNPATH) to extract the spec file
# * for the same reason, in case cvs is used, the first module name is added to 
# $(package)-SPEC - otherwise the cvs modules have to define spec as 
# <module>/<module>.spec while svn modules just define it as <module>.spec
#
define stage1_variables
$(1)_spec = $(notdir $($(1)-SPEC))
$(1)_specpath = CODESPECS/$(notdir $($(1)-SPEC))
$(1)_module = $(firstword $($(1)-MODULES))
endef

$(foreach package, $(ALL), $(eval $(call stage1_variables,$(package))))

#
# for each package, compute whether we need to set date (i.e. whether we use the trunk)
# the myplc package is forced to have a date, because it is more convenient
# (we cannot bump its number everytime something changes in the system)
# 
define package_hasdate
$(1)_hasdate = $(if $(subst myplc,,$(1)), \
	          $(if $($(1)-SVNPATH),\
		     $(if $(findstring /trunk,$($(1)-SVNPATH)),yes,),\
		     $(if $(findstring HEAD,$($(1)-TAG)),yes,)), \
		yes)
endef

$(foreach package, $(ALL), $(eval $(call package_hasdate,$(package))))

### extract spec file from scm
# usage: extract_spec_file package 
# see early releases for comments on other possible implementations
# cannot use variables in such rules, we need to inline everything, sigh
define target_spec
$($(1)_specpath):
	mkdir -p CODESPECS
	(echo -n "# Generated by planetlab build from $($(1)-SPEC) on " ; date) > $($(1)_specpath)
	echo "%define distroname $(DISTRO)" >> $($(1)_specpath)
	echo "%define distrorelease $(RELEASE)" >> $($(1)_specpath)
	echo "%define pldistro $(PLDISTRO)" >> $($(1)_specpath)
	$(if $($(1)_hasdate),echo "%define date $(shell date +%Y.%m.%d)" >> $($(1)_specpath),)
	echo "# included from codebase specfile" >> $($(1)_specpath)
	$(if $($(1)-SPECVARS), \
	  $(foreach line,$($(1)-SPECVARS), \
	    echo "%define" $(word 1,$(subst =, ,$(line))) "$(word 2,$(subst =, ,$(line)))" >> $($(1)_specpath) ;))
	$(if $($($(1)_module)-SVNPATH),\
          svn cat $($($(1)_module)-SVNPATH)/$($(1)-SPEC) >> $($(1)_specpath),\
          cvs -d $($($(1)_module)-CVSROOT) checkout \
	      -r $($($(1)_module)-TAG) \
	      -p $($(1)_module)/$($(1)-SPEC) >> $($(1)_specpath))
	@if [ -z $($(1)_specpath) ] ; then rm $($(1)_specpath) ; exit 1 ; fi
endef

$(foreach package,$(ALL),$(eval $(call target_spec,$(package))))

### this utility allows to extract various info from a spec file
### and to define them in makefiles
spec2make: spec2make.c
	$(CC) -g -Wall $< -o $@ -lrpm -lrpmbuild

# Base rpmbuild in the current directory
# trying a longer topdir 
# http://forums.fedoraforum.org/showthread.php?t=39625
# and more specifically post#6
# hard-wired for now 
export HOME := /building
.rpmmacros:
	rm -f /building ; ln -s /build /building
	rm -f $@ 
	echo "%_topdir $(HOME)" >> $@
	echo "%_tmppath $(HOME)/tmp" >> $@
	echo "%_netsharedpath /proc:/dev/pts" >> $@
	echo "%_install_langs C:de:en:es:fr" >> $@

### run spec2make on the spec file and include the result
# usage: spec2make package
define target_mk
MAKE/$(1).mk: $($(1)_specpath) spec2make .rpmmacros
	mkdir -p MAKE
	./spec2make $($(1)-RPMFLAGS) $($(1)_specpath) $(1) > MAKE/$(1).mk
	@if [ -z MAKE/$(1).mk ] ; then rm MAKE/$(1).mk ; exit 1 ; fi
endef

$(foreach package,$(ALL),$(eval $(call target_mk,$(package))))

# stores PLDISTRO in a file
# this is done at stage1. later run wont get confused
pldistro.mk:
	echo "PLDISTRO:=$(PLDISTRO)" > $@
	echo "PLDISTROTAGS:=$(PLDISTROTAGS)" >> $@

savepldistro: pldistro.mk
.PHONY: savepldistro

# always refresh this
all: savepldistro

####################
### pack sources into tarballs
ALLTARBALLS:= $(foreach package, $(ALL), $($(package)-TARBALLS))
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
# with a copy -rl from CODEBASES/<package>
# the former is $(package-SOURCE) and the latter is $(package-CODEBASE)
ALLSOURCES:=$(foreach package, $(ALL), $($(package)-SOURCE))
# so that make does not use the rule below directly for creating the tarball files
.SECONDARY: $(ALLSOURCES)

sources: $(ALLSOURCES)
	@echo $(words $(ALLSOURCES)) versioned source trees OK
.PHONY: sources

define target_link_codebase_sources
$($(1)-SOURCE): $($(1)-CODEBASE) ; mkdir -p SOURCES ; cp -rl $($(1)-CODEBASE) $($(1)-SOURCE)
endef

$(foreach package,$(ALL),$(eval $(call target_link_codebase_sources,$(package))))

### codebase extraction
ALLCODEBASES:=$(foreach package, $(ALL), $($(package)-CODEBASE))
# so that make does not use the rule below directly for creating the tarball files
.SECONDARY: $(ALLCODEBASES)

codebases : $(ALLCODEBASES)
	@echo $(words $(ALLCODEBASES)) codebase OK
.PHONY: codebases

### extract codebase 
# usage: extract_single_module package 
define extract_single_module
	mkdir -p CODEBASES
	$(if $($($(1)_module)-SVNPATH), cd CODEBASES && svn export $($($(1)_module)-SVNPATH) $(1), cd CODEBASES && cvs -d $($($(1)_module)-CVSROOT) export -r $($($(1)_module)-TAG) -d $(1) $($(1)_module))
endef

# usage: extract_multi_module package 
define extract_multi_module
	mkdir -p CODEBASES/$(1) && cd CODEBASES/$(1) && (\
	$(foreach m,$($(1)-MODULES), $(if $($(m)-SVNPATH), svn export $($(m)-SVNPATH) $(m);, cvs -d $($(m)-CVSROOT) export -r $($(m)-TAG) $(m);)))
endef

CODEBASES/%: package=$(notdir $@)
CODEBASES/%: multi_module=$(word 2,$($(package)-MODULES))
CODEBASES/%: 
	@(echo -n "XXXXXXXXXXXXXXX -- BEG CODEBASE $(package) : $@ " ; date)
	$(if $(multi_module),\
	  $(call extract_multi_module,$(package)),\
	  $(call extract_single_module,$(package)))
	@(echo -n "XXXXXXXXXXXXXXX -- END CODEBASE $(package) : $@ " ; date)

### source rpms
ALLSRPMS:=$(foreach package,$(ALL),$($(package)-SRPM))
srpms: $(ALLSRPMS)
	@echo $(words $(ALLSRPMS)) source rpms OK
.PHONY: srpms

# usage: target_source_rpm package
# select upon the package name, whether it contains srpm or not
define target_source_rpm 
ifeq "$(subst srpm,,$(1))" "$(1)"
$($(1)-SRPM): $($(1)_specpath) .rpmmacros $($(1)-TARBALLS) 
	mkdir -p BUILD SRPMS tmp
	@(echo -n "XXXXXXXXXXXXXXX -- BEG SRPM $(1) " ; date)
	$(if $($(1)-RPMBUILD),\
	  $($(1)-RPMBUILD) $($(1)-RPMFLAGS) -bs $($(1)_specpath),
	  $(RPMBUILD) $($(1)-RPMFLAGS) -bs $($(1)_specpath))	
	@(echo -n "XXXXXXXXXXXXXXX -- END SRPM $(1) " ; date)
else
$($(1)-SRPM): $($(1)_specpath) .rpmmacros $($(1)-CODEBASE)
	mkdir -p BUILD SRPMS tmp
	@(echo -n "XXXXXXXXXXXXXXX -- BEG SRPM $(1) (using make srpm) " ; date)
	make -C $($(1)-CODEBASE) srpm && \
           rm -f SRPMS/$(notdir $($(1)-SRPM)) && \
           ln $($(1)-CODEBASE)/$(notdir $($(1)-SRPM)) SRPMS/$(notdir $($(1)-SRPM)) 
	@(echo -n "XXXXXXXXXXXXXXX -- END SRPM $(1) " ; date)
endif
endef

$(foreach package,$(ALL),$(eval $(call target_source_rpm,$(package))))

### rpmbuild invokation
ALLRPMS:=$(foreach package,$(ALL),$($(package)-RPMS))
# same as above, mention $(ALL) and not $(ALLRPMS)
rpms: $(ALLRPMS)
	@echo $(words $(ALLRPMS)) binary rpms OK
.PHONY: rpms

# usage: build_binary_rpm package
# xxx hacky - invoke createrepo if DEPENDFILES mentions RPMS/yumgroups.xml
define target_binary_rpm 
$($(1)-RPMS): $($(1)-SRPM)
	mkdir -p BUILD RPMS SPECS tmp
	@(echo -n "XXXXXXXXXXXXXXX -- BEG RPM $(1) " ; date)
	$(if $(findstring RPMS/yumgroups.xml,$($(1)-DEPENDFILES)), createrepo --quiet -g yumgroups.xml RPMS/ , )
	@$(foreach devel,$($(1)-DEPENDDEVELS), $(if $($(devel)-DEVEL-RPMS),rpm -Uvh $($(devel)-DEVEL-RPMS);))
	$(if $($(1)-RPMBUILD),\
	  $($(1)-RPMBUILD) $($(1)-RPMFLAGS) --rebuild $($(1)-SRPM), \
	  $(RPMBUILD)  $($(1)-RPMFLAGS) --rebuild $($(1)-SRPM))
	@(echo -n "XXXXXXXXXXXXXXX -- END RPM $(1) " ; date)
endef

$(foreach package,$(ALL),$(eval $(call target_binary_rpm,$(package))))

### RPMS/yumgroups.xml
ifndef YUMGROUPS
YUMGROUPS := groups/$(PLDISTRO).xml
endif
RPMS/yumgroups.xml: $(YUMGROUPS)
	install -D -m 644 $(YUMGROUPS) $@

### shorthand target
# e.g. make proper -> does propers rpms
# usage shorthand_target package
define target_shorthand 
$(1): $($(package)-RPMS)
.PHONY: $(1)
$(1)-spec: $($(package)-SPEC)
.PHONY: $(1)-spec
$(1)-mk: $($(package)-MK)
.PHONY: $(1)-mk
$(1)-tarball: $($(package)-TARBALLS)
.PHONY: $(1)-tarball
$(1)-codebase: $($(package)-CODEBASE)
.PHONY: $(1)-source
$(1)-source: $($(package)-SOURCE)
.PHONY: $(1)-codebase
$(1)-rpms: $($(package)-RPMS)
.PHONY: $(1)-rpms
$(1)-srpm: $($(package)-SRPM)
.PHONY: $(1)-srpm
endef

$(foreach package,$(ALL),$(eval $(call target_shorthand,$(package))))

### dependencies
define package_depends_on_file
$(1):$(2)
$($(1)-RPMS):$(2)
endef

define target_dependfiles
$(foreach file,$($(1)-DEPENDFILES),$(eval $(call package_depends_on_file,$(1),$(file))))
endef

define package_depends_on_package
$(1):$(2)
$(1):$($(2)-RPMS)
$($(1)-RPMS):$($(2)-RPMS)
endef

define target_depends
$(foreach package,$($(1)-DEPENDS) $($(1)-DEPENDDEVELS),$(eval $(call package_depends_on_package,$(1),$(package))))
endef

$(foreach package,$(ALL),$(eval $(call target_depends,$(package))))
$(foreach package,$(ALL),$(eval $(call target_dependfiles,$(package))))

### clean target
# usage: target_clean package
define target_clean
$(1)-clean-codebase:
	rm -rf $($(1)-CODEBASE)
.PHONY: $(1)-clean-codebase
CLEANS += $(1)-clean-codebase
$(1)-clean-source:
	rm -rf $($(1)-SOURCE)
.PHONY: $(1)-clean-source
CLEANS += $(1)-clean-source
$(1)-clean-tarball:
	rm -rf $($(1)-TARBALLS)
.PHONY: $(1)-clean-tarball
CLEANS += $(1)-clean-tarball
$(1)-clean-build:
	rm -rf BUILD/$(notdir $($(1)-SOURCE))
CLEANS += $(1)-clean-build
$(1)-clean-rpms:
	rm -rf $($(1)-RPMS)
.PHONY: $(1)-clean-rpms
CLEANS += $(1)-clean-rpms
$(1)-clean-srpm:
	rm -rf $($(1)-SRPM)
.PHONY: $(1)-clean-srpm
CLEANS += $(1)-clean-srpm
$(1)-clean: $(1)-clean-codebase $(1)-clean-source $(1)-clean-tarball $(1)-clean-build $(1)-clean-rpms $(1)-clean-srpm
.PHONY: $(1)-clean
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
	rm -rf pldistro.mk .rpmmacros spec2make CODESPECS MAKE 
distclean2:
	rm -rf CODEBASES SOURCES BUILD RPMS SRPMS SPECS tmp
distclean: distclean1 distclean2
.PHONY: distclean1 distclean2 distclean

# xxx tmp - I cannot use this on my mac for local testing
ISMACOS=$(findstring Darwin,$(shell uname))
ifneq "$(ISMACOS)" ""
#################### produce reliable version information
# for a given module
VFORMAT="%30s := %s\n"
define print_version
$(1)-version:
	@$(if $($(1)-SVNPATH),\
	   printf $(VFORMAT) $(1)-SVNPATH "$($(1)-SVNPATH)",\
	   printf $(VFORMAT) $(1)-CVSROOT "$($(1)-CVSROOT)" ; printf $(VFORMAT) $(1)-TAG "$($(1)-TAG)")
endef

# compute all modules
ALL-MODULES :=
$(foreach package,$(ALL), $(eval ALL-MODULES+=$($(package)-MODULES)))
ALL-MODULES:=$(sort $(ALL-MODULES))

$(foreach module,$(ALL-MODULES), $(eval $(call print_version,$(module))))

versions: $(foreach module, $(ALL-MODULES), $(module)-version)
else
versions:
	@echo "warning : the 'versions' target is not supported on macos"
endif

#################### include install Makefile
# the default is to use the distro-dependent install file
# however the main distro file can redefine PLDISTROINSTALL
ifndef PLDISTROINSTALL
PLDISTROINSTALL := $(PLDISTRO)-install.mk
endif
# only if present
-include $(PLDISTROINSTALL)

####################
help:
	@echo "Known pakages are"
	@echo "  $(ALL)"
	@echo "Run make in two stages:"
	@echo ""
	@echo "make stage1=true PLDISTRO=onelab"
	@echo " -> extracts all spec files in CODESPECS/ and mk files in MAKE/"
	@echo "    as well as save PLDISTRO for subsequent runs"
	@echo ""
	@echo "Then you can use the following targets"
	@echo '$ make'
	@echo "  rebuilds everything"
	@echo '$ make util-vserver'
	@echo "  makes the RPMS related to util-vserver"
	@echo "  equivalent to 'make util-vserver-rpms'"
	@echo ""
	@echo "Or, vertically - step-by-step for a given package"
	@echo '$ make util-vserver-codebase'
	@echo "  performs codebase extraction in CODEBASES/util-vserver"
	@echo '$ make util-vserver-source'
	@echo "  creates source link in SOURCES/util-vserver-<version>"
	@echo '$ make util-vserver-tarball'
	@echo "  creates source tarball in SOURCES/util-vserver-<version>.<tarextension>"
	@echo '$ make util-vserver-rpms'
	@echo "  build rpm(s) in RPMS/"
	@echo '$ make util-vserver-srpm'
	@echo "  build source rpm in SRPMS/"
	@echo ""
	@echo "Or, horizontally, reach a step for all known packages"
	@echo '$ make codebases'
	@echo '$ make sources'
	@echo '$ make tarballs'
	@echo '$ make rpms'
	@echo '$ make srpms'
	@echo ""
	@echo "Cleaning examples"
	@echo "$ make clean"
	@echo "  removes the files made by make"
	@echo "$ make distclean"
	@echo "  brute-force cleaning, removes entire directories - requires a new stage1"
	@echo "$ make util-vserver-clean"
	@echo "  removes codebase, source, tarball, build, rpm and srpm for util-vserver"
	@echo "$ make util-vserver-clean-codebase"
	@echo "  and so on for source, tarball, build, rpm and srpm"

#################### convenience, for debugging only
# make +foo : prints the value of $(foo)
# make ++foo : idem but verbose, i.e. foo=$(foo)
++%: varname=$(subst +,,$@)
++%:
	@echo "$(varname)=$($(varname))"
+%: varname=$(subst +,,$@)
+%:
	@echo "$($(varname))"
