#!/bin/bash
#
# PlanetLab release build script. Intended to be used by scripts and
# crontabs to build nightly releases (default). Can also be invoked
# manually to build a tagged release (-r) in the current directory.
#
# $Id: build.sh,v 1.4 2004/05/26 18:50:15 mlh-pl_rpm Exp $
#

# Set defaults
CVSROOT=pup-pl_rpm@cvs.planet-lab.org:/cvs
CVS_RSH=ssh
MODULE=rpm
TAG=HEAD

# Export certain variables
export CVS_RSH

# Get options
while getopts "d:r:" opt ; do
    case $opt in
	d)
	    CVSROOT=$OPTARG
	    ;;
	r)
	    TAG=$OPTARG
	    ;;
	*)
	    echo "usage: `basename $0` [-d $CVSROOT] [-r $TAG]"
	    exit 1
	    ;;
    esac
done

# Create a unique build base
BASE=${TAG/HEAD/`date +%Y.%m.%d`}
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

# Build
(
cvs -d ${CVSROOT} export -r ${TAG} -d ${BASE} ${MODULE}
make -C ${BASE}
) >${BASE}/log 2>&1

# Dump log
if [ $? -ne 0 ] ; then
    if [ -f ${BASE}/log ] ; then
	tail -100 ${BASE}/log
    else
	echo "Error $?"
    fi
fi
