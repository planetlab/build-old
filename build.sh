#!/bin/bash
#
# PlanetLab release build script. Intended to be used by scripts and
# crontabs to build nightly releases (default). Can also be invoked
# manually to build a tagged release (-r) in the current directory.
#
# $Id: build.sh,v 1.26 2005/04/13 17:20:30 mlhuang Exp $
#

# Set defaults
CVSROOT=:pserver:anon@cvs.planet-lab.org:/cvs
CVS_RSH=ssh
MODULE=build
TAG=HEAD
BASE=$PWD

# cron does not set USER?
[ -z "$USER" ] && export USER=$LOGNAME

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
exec 2>&1
exec &>${BASE}/log

# Build
cvs -d ${CVSROOT} export -r ${TAG} -d ${BASE} ${MODULE}
make -C ${BASE}
rc=$?

if [ $rc -ne 0 ] ; then
    # Notify recipient of failure
    if [ -n "$MAILTO" ] ; then
	tail -100 ${BASE}/log | mail -s "Failures for ${BASE}" $MAILTO
    fi
    exit $rc
fi

# XXX For debugging
set -x

# XXX Should check out a tagged version of yumgroups.xml
echo "$(date) Getting yumgroups.xml"
cvs -d ${CVSROOT} checkout -p alpina/groups/v3_yumgroups.xml > ${BASE}/RPMS/yumgroups.xml

# Create package manifest
echo "$(date) Creating package manifest"
URLBASE=$(cd ${BASE} && pwd -P)
URLBASE="http://build.planet-lab.org/${URLBASE##$HOME/}/SRPMS"
${BASE}/packages.sh -b ${URLBASE} ${BASE}/SRPMS > ${BASE}/SRPMS/packages.xml

# Upload packages to boot server
SERVER=build@boot.planet-lab.org
ARCHIVE=/var/www/html/install-rpms/archive
# Put nightly alpha builds in a subdirectory
if [ "$TAG" = "HEAD" ] ; then
    ARCHIVE=$ARCHIVE/planetlab-alpha
    REPOS=/var/www/html/install-rpms/planetlab-alpha
fi

# Remove old runs
if [ -n "$BUILDS" ] ; then
    echo "$(date) Removing old runs"
    echo "cd $ARCHIVE && ls -t | sed -n ${BUILDS}~1p | xargs rm -rf" | ssh $SERVER /bin/bash -s
fi

# Populate repository
echo "$(date) Populating repository"
for RPMS in RPMS SRPMS ; do
    ssh $SERVER mkdir -p $ARCHIVE/$BASE/$RPMS/
    find $BASE/$RPMS/ -type f | xargs -i scp {} $SERVER:$ARCHIVE/$BASE/$RPMS/
    ssh $SERVER yum-arch $ARCHIVE/$BASE/$RPMS/ >/dev/null
done


# Update nightly alpha symlink if it does not exist or is broken, or
# it is Monday
echo "$(date) Updating symlink"
if [ "$TAG" = "HEAD" ] && ([ ! -e $REPOS ] || [ "$(date +%A)" = "Monday" ]) ; then
    ssh $SERVER ln -nsf $ARCHIVE/$BASE/RPMS/ $REPOS
fi

echo "$(date) $BASE done"

exit 0
