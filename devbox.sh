#!/bin/bash
#
# PlanetLab devbox release script. Intended to be used by scripts and
# crontabs to build nightly releases (default).
#
# $Id: devbox.sh,v 1.1 2005/03/02 07:21:05 mef Exp $
#

# Set defaults
CVSROOT=:pserver:anon@cvs.planet-lab.org:/cvs
CVS_RSH=ssh
MODULE=build
TAG=HEAD
BASE=$PWD

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
	    ;;
	h|*)
	    echo "usage: `basename $0` [OPTION]..."
	    echo "	-d directory	CVS repository root (default $CVSROOT)"
	    echo "	-r revision	CVS revision to checkout (default $TAG)"
	    echo "	-m address	Notify recipient of failures (default: none)"
	    echo "	-b base		Run operations in specified base directory (default $BASE)"
	    exit 1
	    ;;
    esac
done

# Base operations in specified directory
BASE=`mktemp -d /tmp/DEVBOX.XXXXXX` || { echo $"could not make temp file" >& 2; exit 1; }
mkdir -p $BASE
cd $BASE || exit $?

# Redirect output from here
exec 2>&1
exec &>${BASE}/log

# XXX For debugging
set -x

# Upload packages to boot server
SERVER=build@boot.planet-lab.org
REPOSITORY=/var/www/html/install-rpms

for RELEASE in devbox alpha-devbox beta-devbox ; do
    TMPDEVBOXRELEASE=planetlab-${RELEASE}_`date +%Y.%m.%d`_tmp
    DEVBOXRELEASE=planetlab-${RELEASE}

    ssh $SERVER mkdir -p ${REPOSITORY}/${TMPDEVBOXRELEASE}
    if [ $? -ne 0 ] ; then
	echo "ERROR: mkdir -p ${REPOSITORY}/${TMPDEVBOXRELEASE} failed"
	exit 1 
    fi
    BUILT=$(echo $DEVBOXRELEASE | sed "s,\-devbox,,")
    ssh $SERVER ln -nf ${REPOSITORY}/$BUILT/*.rpm ${REPOSITORY}/${TMPDEVBOXRELEASE}

    mkdir -p ${BASE}/${DEVBOXRELEASE}
    install -D -m 644 groups/${RELEASE}_yumgroups.xml ${BASE}/${DEVBOXRELEASE}/yumgroups.xml
    scp ${BASE}/${DEVBOXRELEASE}/yumgroups.xml ${SERVER}:${REPOSITORY}/${TMPDEVBOXRELEASE}/yumgroups.xml

    ssh $SERVER yum-arch ${REPOSITORY}/${TMPDEVBOXRELEASE} >/dev/null

    ssh $SERVER mv ${REPOSITORY}/${DEVBOXRELEASE} ${REPOSITORY}/${DEVBOXRELEASE}-old
    ssh $SERVER mv ${REPOSITORY}/${TMPDEVBOXRELEASE} ${REPOSITORY}/${DEVBOXRELEASE}
    if [ $? -ne 0 ] ; then    
	ssh $SERVER mv ${REPOSITORY}/${DEVBOXRELEASE}-old ${REPOSITORY}/${DEVBOXRELEASE}
    else
	ssh $SERVER rm -rf ${REPOSITORY}/${DEVBOXRELEASE}-old
    fi
done

cd / || exit $?
rm -rf $BASE

exit 0
