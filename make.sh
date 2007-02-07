#!/bin/bash
#
# make(1) wrapper to build PlanetLab RPMS inside a myplc-devel
# development environment.
#
# 1. $BASE is the build/ directory containing this script.
# 2. Builds myplc-devel using host tools.
# 3. Mounts $BASE onto the home directory of the build user inside
#    myplc-devel.
# 4. Executes "make" on the specified targets.
#
# Can be used to manally restart a build also, e.g.,
#
# cd build/nightly/2007.02.07/
# ./make.sh kernel
# 
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2007 The Trustees of Princeton University
#
# $Id: make.sh,v 1.2 2007/02/07 23:49:42 mlhuang Exp $
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

BASE=$(cd "$(dirname $0)" && pwd -P)

# Delete .rpmmacros and parseSpec files in case we are restarting
rm -f $BASE/.rpmmacros $BASE/parseSpec

# Build development environment first
make -C $BASE myplc-devel

# Build everything else inside the development environment
export PLC_ROOT=$(echo $BASE/BUILD/myplc-devel-*/myplc/devel/root)
export PLC_DATA=$(echo $BASE/BUILD/myplc-devel-*/myplc/devel/data)

cleanup() {
    sudo umount $PLC_ROOT/data/fedora
    sudo umount $PLC_ROOT/data/build
    sudo $BASE/BUILD/myplc-devel-*/myplc/host.init stop
    sudo chown -h -R $USER $PLC_DATA
}

trap "cleanup" ERR INT

# Start development environment
sudo $BASE/BUILD/myplc-devel-*/myplc/host.init start

# Cross mount the current build directory to the build user home directory
sudo mount -o bind,rw $BASE $PLC_ROOT/data/build

# Also cross mount /data/fedora if it exists
if [ -d /data/fedora ] ; then
    sudo mkdir -p $PLC_ROOT/data/fedora
    sudo mount -o bind,ro /data/fedora $PLC_ROOT/data/fedora
fi

# Delete .rpmmacros and parseSpec files so that they get regenerated
# appropriately in the development environment.
rm -f $BASE/.rpmmacros $BASE/parseSpec

# Enable networking
sudo cp -f /etc/hosts /etc/resolv.conf $PLC_ROOT/etc/

# Run the rest of the build
sudo chroot $PLC_ROOT su - build -c "make $@"
rc=$?

# Clean up
cleanup
trap - ERR INT

exit $rc
