#!/bin/bash
#
# Release build script
#
# $Id: Makerules,v 1.7 2004/04/14 18:05:30 mlh-pl_rpm Exp $
#

# Set defaults
CVSROOT=pup-pl_rpm@cvs.planet-lab.org:/cvs
CVS_RSH=ssh
MODULE=rpm
TAG=HEAD

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

# Redirect both stdout and stderr to log file
exec &>${BASE}/log

# Build
cvs -d ${CVSROOT} export -r ${TAG} -d ${BASE} ${MODULE}
make -C ${BASE}
