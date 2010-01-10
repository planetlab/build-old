#!/bin/bash
REVISION=$(echo '$Revision$' | sed -e 's,\$,,g' -e 's,^\w*:\s,,' )

COMMANDPATH=$0
COMMAND=$(basename $0)

# default values, tunable with command-line options
DEFAULT_FCDISTRO=centos5
DEFAULT_PLDISTRO=planetlab
DEFAULT_PERSONALITY=linux32
DEFAULT_BASE="@DATE@--@PLDISTRO@-@FCDISTRO@-@PERSONALITY@"
DEFAULT_build_SVNPATH="http://svn.planet-lab.org/svn/build/trunk"
DEFAULT_IFNAME=eth0

# default gpg path used in signing yum repo
DEFAULT_GPGPATH="/etc/planetlab"
# default email to use in gpg secring
DEFAULT_GPGUID="root@$( /bin/hostname )"

DEFAULT_TESTCONFIG="default"

# for publishing results, and the tests settings
x=$(hostname)
y=$(hostname|sed -e s,inria,,)
# INRIA defaults
if [ "$x" != "$y" ] ; then
    DEFAULT_WEBPATH="/build/@PLDISTRO@/"
    DEFAULT_TESTBUILDURL="http://build.onelab.eu/"
    # this is where the buildurl is pointing towards
    DEFAULT_WEBROOT="/build/"
    DEFAULT_TESTMASTER="testmaster.onelab.eu"
else
    DEFAULT_WEBPATH="/build/@FCDISTRO@/@PLDISTRO@/"
    DEFAULT_TESTBUILDURL="http://build.planet-lab.org/"
    # this is where the buildurl is pointing towards
    DEFAULT_WEBROOT="/build/"
    DEFAULT_TESTMASTER="manager.test.planet-lab.org"
fi    

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
m_show_line=re.compile(".* BEG (RPM|VSERVER).*|.*'boot'.*|\* .*| \* .*|.*is not installed.*|.*PROPFIND.*|.*Starting.*:run_log.*")
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

### we might build on a box other than the actual web server
# utilities for handling the pushed material (rpms, logfiles, ...)
function webpublish_misses_dir () { ssh root@${WEBHOST}  "bash -c \"test \! -d $1\"" ; }
function webpublish_remote () { ssh root@${WEBHOST} "$@" ; }
function webpublish_mkdir () { webpublish_remote mkdir "$@" ; }
function webpublish_rm () { webpublish_remote rm "$@" ; }
function webpublish_rsync_dir () { rsync --archive --delete $VERBOSE $1 root@${WEBHOST}:$2 ; }
function webpublish_rsync_file () { rsync $VERBOSE $1 root@${WEBHOST}:$2 ; }
function webpublish_cp_local_to_remote () { scp $1 root@${WEBHOST}:$2 ; }
function webpublish_cp_stdin_to_file () { ssh root@${WEBHOST} cat \> $1; }
function webpublish_append_stdin_to_file () { ssh root@${WEBHOST} cat \>\> $1; }

# Notify recipient of failure or success, manage various stamps 
function failure() {
    set -x
    # early stage ? - let's not create /build/@PLDISTRO@
    if webpublish_misses_dir ${WEBPATH} ; then
	WEBHOST=localhost
	WEBPATH=/tmp
	WEBLOG=/tmp/vbuild-early.log.txt
    fi
    webpublish_cp_local_to_remote $LOG ${WEBLOG}
    summary $LOG | webpublish_append_stdin_to_file ${WEBLOG}
    (echo -n "============================== $COMMAND: failure at " ; date ; \
	webpublish_remote tail --lines=1000 $WEBLOG) | \
	webpublish_cp_stdin_to_file ${WEBLOG}.ko
    if [ -n "$MAILTO" ] ; then
	( \
	    echo "See full build log at ${LOG_URL}" ; \
	    echo "and tail version at ${LOG_URL}.ko" ; \
	    echo "See complete set of testlogs at ${TESTLOGS_URL}" ; \
	    webpublish_remote tail --lines=1000 ${WEBLOG} ) | \
	    mail -s "Failures with ${MAIL_SUBJECT} ${BASE} on $(hostname)" $MAILTO
    fi
    exit 1
}

function success () {
    set -x
    # early stage ? - let's not create /build/@PLDISTRO@
    if webpublish_misses_dir ${WEBPATH} ; then
	WEBHOST=localhost
	WEBPATH=/tmp
	WEBLOG=/tmp/vbuild-early-$(date +%Y-%m-%d).log.txt
    fi
    webpublish_cp_local_to_remote $LOG ${WEBLOG}
    summary $LOG | webpublish_append_stdin_to_file ${WEBLOG}
    if [ -n "$DO_TEST" ] ; then
	( \
	    echo "Successfully built and tested" ; \
	    echo "See full build log at ${LOG_URL}" ; \
	    echo "See complete set of testlogs at ${TESTLOGS_URL}" ; \
	    ) | webpublish_cp_stdin_to_file ${WEBLOG}.pass
	webpublish_rm -f ${WEBLOG}.pkg-ok ${WEBLOG}.ko
    else
	( \
	    echo "Successful package-only build, no test requested" ; \
	    echo "See full build log at ${LOG_URL}" ; \
	    ) | webpublish_cp_stdin_to_file ${WEBLOG}.pkg-ok
	webpublish_rm -f ${WEBLOG}.ko
    fi
    if [ -n "$MAILTO" ] ; then
	( \
	    echo "$PLDISTRO ($BASE) build for $FCDISTRO completed on $(date)" ; \
	    echo "See full build log at ${LOG_URL}" ; \
            [ -n "$DO_TEST" ] && echo "See complete set of testlogs at ${TESTLOGS_URL}" ) \
	    | mail -s "Success with ${MAIL_SUBJECT} ${BASE} on $(hostname)" $MAILTO
    fi
    # XXX For some reason, we haven't been getting this email for successful builds. If this sleep
    # doesn't fix the problem, I'll remove it -- Sapan.
    sleep 5
    exit 0
}

# run in the vserver - do not manage success/failure, will be done from the root ctx
function build () {
    set -x
    set -e

    echo -n "============================== Starting $COMMAND:build on "
    date

    cd /build
    show_env
    
    echo "Running make IN $(pwd)"
    
    # stuff our own variable settings
    MAKEVARS=("PLDISTRO=${PLDISTRO}" "${MAKEVARS[@]}")
    MAKEVARS=("PLDISTROTAGS=${PLDISTROTAGS}" "${MAKEVARS[@]}")
    MAKEVARS=("build-SVNPATH=${build_SVNPATH}" "${MAKEVARS[@]}")
    MAKEVARS=("PERSONALITY=${PERSONALITY}" "${MAKEVARS[@]}")
    MAKEVARS=("MAILTO=${MAILTO}" "${MAKEVARS[@]}")
    MAKEVARS=("WEBPATH=${WEBPATH}" "${MAKEVARS[@]}")
    MAKEVARS=("TESTBUILDURL=${TESTBUILDURL}" "${MAKEVARS[@]}")
    MAKEVARS=("WEBROOT=${WEBROOT}" "${MAKEVARS[@]}")

    MAKEVARS=("BASE=${BASE}" "${MAKEVARS[@]}")

    # stage1
    make -C /build $DRY_RUN "${MAKEVARS[@]}" stage1=true 
    # store tests_svnpath
    make -C /build $DRY_RUN "${MAKEVARS[@]}" stage1=true tests_svnpath
    # versions
    make -C /build $DRY_RUN "${MAKEVARS[@]}" versions
    # actual stuff
    make -C /build $DRY_RUN "${MAKEVARS[@]}" "${MAKETARGETS[@]}"

}

# this was formerly run in the myplc-devel chroot but now is run in the root context,
# this is so that the .ssh config gets done manually, and once and for all
function run_log () {
    set -x
    set -e
    trap failure ERR INT

    echo -n "============================== Starting $COMMAND:run_log on $(date)"

    # where to find TESTS_SVNPATH
    stamp=/vservers/$BASE/build/tests_svnpath
    if [ ! -f $stamp ] ; then
	echo "$COMMAND: Cannot figure TESTS_SVNPATH from missing $stamp"
	failure
	exit 1
    fi
    TESTS_SVNPATH=$(cat $stamp)
    # don't need the tests fulltree anymore
    TESTS_SYSTEM_SVNPATH=${TESTS_SVNPATH}/system

    ### the URL to the RPMS/<arch> location
    # f12 now has everything in i686; try i386 first as older fedoras have both
    url=""
    for a in i386 i686 x86_64; do
	archdir=/vservers/$BASE/build/RPMS/$a
	if [ -d $archdir ] ; then
	    # where was that installed
	    url=$(echo $archdir | sed -e "s,/vservers/${BASE}/build,${WEBPATH}/${BASE},")
	    url=$(echo $url | sed -e "s,${WEBROOT},${TESTBUILDURL},")
	    break
	fi
    done

    if [ -z "$url" ] ; then
	echo "$COMMAND: Cannot locate arch URL for testing"
	failure
	exit 1
    fi

    testmaster_ssh="root@${TESTMASTER}"

    # test directory name on test box
    testdir=${BASE}
    # clean it
    ssh -n ${testmaster_ssh} rm -rf ${testdir}
    # check it out 
    ssh -n ${testmaster_ssh} svn co ${TESTS_SYSTEM_SVNPATH} ${testdir}
###    # check out the entire tests/ module (with system/ duplicated) as a subdir - see fulltree above
###    ssh -n ${testmaster_ssh} svn co ${TESTS_SVNPATH} ${testdir}/tests
    # invoke test on testbox - pass url and build url - so the tests can use vtest-init-vserver.sh
    configs=""
    for config in ${TESTCONFIG} ; do
	configs="$configs --config $config"
    done
    test_env="-p $PERSONALITY -d $PLDISTRO -f $FCDISTRO"

    # need to proceed despite of set -e
    success=true
    ssh 2>&1 -n ${testmaster_ssh} ${testdir}/run_log --build ${build_SVNPATH} --url ${url} $configs $test_env $VERBOSE --all || success=

    # gather logs in the vserver
    mkdir -p /vservers/$BASE/build/testlogs
    ssh 2>&1 -n ${testmaster_ssh} tar -C ${testdir}/logs -cf - . | tar -C /vservers/$BASE/build/testlogs -xf - || true
    # push them to the build web
    chmod -R a+r /vservers/$BASE/build/testlogs/
    webpublish_rsync_dir /vservers/$BASE/build/testlogs/ $WEBPATH/$BASE/testlogs/

    if [ -z "$success" ] ; then
	failure
    fi
    
    echo -n "============================== End $COMMAND:run_log on $(date)"
}

function in_root_context () {
    rpm -q util-vserver > /dev/null 
}

# this part won't work if WEBHOST does not match the local host
# would need to be made webpublish_* compliant
# but do we really need this feature anyway ?
function sign_node_packages () {

    echo "Signing node packages"
    
    need_createrepo=""

    repository=$WEBPATH/$BASE/RPMS/
    # the rpms that need signing
    new_rpms=
    # and the corresponding stamps
    new_stamps=

    for package in $(find $repository/ -name '*.rpm') ; do
        stamp=$repository/signed-stamps/$(basename $package).signed
        # If package is newer than signature stamp
        if [ $package -nt $stamp ] ; then
            new_rpms="$new_rpms $package"
            new_stamps="$new_stamps $stamp"
        fi
        # Or than createrepo database
        [ $package -nt $repository/repodata/repomd.xml ] && need_createrepo=true
    done

    if [ -n "$new_rpms" ] ; then
        # Create a stamp once the package gets signed
        mkdir $repository/signed-stamps 2> /dev/null
	
        # Sign RPMS. setsid detaches rpm from the terminal,
        # allowing the (hopefully blank) GPG password to be
        # entered from stdin instead of /dev/tty.
        echo | setsid rpm \
            --define "_signature gpg" \
            --define "_gpg_path $GPGPATH" \
            --define "_gpg_name $GPGUID" \
            --resign $new_rpms && touch $new_stamps
    fi

     # Update repository index / yum metadata. 
    if [ -n "$need_createrepo" ] ; then
	echo "Indexing node packages after signing"
        if [ -f $repository/yumgroups.xml ] ; then
            createrepo --quiet -g yumgroups.xml $repository
        else
            createrepo --quiet $repository
        fi
    fi
}

function show_env () {
    set +x
    echo FCDISTRO=$FCDISTRO
    echo PLDISTRO=$PLDISTRO
    echo PERSONALITY=$PERSONALITY
    echo BASE=$BASE
    echo build_SVNPATH=$build_SVNPATH
    echo MAKEVARS="${MAKEVARS[@]}"
    echo DRY_RUN="$DRY_RUN"
    echo PLDISTROTAGS="$PLDISTROTAGS"
    # this does not help, it's not yet set when we run show_env
    #echo WEBPATH="$WEBPATH"
    echo TESTBUILDURL="$TESTBUILDURL"
    echo WEBHOST="$WEBHOST"
    if in_root_context ; then
	echo PLDISTROTAGS="$PLDISTROTAGS"
    else
	if [ -f /build/$PLDISTROTAGS ] ; then
	    echo "XXXXXXXXXXXXXXXXXXXX Contents of tags definition file /build/$PLDISTROTAGS"
	    cat /build/$PLDISTROTAGS
	    echo "XXXXXXXXXXXXXXXXXXXX end tags definition"
	else
	    echo "XXXXXXXXXXXXXXXXXXXX Cannot find tags definition file /build/$PLDISTROTAGS, assuming remote pldistro"
	fi
    fi
    set -x
}

function setupssh () {
    base=$1; shift
    sshkey=$1; shift
    
    if [ -f ${sshkey} ] ; then
	SSHDIR=/vservers/${base}/root/.ssh
	mkdir -p ${SSHDIR}
	cp $sshkey ${SSHDIR}/thekey
	(echo "host *"; \
	    echo "  IdentityFile ~/.ssh/thekey"; \
	    echo "  StrictHostKeyChecking no" ) > ${SSHDIR}/config
	chmod 700 ${SSHDIR}
	chmod 400 ${SSHDIR}/*
    else 
	echo "WARNING : could not find provided ssh key $sshkey - ignored"
    fi
}

function usage () {
    echo "Usage: $COMMAND [option] [var=value...] make-targets"
    echo "This is $REVISION"
    echo "Supported options"
    echo " -f fcdistro - defaults to $DEFAULT_FCDISTRO"
    echo " -d pldistro - defaults to $DEFAULT_PLDISTRO"
    echo " -p personality - defaults to $DEFAULT_PERSONALITY"
    echo " -m mailto - no default"
    echo " -s svnpath - where to fetch the build module - defaults to $DEFAULT_build_SVNPATH"
    echo " -t pldistrotags - defaults to \${PLDISTRO}-tags.mk"
    echo " -b base - defaults to $DEFAULT_BASE"
    echo "    @NAME@ replaced as appropriate"
    echo " -o base: (overwrite) do not re-create vserver, re-use base instead"
    echo "    the -f/-d/-p/-m/-s/-t options are uneffective in this case"
    echo " -c testconfig - defaults to $DEFAULT_TESTCONFIG"
    echo " -w webpath - defaults to $DEFAULT_WEBPATH"
    echo " -W testbuildurl - defaults to $DEFAULT_TESTBUILDURL; this is also used to get the hostname where to publish builds"
    echo " -r webroot - defaults to $DEFAULT_WEBROOT - the fs point where testbuildurl actually sits"
    echo " -M testmaster - defaults to $DEFAULT_TESTMASTER"
    echo " -y - sign yum repo in webpath"
    echo " -g gpg_path - to the gpg secring used to sign rpms.  Defaults to $DEFAULT_GPGPATH" 
    echo " -u gpg_uid - email used in secring. Defaults to $DEFAULT_GPGUID"
    echo " -K svnsshkey - specify key to use when svn+ssh:// URLs are used for SVNPATH"
    echo " -S - do not publish source rpms"
    echo " -B - run build only"
    echo " -T - run test only"
    echo " -n - dry-run: -n passed to make - vserver gets created though - no mail sent"
    echo " -v - be verbose"
    echo " -7 - uses weekday-@FCDISTRO@ as base"
    echo " -i ifname - defaults to $DEFAULT_IFNAME - used to determine local IP"
    exit 1
}

function main () {

    set -e

    # parse arguments
    MAKEVARS=()
    MAKETARGETS=()
    DRY_RUN=
    DO_BUILD=true
    DO_TEST=true
    PUBLISH_SRPMS=true
    SSH_KEY=""
    SIGNYUMREPO=""
    while getopts "f:d:p:m:s:t:b:o:c:w:W:r:M:yg:u:K:SBTnv7i:" opt ; do
	case $opt in
	    f) FCDISTRO=$OPTARG ;;
	    d) PLDISTRO=$OPTARG ;;
	    p) PERSONALITY=$OPTARG ;;
	    m) MAILTO=$OPTARG ;;
	    s) build_SVNPATH=$OPTARG ;;
	    t) PLDISTROTAGS=$OPTARG ;;
	    b) BASE=$OPTARG ;;
	    o) OVERBASE=$OPTARG ;;
	    c) TESTCONFIG="$TESTCONFIG $OPTARG" ;;
	    w) WEBPATH=$OPTARG ;;
	    W) TESTBUILDURL=$OPTARG ;;
	    r) WEBROOT=$OPTARG ;;
	    M) TESTMASTER=$OPTARG ;;
            y) SIGNYUMREPO=true ;;
            g) GPGPATH=$OPTARG ;;
            u) GPGUID=$OPTARG ;;
	    K) SSH_KEY=$OPTARG ;;
	    S) PUBLISH_SRPMS="" ;;
	    B) DO_TEST= ;;
	    T) DO_BUILD= ;;
	    n) DRY_RUN="-n" ;;
	    v) set -x ; VERBOSE="-v" ;;
	    7) BASE="$(date +%a|tr A-Z a-z)-@FCDISTRO@" ;;
	    i) IFNAME=$OPTARG ;;
	    h|*) usage ;;
	esac
    done
	
    # preserve options for passing them again later, together with expanded base
    declare -a options
    toshift=$(($OPTIND - 1))
    arg=1; while [ $arg -le $toshift ] ; do options=(${options[@]} "$1") ; shift; arg=$(($arg+1)) ; done

    # allow var=value stuff; 
    for target in "$@" ; do
	# check if contains '='
	target1=$(echo $target | sed -e s,=,,)
	if [ "$target" = "$target1" ] ; then
	    MAKETARGETS=(${MAKETARGETS[@]} "$target")
	else
	    MAKEVARS=(${MAKEVARS[@]} "$target")
	fi
    done
    
    # set defaults
    [ -z "$FCDISTRO" ] && FCDISTRO=$DEFAULT_FCDISTRO
    [ -z "$PLDISTRO" ] && PLDISTRO=$DEFAULT_PLDISTRO
    [ -z "$PERSONALITY" ] && PERSONALITY=$DEFAULT_PERSONALITY
    [ -z "$PLDISTROTAGS" ] && PLDISTROTAGS="${PLDISTRO}-tags.mk"
    [ -z "$BASE" ] && BASE="$DEFAULT_BASE"
    [ -z "$WEBPATH" ] && WEBPATH="$DEFAULT_WEBPATH"
    [ -z "$TESTBUILDURL" ] && TESTBUILDURL="$DEFAULT_TESTBUILDURL"
    [ -z "$WEBROOT" ] && WEBROOT="$DEFAULT_WEBROOT"
    [ -z "$GPGPATH" ] && GPGPATH="$DEFAULT_GPGPATH"
    [ -z "$GPGUID" ] && GPGUID="$DEFAULT_GPGUID"
    [ -z "$IFNAME" ] && IFNAME="$DEFAULT_IFNAME"
    [ -z "$build_SVNPATH" ] && build_SVNPATH="$DEFAULT_build_SVNPATH"
    [ -z "$TESTCONFIG" ] && TESTCONFIG="$DEFAULT_TESTCONFIG"
    [ -z "$TESTMASTER" ] && TESTMASTER="$DEFAULT_TESTMASTER"

    [ -n "$DRY_RUN" ] && MAILTO=""
	
    if [ -n "$OVERBASE" ] ; then
	sedargs="-e s,@DATE@,${DATE},g"
	BASE=$(echo ${OVERBASE} | sed $sedargs)
    else
	sedargs="-e s,@DATE@,${DATE},g -e s,@FCDISTRO@,${FCDISTRO},g -e s,@PLDISTRO@,${PLDISTRO},g -e s,@PERSONALITY@,${PERSONALITY},g"
	BASE=$(echo ${BASE} | sed $sedargs)
    fi

    ### elaborate mail subject
    if [ -n "$DO_BUILD" -a -n "$DO_TEST" ] ; then
	MAIL_SUBJECT="complete"
    elif [ -n "$DO_BUILD" ] ; then
	MAIL_SUBJECT="package-only"
    elif [ -n "$DO_TEST" ] ; then
	MAIL_SUBJECT="test-only"
    fi
    if [ -n "$OVERBASE" ] ; then
	MAIL_SUBJECT="$MAIL_SUBJECT incremental run on"
    else
	MAIL_SUBJECT="$MAIL_SUBJECT fresh build"
    fi

    ### compute WEBHOST from TESTBUILDURL 
    # this is to avoid having to change the builds configs everywhere
    # simplistic way to extract hostname from a URL
    WEBHOST=$(echo "$TESTBUILDURL" | cut -d/ -f 3)

    if ! in_root_context ; then
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
	
	if [ -n "$OVERBASE" ] ; then
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
	    # start in case e.g. we just rebooted
	    vserver ${BASE} start || :
	    # update build
	    [ -n "$SSH_KEY" ] && setupssh ${BASE} ${SSH_KEY}
	    vserver ${BASE} exec svn update /build
	    # get environment from the first run 
	    FCDISTRO=$(vserver ${BASE} exec /build/getdistroname.sh)
	    # retrieve all in one run
	    tmp=/tmp/${BASE}-env.sh
	    vserver ${BASE} exec make --no-print-directory -C /build stage1=skip \
		++PLDISTRO ++PLDISTROTAGS ++PERSONALITY ++MAILTO ++WEBPATH ++TESTBUILDURL ++WEBROOT > $tmp
	    # sh vars cannot have a minus
	    echo build_SVNPATH=$(vserver ${BASE} exec make --no-print-directory -C /build stage1=skip +build-SVNPATH) >> $tmp
	    . $tmp
	    rm -f $tmp
	    options=(${options[@]} -d $PLDISTRO -t $PLDISTROTAGS -s $build_SVNPATH)
	    [ -n "$PERSONALITY" ] && options=(${options[@]} -p $PERSONALITY)
	    [ -n "$MAILTO" ] && options=(${options[@]} -m $MAILTO)
	    [ -n "$WEBPATH" ] && options=(${options[@]} -w $WEBPATH)
	    [ -n "$TESTBUILDURL" ] && options=(${options[@]} -W $TESTBUILDURL)
	    [ -n "$WEBROOT" ] && options=(${options[@]} -r $WEBROOT)
	    show_env
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
	    svn export $build_SVNPATH $tmpdir
            # Create vserver
	    cd $tmpdir
	    ./vbuild-init-vserver.sh $VERBOSE -f ${FCDISTRO} -d ${PLDISTRO} -p ${PERSONALITY} -i ${IFNAME} ${BASE} 
	    # cleanup
	    cd -
	    rm -rf $tmpdir
	    # Extract build again - in the vserver
	    [ -n "$SSH_KEY" ] && setupssh ${BASE} ${SSH_KEY}
	    vserver ${BASE} exec svn checkout ${build_SVNPATH} /build
	fi
	# install ssh key in vserver
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

	sedargs="-e s,@DATE@,${DATE},g -e s,@FCDISTRO@,${FCDISTRO},g -e s,@PLDISTRO@,${PLDISTRO},g -e s,@PERSONALITY@,${PERSONALITY},g"
	WEBPATH=$(echo ${WEBPATH} | sed $sedargs)
	webpublish_mkdir -p ${WEBPATH}

        # where to store the log for web access
	WEBLOG=${WEBPATH}/${BASE}.log.txt
        # compute the log URL - inserted in the mail messages for convenience
	LOG_URL=$(echo ${WEBLOG} | sed -e "s,//,/,g" -e "s,${WEBROOT},${TESTBUILDURL},")
	TESTLOGS_URL=$(echo ${WEBPATH}/${BASE}/testlogs | sed -e "s,//,/,g" -e "s,${WEBROOT},${TESTBUILDURL},")
    
	if [ -n "$DO_BUILD" ] ; then 

	    # invoke this command into the build directory of the vserver
	    cp $COMMANDPATH /vservers/${BASE}/build/

	    # invoke this command in the vserver for building (-T)
	    vserver ${BASE} exec chmod +x /build/$COMMAND
	    vserver ${BASE} exec /build/$COMMAND "${options[@]}" -b "${BASE}" "${MAKEVARS[@]}" "${MAKETARGETS[@]}"
	fi

	# publish to the web so run_log can find them
	webpublish_rm -rf $WEBPATH/$BASE ; webpublish_mkdir -p $WEBPATH/$BASE/{RPMS,SRPMS}
	webpublish_rsync_dir /vservers/$BASE/build/RPMS/ $WEBPATH/$BASE/RPMS/
	[[ -n "$PUBLISH_SRPMS" ]] && webpublish_rsync_dir /vservers/$BASE/build/SRPMS/ $WEBPATH/$BASE/SRPMS/
	# publish myplc-release if this exists
	release=/vservers/$BASE/build/myplc-release
	[ -f $release ] && webpublish_rsync_file $release $WEBPATH/$BASE

        # create yum repo and sign packages.
	if [ -n "$SIGNYUMREPO" ] ; then
	    # this script does not yet support signing on a remote (webhost) repo
	    sign_here=$(hostname) ; sign_web=$(webpublish_remote hostname)
	    if [ "$hostname" = "$sign_here" ] ; then
		sign_node_packages
	    else
		echo "$COMMAND does not support signing on a remote yum repo"
		echo "you might want to turn off the -y option, or run this on the web server box itself"
		exit 1
	    fi
	fi

	if [ -n "$DO_TEST" ] ; then 
	    run_log
	fi

	success 
	
    fi

}  

##########
main "$@" 
