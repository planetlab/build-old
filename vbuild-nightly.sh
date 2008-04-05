#!/bin/bash
REVISION=$(echo '$Revision$' | sed -e 's,\$,,g' -e 's,^\w*:\s,,' )

COMMANDPATH=$0
COMMAND=$(basename $0)

# default values, tunable with command-line options
DEFAULT_FCDISTRO=f8
DEFAULT_PLDISTRO=planetlab
DEFAULT_PERSONALITY=linux32
DEFAULT_BASE="@DATE@--@PLDISTRO@-@FCDISTRO@-@PERSONALITY@"
DEFAULT_SVNPATH="http://svn.planet-lab.org/svn/build/trunk"
DEFAULT_TESTSVNPATH="http://svn.planet-lab.org/svn/tests/trunk/system/"
DEFAULT_TESTCONFIG32="main 1vnodes 1testbox32"
DEFAULT_TESTCONFIG64="main 1vnodes 1testbox64"
DEFAULT_IFNAME=eth0

# web publishing results
DEFAULT_WEBPATH="/build/@PLDISTRO@/"

# for the test part
TESTBUILDURL="http://build.one-lab.org/"
TESTBOXSSH=root@testbox.one-lab.org
####################
# assuming vserver runs in UTC
DATE=$(date +'%Y.%m.%d')

# temporary - wrap a quick summary of suspicious stuff
# this is to focus on installation that go wrong
# use with care, a *lot* of other things can go bad as well
function summary () {
    from=$1; shift
    echo "******************** BEG SUMMARY" 
    python - $from <<EOF
#!/usr/bin/env python
# read a full log and tries to extract the interesting stuff

import sys,re
m_show_line=re.compile(".* BEG (RPM|VSERVER).*|.*'boot'.*|\* .*|.*is not installed.*")
m_installing_any=re.compile('\r  (Installing:[^\]]*]) ')
m_installing_err=re.compile('\r  (Installing:[^\]]*])(..+)')
m_installing_end=re.compile('Installed:.*')
m_installing_doc1=re.compile("(.*)install-info: No such file or directory for /usr/share/info/\S+(.*)")
m_installing_doc2=re.compile("(.*)grep: /usr/share/info/dir: No such file or directory(.*)")

def summary (filename):

    try:
        if filename=="-":
            filename="stdin"
            f=sys.stdin
        else:
            f=open(filename)
        echo=False
        for line in f.xreadlines():
            # first off : discard warnings related to doc
            if m_installing_doc1.match(line):
                (begin,end)=m_installing_doc1.match(line).groups()
                line=begin+end
            if m_installing_doc2.match(line):
                (begin,end)=m_installing_doc2.match(line).groups()
                line=begin+end
            # unconditionnally show these lines
            if m_show_line.match(line):
                print '>>>',line,
            # an 'installing' line with messages afterwards : needs to be echoed
            elif m_installing_err.match(line):
                (installing,error)=m_installing_err.match(line).groups()
                print '>>>',installing
                print '>>>',error
                echo=True
            # closing an 'installing' section
            elif m_installing_end.match(line):
                echo=False
            # any 'installing' line
            elif m_installing_any.match(line):
                if echo: 
                    installing=m_installing_any.match(line).group(1)
                    print '>>>',installing
                echo=False
            # print lines when echo is true
            else:
                if echo: print '>>>',line,
        f.close()
    except:
        print 'Failed to analyze',filename

for arg in sys.argv[1:]:
    summary(arg)
EOF
    echo "******************** END SUMMARY" 
}


# Notify recipient of failure or success, manage various stamps 
function failure() {
    set -x
    WEBLOG=${WEBPATH}/${BASE}.log.txt
    mkdir -p ${WEBPATH}
    cp $LOG ${WEBLOG}
    summary $LOG >> ${WEBLOG}
    (echo -n "============================== $COMMAND: failure at " ; date ; tail -c 20k $WEBLOG) > ${WEBLOG}.ko
    if [ -n "$MAILTO" ] ; then
	tail -c 20k ${WEBLOG} | mail -s "Failures for build ${BASE}" $MAILTO
    fi
    exit 1
}

function success () {
    set -x
    WEBLOG=${WEBPATH}/${BASE}.log.txt
    mkdir -p ${WEBPATH}
    cp $LOG ${WEBLOG}
    summary $LOG >> ${WEBLOG}
    if [ -n "DO_TEST" ] ; then
	echo "Successfully built and tested - see testlogs for details" > ${WEBLOG}.pass
	rm -f ${WEBLOG}.ok
    else
	echo "Successfully built"> ${WEBLOG}.ok
    fi
    if [ -n "$MAILTO" ] ; then
	(echo "$PLDISTRO ($BASE) build for $FCDISTRO completed on $(date)" ) | mail -s "Successful build for ${BASE}" $MAILTO
    fi
    exit 0
}

# run in the vserver - do not manage success/failure, will be done from the root ctx
function build () {
    set -x
    set -e

    echo -n "============================== Starting $COMMAND:build on "
    date

    cd /build
  # if TAGSRELEASE specified : update PLDISTROTAGS with this tag
    if [ -n "$TAGSRELEASE" ] ; then
	svn up -r $TAGSRELEASE $PLDISTROTAGS
    fi

    show_env
    
    echo "Running make IN $(pwd)"
    
    # stuff our own variable settings
    MAKEVARS=("PLDISTRO=${PLDISTRO}" "${MAKEVARS[@]}")
    MAKEVARS=("PLDISTROTAGS=${PLDISTROTAGS}" "${MAKEVARS[@]}")
    MAKEVARS=("NIGHTLY_BASE=${BASE}" "${MAKEVARS[@]}")
    MAKEVARS=("NIGHTLY_PERSONALITY=${PERSONALITY}" "${MAKEVARS[@]}")

    # stage1
    make -C /build $DRY_RUN "${MAKEVARS[@]}" stage1=true 
    # versions
    make -C /build $DRY_RUN "${MAKEVARS[@]}" versions
    # actual stuff
    make -C /build $DRY_RUN "${MAKEVARS[@]}" $MAKETARGETS

}

# this was formerly run in the myplc-devel chroot but now is run in the root context,
# this is so that the .ssh config gets done manually, and once and for all
function runtest () {
    set -x
    set -e
    trap failure ERR INT

    echo -n "============================== Starting $COMMAND:runtest on $(date)"

    ### the URL to the myplc package
    rpm=$( find /vservers/$BASE/build/RPMS -name 'myplc-[0-9]*' )
    if [ ${#rpm[@]} != 1 ] ; then
	echo "$COMMAND: Cannot locate rpm for testing"
	failure
	exit 1
    fi
    url=$(echo $rpm | sed -e "s,/vservers/$BASE/build,${TESTBUILDURL}${PLDISTRO}/${BASE},")

    # compute test directory name on test box
    testdir=chroot-${BASE}
    # use another name if any config contains vserver
    echo $TESTCONFIG | grep vserver &> /dev/null && testdir=vserver-${BASE}
    # clean it
    ssh ${TESTBOXSSH} rm -rf ${testdir}
    # check it out
    ssh ${TESTBOXSSH} svn co ${TESTSVNPATH} ${testdir}
    # invoke test on testbox - pass url and build url - so the tests can use vtest-init-vserver.sh
    configs=""
    for config in ${TESTCONFIG} ; do
	configs="$configs --config $config"
    done
    
    # need to proceed despite of set -e
    success=true
    ssh 2>&1 ${TESTBOXSSH} ${testdir}/runtest --build ${SVNPATH} --url ${url} $configs --all || success=

    # gather logs in the vserver
    mkdir -p /vservers/$BASE/build/testlogs
    ssh 2>&1 ${TESTBOXSSH} tar -C ${testdir}/logs -cf - . | tar -C /vservers/$BASE/build/testlogs -xf - || true
    # push them to the build web
    rsync --archive --delete /vservers/$BASE/build/testlogs/ $WEBPATH/$BASE/testlogs/
    chmod -R a+r $WEBPATH/$BASE/testlogs/

    if [ -z "$success" ] ; then
	failure
    fi
    
    echo -n "============================== End $COMMAND:runtest on $(date)"
}

function show_env () {
    set +x
    echo FCDISTRO=$FCDISTRO
    echo PLDISTRO=$PLDISTRO
    echo BASE=$BASE
    echo SVNPATH=$SVNPATH
    echo MAKEVARS="${MAKEVARS[@]}"
    echo DRY_RUN="$DRY_RUN"
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
    echo " -f fcdistro - defaults to $DEFAULT_FCDISTRO"
    echo " -d pldistro - defaults to $DEFAULT_PLDISTRO"
    echo " -p personality - defaults to $DEFAULT_PERSONALITY"
    echo " -b base - defaults to $DEFAULT_BASE"
    echo "    @NAME@ replaced as appropriate"
    echo " -t pldistrotags - defaults to \${PLDISTRO}-tags.mk"
    echo " -r tagsrelease - a release number that refers to PLDISTROTAGS - defaults to HEAD"
    echo " -s svnpath - where to fetch the build module"
    echo " -x testsvnpath - defaults to $DEFAULT_TESTSVNPATH"
    echo " -c testconfig - defaults to $DEFAULT_TESTCONFIG32 or $DEFAULT_TESTCONFIG64"
    echo " -w webpath - defaults to $DEFAULT_WEBPATH"
    echo " -m mailto - no default"
    echo " -O : overwrite - re-run in base directory, do not re-create vserver"
    echo " -B : run build only"
    echo " -T : run test only"
    echo " -n dry-run : -n passed to make - vserver gets created though - no mail sent"
    echo " -v : be verbose"
    echo " -7 : uses weekday-@FCDISTRO@ as base"
    echo " -a makevar=value - space in values are not supported"
    echo " -i ifname - defaults to $DEFAULT_IFNAME - used to determine local IP"
    exit 1
}

function main () {

    set -e

    # parse arguments
    MAKEVARS=()
    DRY_RUN=
    DO_BUILD=true
    DO_TEST=true
    while getopts "f:d:p:b:t:r:s:x:c:w:m:OBTnv7a:i:" opt ; do
	case $opt in
	    f) FCDISTRO=$OPTARG ;;
	    d) PLDISTRO=$OPTARG ;;
	    p) PERSONALITY=$OPTARG ;;
	    b) BASE=$OPTARG ;;
	    t) PLDISTROTAGS=$OPTARG ;;
	    r) TAGSRELEASE=$OPTARG ;;
	    s) SVNPATH=$OPTARG ;;
	    x) TESTSVNPATH=$OPTARG ;;
	    c) TESTCONFIG="$TESTCONFIG $OPTARG" ;;
	    w) WEBPATH=$OPTARG ;;
	    m) MAILTO=$OPTARG ;;
	    O) OVERWRITEMODE=true ;;
	    B) DO_TEST= ;;
	    T) DO_BUILD= ; OVERWRITEMODE=true ;;
	    n) DRY_RUN="-n" ;;
	    v) set -x ;;
	    7) BASE="$(date +%a|tr A-Z a-z)-@FCDISTRO@" ;;
	    a) MAKEVARS=(${MAKEVARS[@]} "$OPTARG") ;;
	    i) IFNAME=$OPTARG ;;
	    h|*) usage ;;
	esac
    done
	
    # preserve options for passing them again later, together with expanded base
    declare -a options
    toshift=$(($OPTIND - 1))
    arg=1; while [ $arg -le $toshift ] ; do options=(${options[@]} "$1") ; shift; arg=$(($arg+1)) ; done

    MAKETARGETS="$@"
    
    # set defaults
    [ -z "$FCDISTRO" ] && FCDISTRO=$DEFAULT_FCDISTRO
    [ -z "$PLDISTRO" ] && PLDISTRO=$DEFAULT_PLDISTRO
    [ -z "$PERSONALITY" ] && PERSONALITY=$DEFAULT_PERSONALITY
    [ -z "$PLDISTROTAGS" ] && PLDISTROTAGS="${PLDISTRO}-tags.mk"
    [ -z "$BASE" ] && BASE="$DEFAULT_BASE"
    [ -z "$WEBPATH" ] && WEBPATH="$DEFAULT_WEBPATH"
    [ -z "$IFNAME" ] && IFNAME="$DEFAULT_IFNAME"
    [ -z "$SVNPATH" ] && SVNPATH="$DEFAULT_SVNPATH"
    [ -z "$TESTSVNPATH" ] && TESTSVNPATH="$DEFAULT_TESTSVNPATH"
    [ "$PERSONALITY" == linux32 ] && [ -z "$TESTCONFIG" ] && TESTCONFIG="$DEFAULT_TESTCONFIG32"
    [ "$PERSONALITY" == linux64 ] && [ -z "$TESTCONFIG" ] && TESTCONFIG="$DEFAULT_TESTCONFIG64"

    [ -n "$DRY_RUN" ] && MAILTO=""
	
    ### set BASE from DISTRO, if unspecified
    sedargs="-e s,@DATE@,${DATE},g -e s,@FCDISTRO@,${FCDISTRO},g -e s,@PLDISTRO@,${PLDISTRO},g -e s,@PERSONALITY@,${PERSONALITY},g"
    BASE=$(echo ${BASE} | sed $sedargs)
    WEBPATH=$(echo ${WEBPATH} | sed $sedargs)

    if [ ! -d /vservers ] ; then
        # in the vserver
	echo "==================== Within vserver BEG $(date)"
	build
	echo "==================== Within vserver END $(date)"

    else
	trap failure ERR INT
        # we run in the root context : 
        # (*) create or check for the vserver to use
        # (*) copy this command in the vserver
        # (*) invoke it
	
	if [ -n "$OVERWRITEMODE" ] ; then
            ### Re-use a vserver (finish an unfinished build..)
	    if [ ! -d /vservers/${BASE} ] ; then
		echo $COMMAND : cannot find vserver $BASE
		exit 1
	    fi
	    # manage LOG - beware it might be a symlink so nuke it first
	    LOG=/vservers/${BASE}.log.txt
	    rm -f $LOG
	    exec > $LOG 2>&1
	    set -x
	    echo "XXXXXXXXXX $COMMAND: using existing vserver $BASE" $(date)
	    show_env
	    # update build
	    vserver ${BASE} exec svn update /build
	else
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
	    ./vbuild-init-vserver.sh -f ${FCDISTRO} -d ${PLDISTRO} -p ${PERSONALITY} -i ${IFNAME} ${BASE} 
	    # cleanup
	    cd -
	    rm -rf $tmpdir
	    # Extract build again - in the vserver
	    vserver ${BASE} exec svn checkout ${SVNPATH} /build
	fi
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

	if [ -n "$DO_BUILD" ] ; then 

	    cp $COMMANDPATH /vservers/${BASE}/build/

	    # invoke this command in the vserver for building (-T)
	    vserver ${BASE} exec chmod +x /build/$COMMAND
	    vserver ${BASE} exec /build/$COMMAND "${options[@]}" -b "${BASE}" $MAKETARGETS
	fi

	# publish to the web so runtest can find them
	rm -rf $WEBPATH/$BASE ; mkdir -p $WEBPATH/$BASE/{RPMS,SRPMS}
	rsync --archive --delete --verbose /vservers/$BASE/build/RPMS/ $WEBPATH/$BASE/RPMS/
	rsync --archive --delete --verbose /vservers/$BASE/build/SRPMS/ $WEBPATH/$BASE/SRPMS/
	
	if [ -n "$DO_TEST" ] ; then 
	    runtest
	fi

	success 
	
    fi

}  

##########
main "$@" 
