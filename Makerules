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
# $Id: Makerules,v 1.1.1.1 2004/04/07 21:13:51 mlh-pl_rpm Exp $
#

# Base cvsps and rpmbuild in the current directory
export HOME := $(shell pwd)
export CVSROOT CVS_RSH

#
# Parse spec file template
#

MK := SPECS/$(patsubst %.spec,%.mk,$(notdir $(SPEC)))

$(MK): SPECS/$(notdir $(SPEC)).in
        # Substitute '$' for '%' and 'name := value' for '%define name value' or 'name: value'
	sed -n \
	-e 's/%{/$${/g' \
	-e 's/^%define[	 ]*\([^	 ]*\)[	 ]*\([^	 ]*\)/\1 := \2/p' \
	-e 's/^\([^	 ]*\):[	 ]*\([^	 ]*\)/\1 := \2/p' \
	$< > $@
ifneq ($(INITIAL),$(TAG))
        # Get list of PatchSets
	cvsps --cvs-direct --root $(CVSROOT) -r $(INITIAL) $(if $(TAG:HEAD=),-r $(TAG)) $(MODULE) | \
	sed -ne 's|^PatchSet[	 ]*\([0-9]*\)|PATCHES += \1|p' >> $@
endif

SPECS/$(notdir $(SPEC)).in:
	mkdir -p SPECS
	cvs -d $(CVSROOT) checkout -r $(TAG) -p $(SPEC) > $@

include $(MK)

#
# Generate tarball
#

# Add tarball to the list of sources
SOURCES += SOURCES/$(Source0)

# Get rid of .tar.bz2 or .tar.gz or .tgz
Base0 := $(basename $(basename $(Source0)))

# Export module
SOURCES/$(Base0):
	mkdir -p SOURCES
	cd SOURCES && cvs -d $(CVSROOT) export -r $(INITIAL) -d $(Base0) $(MODULE)

.SECONDARY: $(SOURCES)/$(Base0)

# Generate tarball
SOURCES/$(Base0).tar.bz2: SOURCES/$(Base0)
	tar cpjf $@ -C SOURCES $(Base0)

SOURCES/$(Base0).tar.gz SOURCES/$(Base0).tgz: SOURCES/$(Base0)
	tar cpzf $@ -C SOURCES $(Base0)

SOURCES/$(Base0).tar: SOURCES/$(Base0)
	tar cpf $@ -C SOURCES $(Base0)

#
# Generate patches
#

define PATCH_template

# In case the spec file did not explicitly list the PatchSet
ifeq ($$(origin Patch$(1)),undefined)
Patch$(1) := $(1).patch.bz2
endif

# Add patch to the list of sources
SOURCES += SOURCES/$$(Patch$(1))

# Generate uncompressed patch
SOURCES/$$(patsubst %.gz,%,$$(patsubst %.bz2,%,$$(Patch$(1)))):
	mkdir -p SOURCES
	cvsps --cvs-direct --root $(CVSROOT) -g -s $(1) $(MODULE) > $$@

endef

# bzip2
%.bz2: %
	bzip2 -c $< > $@

# gzip
%.gz: %
	gzip -c $< > $@

# Generate rules to generate patches
$(foreach n,$(PATCHES),$(eval $(call PATCH_template,$(n))))

#
# Generate spec file
#

ifeq ($(TAG),HEAD)
# Define date for untagged builds
DATE := $(shell date +%Y.%m.%d)
endif

# Generate spec file
SPECS/$(notdir $(SPEC)): SPECS/$(notdir $(SPEC)).in
	rm -f $@
ifeq ($(TAG),HEAD)
        # Define date for untagged builds
	echo "%define date $(DATE)" >> $@
endif
        # Rewrite patch sections of spec file
	perl -n -e ' \
	next if /^Patch.*/; \
	next if /^%patch.*/; \
	print; \
	if (/^Source.*/) { $(foreach n,$(PATCHES),print "Patch$(n): $(Patch$(n))\n";) } \
	if (/^%setup.*/) { $(foreach n,$(PATCHES),print "%patch$(n) -p1\n";) } \
	' $< >> $@

#
# Build
#

NVR := $(shell rpmquery $(RPMFLAGS) $(if $(DATE),--define "date $(DATE)") --specfile SPECS/$(notdir $(SPEC)).in | head -1)
ARCH := $(shell rpm $(RPMFLAGS) --showrc | sed -ne 's/^build arch[	 ]*:[	 ]*\(.*\)/\1/p')

all: RPMS/$(ARCH)/$(NVR).$(ARCH).rpm SRPMS/$(NVR).src.rpm

# Build RPM
RPMS/$(ARCH)/$(NVR).$(ARCH).rpm: SPECS/$(notdir $(SPEC)) $(SOURCES) .rpmmacros
	mkdir -p BUILD RPMS
	rpmbuild $(RPMFLAGS) -bb $<

# Build SRPM
SRPMS/$(NVR).src.rpm: SPECS/$(notdir $(SPEC)) $(SOURCES) .rpmmacros
	mkdir -p SRPMS
	rpmbuild $(RPMFLAGS) -bs $<

# Base rpmbuild in the current directory
.rpmmacros:
	echo "%_topdir $(HOME)" > $@

.PHONY: all
