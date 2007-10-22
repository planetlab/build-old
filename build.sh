#!/bin/bash
#
# PlanetLab release build script. Intended to be used by scripts and
# crontabs to build nightly releases (default). Can also be invoked
# manually to build a tagged release (-r) in the current directory.
#
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2003-2005 The Trustees of Princeton University
#
# $Id: build.sh,v 1.43 2007/02/01 16:03:33 mlhuang Exp $
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Set defaults
SVNPATH=https://svn.planet-lab.org/svn
TAG=trunk
MODULE=build
BASE=$PWD
PLDISTRO=planetlab
VSERVER=

# cron does not set USER?
[ -z "$USER" ] && export USER=$LOGNAME

# Get options
while getopts "d:r:m:f:b:x:v:h" opt ; do
    case $opt in
	d)
	    SVNPATH=$OPTARG
	    ;;
	r)
	    TAG=$OPTARG
	    ;;
	m)
	    MAILTO=$OPTARG
	    ;;
	f)
	    PLDISTRO="$OPTARG"
	    ;;
	b)
	    BASE=$OPTARG
	    ;;
	x)
	    BUILDS=$OPTARG
	    ;;
	v)
	    VSERVER=$OPTARG
	    ;;
	h|*)
	    echo "usage: `basename $0` [OPTION]..."
	    echo "	-d directory	SVN repository root (default $SVNPATH)"
	    echo "	-r revision	SVN revision to checkout (default $TAG)"
	    echo "	-v Vserver	Vserver reference to build within (optional)"
	    echo "	-m address	Notify recipient of failures (default: none)"
	    echo "	-f distro	Distribution to build (default: $PLDISTRO)"
	    echo "	-b base		Run operations in specified base directory (default $BASE)"
	    echo "	-x N		Remove all but the last N runs from the base directory (default: none)"
	    exit 1
	    ;;
    esac
done
shift $(($OPTIND - 1))

# Base operations in specified directory
mkdir -p $BASE
cd $BASE || exit $?
BASEDIR=$(pwd)

# Remove old runs
if [ -n "$BUILDS" ] ; then
    ls -t | sed -n ${BUILDS}~1p | xargs rm -rf
fi

# Create a unique build base
BASE=build_${TAG/trunk/`date +%Y.%m.%d`}
[ -n "${VSERVER}" ] && BASE=${VSERVER}_${BASE}
i=
while ! mkdir ${BASE}${i} 2>/dev/null ; do
    [ -z ${i} ] && BASE=${BASE}.
    i=$((${i}+1))
    if [ $i -gt 100 ] ; then
	echo "$0: Failed to create release directory `pwd`/${BASE}${i}"
	exit 1
    fi
done
BASE=${BASE}${i}

# Redirect output from here
exec 2>&1
exec &>${BASE}/log

failure() {
    # Notify recipient of failure
    if [ -n "$MAILTO" ] ; then
	tail -c 8k ${BASE}/log | mail -s "Failures for ${BASE}" $MAILTO
    fi
    exit 1
}

vfailure() {
    # Notify recipient of failure
    vnamespace -e $BASE umount ${BASEDIR}/${BASE}/data
    vserver $BASE stop
    vserver --silent $BASE delete
    failure
    exit 1
}

trap failure ERR INT

set -x

VCMDPREFIX=
if [ -n "$VSERVER" ] ; then
    vserver $BASE build -m clone --rootdir ${BASEDIR} -- --source /vservers/${VSERVER}
    vserver $BASE start
    trap vfailure ERR INT
    if [ -d /data ] ; then
	vnamespace -e $BASE mount -o ro --bind /data ${BASEDIR}/${BASE}/data
    fi

    # Checkout build directory
    VSUEXEC="vserver $BASE exec su - build -c"

    $VSUEXEC "svn checkout ${SVNPATH}/${MODULE}/${TAG} ${MODULE}"

    # Build
    #XXX vserver $BASE suexec build ${MODULE}/make.sh TAG=${TAG} PLDISTRO=${PLDISTRO}

    # Install to boot server
    # XXX not yet

    trap - ERR INT
    vnamespace -e $BASE umount ${BASEDIR}/${BASE}/data
    vserver $BASE stop
else
    # Checkout build directory
    svn checkout ${SVNPATH}/${MODULE}/${TAG} ${BASE}

    # Build myplc-devel-native, install it to ensure we've got the right packages, and let it rip
    make TAG=${TAG} PLDISTRO=${PLDISTRO} -C ${BASE} BASE=$BASE BUILDS=$BUILDS myplc-devel-native
    sudo yum -y localinstall RPMS/i386/myplc-devel-native-*.*.rpm 

    # Build everything
    make TAG=${TAG} PLDISTRO=${PLDISTRO} -C ${BASE} BASE=$BASE BUILDS=$BUILDS

    # Install to boot server
    make TAG=${TAG} PLDISTRO=${PLDISTRO} -C ${BASE} install BASE=$BASE BUILDS=$BUILDS
fi

exit 0
