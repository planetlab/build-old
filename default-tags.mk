#
#
#

SVNPATH := https://svn.planet-lab.org/svn
TAG := trunk


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
