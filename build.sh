#!/bin/bash
#
# PlanetLab release build script. Intended to be used by scripts and
# crontabs to build nightly releases (default). Can also be invoked
# manually to build a tagged release (-r) in the current directory.
#
# $Id: build.sh,v 1.5 2004/06/09 14:46:04 mlh-pl_rpm Exp $
#

# Set defaults
CVSROOT=bui-pl_rpm@cvs.planet-lab.org:/cvs
CVS_RSH=ssh
MODULE=rpm
TAG=HEAD

# Alpha node repository
ALPHA_BOOT=build@boot.planet-lab.org
ALPHA_ROOT=/www/planetlab/install-rpms/archive/planetlab-alpha
ALPHA_RPMS=/www/planetlab/install-rpms/planetlab-alpha

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

if [ $? -ne 0 ] ; then
    # Dump log
    if [ -f ${BASE}/log ] ; then
	tail -100 ${BASE}/log
    else
	echo "Error $?"
    fi
elif [ "$TAG" = "HEAD" ] ; then
    # Update alpha node repository
    for i in RPMS SRPMS ; do
	ssh ${ALPHA_BOOT} mkdir -p ${ALPHA_ROOT}/${BASE}/${i}
	find ${BASE}/${i} -type f | xargs -i scp {} ${ALPHA_BOOT}:${ALPHA_ROOT}/${BASE}/${i}
	ssh ${ALPHA_BOOT} yum-arch ${ALPHA_ROOT}/${BASE}/${i}
    done
    # Update symlink
    ssh ${ALPHA_BOOT} ln -nsf ${ALPHA_ROOT}/${BASE}/RPMS/ ${ALPHA_RPMS}
fi
