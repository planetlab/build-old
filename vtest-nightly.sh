#!/bin/bash
REVISION=$(echo '$Revision: 7654 $' | sed -e 's,\$,,g' -e 's,^\w*:\s,,' )

COMMANDPATH=$0
COMMAND=$(basename $0)

# default values, tunable with command-line options
DEFAULT_FCDISTRO=f7
DEFAULT_PLDISTRO=planetlab
DEFAULT_PERSONALITY=linux32
DEFAULT_BASE="@DATE@--test-@PLDISTRO@-@FCDISTRO@-@PERSONALITY@"
DEFAULT_SVNPATH="http://svn.planet-lab.org/svn/build/trunk"
DEFAULT_WEBPATH="/build/@PLDISTRO@/"

DEFAULT_BUILDREPO="http://build.planet-lab.org/install-rpms/archive/"
DEFAULT_REPOURL="@BUILDREPO@/@PLDISTRO@/@FCDISTRO@/@DATE@--@PLDISTRO@-@FCDISTRO@-@PERSONALITY@/RPMS"

# for the test part
TESTSVNPATH="http://svn.planet-lab.org/svn/tests/trunk/system/"

####################
# assuming vserver runs in UTC
DATE=$(date +'%Y.%m.%d')

# Notify recipient of failure or success, manage various stamps 
function failure() {
    set -x
    WEBLOG=${WEBPATH}/${BASE}.test-log.txt
    cp $LOG ${WEBLOG}
    (echo -n "============================== $COMMAND: failure at " ; date ; tail -c 20k $WEBLOG) > ${WEBLOG}.ko
    if [ -n "$MAILTO" ] ; then
	tail -c 20k ${WEBPATH}/${BASE}.log.txt | mail -s "Failures for test ${BASE}" $MAILTO
    fi
    exit 1
}

function success () {
    set -x
    WEBLOG=${WEBPATH}/${BASE}.test-log.txt
    cp $LOG ${WEBLOG}
    touch ${WEBLOG}.ok
    if [ -n "$MAILTO" ] ; then
	(echo "$PLDISTRO ($BASE) tests for $FCDISTRO completed on $(date)" ) | mail -s "Successful test for ${BASE}" $MAILTO
    fi
    exit 0
}

function show_env () {
    set +x
    echo FCDISTRO=$FCDISTRO
    echo PLDISTRO=$PLDISTRO
    echo BASE=$BASE
    echo SVNPATH=$SVNPATH
    echo MAKEVARS="${MAKEVARS[@]}"
    echo MAKEOPTS="${MAKEOPTS[@]}"
    echo PLDISTROTAGS="$PLDISTROTAGS"
    echo TAGSRELEASE="$TAGSRELEASE"
    echo -n "(might be unexpanded)"
    echo WEBPATH="$WEBPATH"
    if [ -d /vservers ] ; then
	echo PLDISTROTAGS="$PLDISTROTAGS"
    else
	echo "XXXXXXXXXXXXXXXXXXXX Contents of tags definition file /build/$PLDISTROTAGS"
	cat /build/$PLDISTROTAGS
	echo "XXXXXXXXXXXXXXXXXXXX end tags definition"
    fi
    set -x
}

function usage () {
    echo "Usage: $COMMAND [option] make-targets"
    echo "This is $REVISION"
    echo "Supported options"
    echo " -n dry-run : -n passed to make - vserver gets created though - no mail sent"
    echo " -f fcdistro - defaults to $DEFAULT_FCDISTRO"
    echo " -d pldistro - defaults to $DEFAULT_PLDISTRO"
    echo " -p personality - defaults to $DEFAULT_PERSONALITY"
    echo " -b base - defaults to $DEFAULT_BASE"
    echo "    @NAME@ replaced as appropriate"
    echo " -t pldistrotags - defaults to \${PLDISTRO}-tags.mk"
    echo " -r tagsrelease - a release number that refers to PLDISTROTAGS - defaults to HEAD"
    echo " -s svnpath - where to fetch the build module"
    echo " -o : overwrite - re-run in base directory, do not create vserver"
    echo " -m mailto"
    echo " -a makevar=value - space in values are not supported"
    echo " -w webpath - defaults to $DEFAULT_WEBPATH"
    echo " -v : be verbose"
    echo " -7 : uses weekday-@FCDISTRO@ as base"
    exit 1
}

function main () {

    set -e

    # preserve arguments for passing them again later
    declare -a argv
    for arg in "$@"; do argv=(${argv[@]} "$arg") ; done
    
    # parse arguments
    MAKEVARS=()
    MAKEOPTS=()
    while getopts "nf:d:b:p:t:r:s:om:a:w:vh7" opt ; do
	case $opt in
	    n) DRY_RUN="true" ; MAKEOPTS=(${MAKEOPTS[@]} -n) ;;
	    f) FCDISTRO=$OPTARG ;;
	    d) PLDISTRO=$OPTARG ;;
	    p) PERSONALITY=$OPTARG ;;
	    b) BASE=$OPTARG ;;
	    t) PLDISTROTAGS=$OPTARG ;;
	    r) TAGSRELEASE=$OPTARG ;;
	    s) SVNPATH=$OPTARG ;;
	    o) OVERWRITEMODE=true ;;
	    m) MAILTO=$OPTARG ;;
	    a) MAKEVARS=(${MAKEVARS[@]} "$OPTARG") ;;
	    w) WEBPATH=$OPTARG ;;
	    v) set -x ;;
	    7) BASE="$(date +%a|tr A-Z a-z)-@FCDISTRO@" ;;
	    h|*) usage ;;
	esac
    done
	
    shift $(($OPTIND - 1))
    MAKETARGETS="$@"
    
    # set defaults
    [ -z "$FCDISTRO" ] && FCDISTRO=$DEFAULT_FCDISTRO
    [ -z "$PLDISTRO" ] && PLDISTRO=$DEFAULT_PLDISTRO
    [ -z "$PERSONALITY" ] && PERSONALITY=$DEFAULT_PERSONALITY
    [ -z "$PLDISTROTAGS" ] && PLDISTROTAGS="${PLDISTRO}-tags.mk"
    [ -z "$BASE" ] && BASE="$DEFAULT_BASE"
    [ -z "$WEBPATH" ] && WEBPATH="$DEFAULT_WEBPATH"
    [ -z "$SVNPATH" ] && SVNPATH="$DEFAULT_SVNPATH"
    [ -z "$BUILDREPO" ] && SVNPATH="$DEFAULT_BUILDREPO"
    [ -z "$REPOURL" ] && SVNPATH="$DEFAULT_REPOURL"

    [ -n "$DRY_RUN" ] && MAILTO=""
	
    ### set BASE from DISTRO, if unspecified
    sedargs="-e s,@DATE@,${DATE},g -e s,@FCDISTRO@,${FCDISTRO},g -e s,@PLDISTRO@,${PLDISTRO},g -e s,@PERSONALITY@,${PERSONALITY},g"
    BASE=$(echo ${BASE} | sed $sedargs)
    WEBPATH=$(echo ${WEBPATH} | sed $sedargs)
    REPOURL=$(echo ${REPOURL} | sed $sedargs)
    sedargs="-e s,@BUILDREPO@,${BUILDREPO},g"
    REPOURL=$(echo ${REPOURL} | sed $sedargs)
    
    trap failure ERR INT
    # create vserver: check it does not exist yet
    i=
    while [ -d /vservers/${BASE}${i} ] ; do
	# we name subsequent builds <base>-n<i> so the logs and builds get sorted properly
	[ -z ${i} ] && BASE=${BASE}-n
	i=$((${i}+1))
	if [ $i -gt 100 ] ; then
	    echo "$COMMAND: Failed to create build vserver /vservers/${BASE}${i}"
	    exit 1
	fi
    done
    BASE=${BASE}${i}
    # need update
    # manage LOG - beware it might be a symlink so nuke it first
    LOG=/vservers/${BASE}.log.txt
    rm -f $LOG
    exec > $LOG 2>&1 
    set -x
    echo "XXXXXXXXXX $COMMAND: creating vserver $BASE" $(date)
    show_env

    ### extract the whole build - much simpler
    tmpdir=/tmp/$COMMAND-$$
    svn export $SVNPATH $tmpdir
    # Create vserver
    cd $tmpdir
    ./myplc-init-vserver.sh -f ${FCDISTRO} -d ${PLDISTRO} -p ${PERSONALITY} ${BASE} ${REPOURL}
    # cleanup
    cd -
    rm -rf $tmpdir

    vserver ${BASE} stop
    rm -f /etc/vservers/${BASE}/interfaces/0/*
    [ -z "${TESTVSERVER_IP}" ] && TESTVSERVER_DEV="eth0"
    if [ -z "${TESTVSERVER_IP}" ] ; then
	xid=$(cat /etc/vservers/${BASE}/context)
	class_a=10
	class_b=254
	TESTVSERVER_IP=$(python -c "context=int($xid); print '%d.%d.%d.%d' % ($a,$b,(context&0xff00)>>8,context&0xff)")
    fi
    echo "${TESTVSERVER_IP}" > /etc/vservers/${BASE}/interfaces/0/ip
    echo "${TESTVSERVER_DEV}" > /etc/vservers/${BASE}/interfaces/0/dev
    vserver ${BASE} start
    echo "XXXXXXXXXX $COMMAND: preparation of vserver $BASE done" $(date)

    # The log inside the vserver contains everything
    LOG2=/vservers/${BASE}/log.txt
    (echo "==================== BEG VSERVER Transcript of vserver creation" ; \
	cat $LOG ; \
	echo "==================== END VSERVER Transcript of vserver creation" ; \
	echo "xxxxxxxxxx Messing with logs, symlinking $LOG2 to $LOG" ) >> $LOG2
    ### not too nice : nuke the former log, symlink it to the new one
    rm $LOG; ln -s $LOG2 $LOG
    LOG=$LOG2
    # redirect log again
    exec >> $LOG 2>&1 

    svn cat ${TESTSVNPATH}/selftest > /vservers/${BASE}/selftest
    vserver ${BASE} exec chmod +x /selftest
    vserver ${BASE} exec /selftest
    success 
}  

##########
main "$@" 
