#!/bin/bash
#
# PlanetLab release build script. Intended to be used by scripts and
# crontabs to build nightly releases (default). Can also be invoked
# manually to build a tagged release (-r) in the current directory.
#
# $Id: build.sh,v 1.11 2004/08/31 14:39:42 mlh-pl_rpm Exp $
#

# Set defaults
CVSROOT=:pserver:anon@build.planet-lab.org:/cvs
CVS_RSH=ssh
MODULE=build
TAG=HEAD
BASE=$PWD

# Alpha node repository
ALPHA_BOOT=build@boot.planet-lab.org
ALPHA_ROOT=/www/planetlab/install-rpms/archive/planetlab-alpha
ALPHA_RPMS=/www/planetlab/install-rpms/planetlab-alpha

# Export certain variables
export CVS_RSH

# Get options
while getopts "d:r:m:b:x:h" opt ; do
    case $opt in
	d)
	    CVSROOT=$OPTARG
	    ;;
	r)
	    TAG=$OPTARG
	    ;;
	m)
	    MAILTO=$OPTARG
	    ;;
	b)
	    BASE=$OPTARG
	    ;;
	x)
	    BUILDS=$OPTARG
	    ;;
	h|*)
	    echo "usage: `basename $0` [OPTION]..."
	    echo "	-d directory	CVS repository root (default $CVSROOT)"
	    echo "	-r revision	CVS revision to checkout (default $TAG)"
	    echo "	-m address	Notify recipient of failures (default: none)"
	    echo "	-b base		Run operations in specified base directory (default $BASE)"
	    echo "	-x N		Remove all but the last N runs from the base directory (default: none)"
	    exit 1
	    ;;
    esac
done

# Base operations in specified directory
mkdir -p $BASE
cd $BASE || exit $?

# Remove old runs
if [ -n "$BUILDS" ] ; then
    ls -t | sed -n ${BUILDS}~1p | xargs rm -rf
fi

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

# Redirect output from here
exec &>${BASE}/log

# XXX Hack to store the pup key as well as the bui key
eval `ssh-agent`
for i in `grep -l "BEGIN.*PRIVATE KEY" $HOME/.ssh/*` ; do
    SSH_ASKPASS=/bin/false ssh-add $i
done

# Build
cvs -d ${CVSROOT} export -r ${TAG} -d ${BASE} ${MODULE}
make -C ${BASE}

if [ $? -ne 0 ] ; then
    # Notify recipient of failure or just dump to stdout
    if [ -n "$MAILTO" ] ; then
	NOTIFY="mail -s 'Failures for ${BASE}' $MAILTO"
    else
	NOTIFY=cat
    fi
    (
    # Dump log
    if [ -f ${BASE}/log ] ; then
	tail -100 ${BASE}/log
    else
	echo "Error $?"
    fi
    ) | eval $NOTIFY
elif [ -n "$BUILDS" ] ; then
    # Remove old nightly runs
    echo "cd ${ALPHA_ROOT} && ls -t | sed -n ${BUILDS}~1p | xargs rm -rf" | ssh ${ALPHA_BOOT} sh -s
    # Update alpha node repository
    for i in RPMS SRPMS ; do
	ssh ${ALPHA_BOOT} mkdir -p ${ALPHA_ROOT}/${BASE}/${i}
	find ${BASE}/${i} -type f | xargs -i scp {} ${ALPHA_BOOT}:${ALPHA_ROOT}/${BASE}/${i}
	ssh ${ALPHA_BOOT} yum-arch ${ALPHA_ROOT}/${BASE}/${i} >/dev/null
    done
    # Update symlink
    ssh ${ALPHA_BOOT} ln -nsf ${ALPHA_ROOT}/${BASE}/RPMS/ ${ALPHA_RPMS}
fi

# Kill the current agent
ssh-agent -k
