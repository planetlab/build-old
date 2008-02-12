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

# web publishing results
DEFAULT_WEBPATH="/build/@PLDISTRO@/"

# for the test part
TESTBUILDURL="http://build.one-lab.org/"
TESTBOX=onelab-test.inria.fr
TESTBOXSSH=root@onelab-test.inria.fr
TESTSVNPATH="http://svn.planet-lab.org/svn/tests/tags/2008-02-11-last-vmware-support/system/"
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
    cp $LOG ${WEBLOG}
    summary $LOG >> ${WEBLOG}
    touch ${WEBLOG}.ok
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
    rpm=$( (cd /vservers/$BASE/build/RPMS/i386 ; ls myplc-[0-9]*.rpm) )
    if [ ${#rpm[@]} != 1 ] ; then
	echo "$COMMAND: Cannot locate rpm for testing"
	failure
	exit 1
    fi
    url=${TESTBUILDURL}${PLDISTRO}/${BASE}/RPMS/i386/${rpm}

    # compute test directory name on test box
    testdir=test-${BASE}
    # clean it
    ssh ${TESTBOXSSH} rm -rf ${testdir}
    # check it out
    ssh ${TESTBOXSSH} svn co ${TESTSVNPATH} ${testdir}
    # invoke test on testbox - pass url and build url - so the tests can use vtest-init-vserver.sh
    ssh 2>&1 ${TESTBOXSSH} python -u ${testdir}/runtest --build ${SVNPATH} --url ${url} --all
    # still missing - need to populate /var/www/html/install-rpms on the myplc
	
    if [ "$?" != 0 ] ; then
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
    echo " -B : run build only"
    echo " -T : run test only"
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
    DRY_RUN=
    DO_BUILD=true
    DO_TEST=true
    while getopts "nf:d:b:p:t:r:s:om:a:w:BTvh7" opt ; do
	case $opt in
	    n) DRY_RUN="-n" ;;
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
	    B) DO_TEST= ;;
	    T) DO_BUILD= ; OVERWRITEMODE=true ;;
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
	    ./vbuild-init-vserver.sh -f ${FCDISTRO} -d ${PLDISTRO} -p ${PERSONALITY} ${BASE}
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
	    vserver ${BASE} exec /build/$COMMAND "${argv[@]}" -b "${BASE}"
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
