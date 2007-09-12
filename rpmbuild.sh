#!/bin/bash

# We require this hack to tell rpmbuild where to find the .rpmmacros
# file.  And for whatever reason the $HOME variable used by the build
# system is not set correctly when invoking rpmbuild with sudo.  This
# is hopefully just a temporary hack until we can either figure out
# what to do with sudo or pass rpmbuild an option that points it at a
# specific .rpmmacros file.

# Be verbose
set -x

export HOME=${PWD}
rpmbuild $@
