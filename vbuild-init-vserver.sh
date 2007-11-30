#!/bin/bash
# -*-shell-*-

COMMAND=$(basename $0)
DIRNAME=$(dirname $0)

# lst parsing utilities
PATH=$(dirname $0):$PATH . build.common

function failure () {
    echo "$COMMAND : Bailing out"
    exit 1
}

# overwrite vserver's internal yum config from what is in
# .distributions/<distrib>/yum/yum.conf and /yum.repos.d 

function configure_yum_in_vserver () {
    set -x 
    set -e 
    trap failure ERR INT

    vserver=$1; shift
    fcdistro=$1; shift

    cd /etc/vservers/.distributions/${fcdistro}
    if [ -f yum/yum.conf ] ; then
	echo "Initializing yum.conf in $vserver from $(pwd)/yum"
        sed -e "s!@YUMETCDIR@!/etc!g;
                s!@YUMCACHEDIR@!/var/cache/yum!g;
                s!@YUMLOGDIR@!/var/log!g;
                s!@YUMLOCKDIR@!/var/lock!g;
               " yum/yum.conf > /vservers/$vserver/etc/yum.conf

	# post process the various @...@ variables from this yum.conf file.
    else
	echo "Using $fcdistro default for yum.conf"
    fi

    if [ -d yum.repos.d ] ; then
	echo "Initializing yum.repos.d in $vserver from $(pwd)/yum.repos.d"
	rm -rf /vservers/$vserver/etc/yum.repos.d
	tar cf - yum.repos.d | tar -C /vservers/$vserver/etc -xvf -
    else
	echo "Cannot initialize yum.repos.d in $vserver"
    fi

    if [ -n "$MYPLC_MODE" ] ; then
	if [ ! -d /vservers/$vserver/etc/yum.repos.d ] ; then
	    echo "WARNING : cannot create myplc repo"
	else
            # exclude kernel from fedora repos 
	    for i in /vservers/$vserver/etc/yum.repos.d/* ; do
		echo "exclude=kernel* ulogd iptables" >> $i
	    done
	    # the build repo is not signed at this stage
	    cat > /vservers/$vserver/etc/yum.repos.d/myplc.repo <<EOF
[myplc]
name= MyPLC
baseurl=$REPO_URL
enabled=1
gpgcheck=0
EOF
	fi
    fi
    cd -
}    

function setup_vserver () {

    set -x
    set -e
    trap failure ERR INT

    vserver=$1; shift
    fcdistro=$1; shift
    personality=$1; shift

    if [ -d /etc/vservers/$vserver ] ; then
	echo "$COMMAND : vserver $vserver seems to exist - bailing out"
	exit 1
    fi

    # create it
    $personality vserver $VERBOSE $vserver build -m yum -- -d $fcdistro

    if [ ! -z "$personality" ] ; then
	l32=$(grep $personality /etc/vservers/$vserver/personality | wc -l)
	[ $l32 -eq 0 ] && echo $personality >> /etc/vservers/$vserver/personality
    fi

    if [ -n "$VBUILD_MODE" ] ; then 
    # set up appropriate vserver capabilities to mount, mknod and IPC_LOCK
	BCAPFILE=/etc/vservers/$vserver/bcapabilities
	touch $BCAPFILE
	cap=$(grep ^CAP_SYS_ADMIN /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_SYS_ADMIN' >> /etc/vservers/$vserver/bcapabilities
	cap=$(grep ^CAP_MKNOD /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_MKNOD' >> /etc/vservers/$vserver/bcapabilities
	cap=$(grep ^CAP_IPC_LOCK /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_IPC_LOCK' >> /etc/vservers/$vserver/bcapabilities
    fi

    # start the vserver so we can do the following operations
    if [ $CLONED -eq 0 ] ; then
	$personality vyum $vserver -- -y install yum
	$personality vserver $VERBOSE $vserver pkgmgmt internalize
    fi
    $personality vserver $VERBOSE $vserver start
    $personality vserver $VERBOSE $vserver exec rm -f /var/lib/rpm/__db*
    $personality vserver $VERBOSE $vserver exec rpm --rebuilddb

    # minimal config in the vserver for yum to work
    configure_yum_in_vserver $vserver $fcdistro 

    # set up resolv.conf
    cp /etc/resolv.conf /vservers/$vserver/etc/resolv.conf
}

function devel_tools () {

    set -x 
    set -e 
    trap failure ERR INT

    vserver=$1; shift
    fcdistro=$1; shift
    pldistro=$1; shift
    personality=$1; shift

    # check for .lst file based on pldistro
    if [ -n "$VBUILD_MODE" ] ; then
	lst=${pldistro}-devel.lst
    else
	lst=${pldistro}-shell.lst
    fi
    if [ -f $lst ] ; then
	echo "$COMMAND: Using $lst"
    elif [ -f $DIRNAME/$lst ] ; then
	lst=$DIRNAME/$lst
	echo "$COMMAND: Using $lst"
    else
	echo "$COMMAND : Cannot locate $lst - exiting"
	usage
    fi

    # install individual packages, then groups
    packages=$(pl_getPackages2 ${fcdistro} $lst)
    groups=$(pl_getGroups2 ${fcdistro} $lst)

    [ -n "$packages" ] && $personality vserver $vserver exec yum -y install $packages
    [ -n "$groups" ] && $personality vserver $vserver exec yum -y groupinstall $groups
    return 0
}

function post_install () {
    if [ -n "$VBUILD_MODE" ] ; then
	post_install_vbuild "$@" 
    else
	post_install_myplc "$@"
    fi
}

function post_install_vbuild () {

    set -x 
    set -e 
    trap failure ERR INT

    vserver=$1; shift
    personality=$1; shift

### From myplc-devel-native.spec
# be careful to backslash $ in this, otherwise it's the root context that's going to do the evaluation
    cat << EOF | $personality vserver $VERBOSE $vserver exec bash -x
    # set up /dev/loop* in vserver
    for i in \$(seq 0 255) ; do
	mknod -m 640 /dev/loop\$i b 7 \$i
    done
    
    # create symlink for /dev/fd
    ln -fs /proc/self/fd /dev/fd

    # modify /etc/rpm/macros to not use /sbin/new-kernel-pkg
    sed -i 's,/sbin/new-kernel-pkg:,,' /etc/rpm/macros
    if [ -h "/sbin/new-kernel-pkg" ] ; then
	filename=\$(readlink -f /sbin/new-kernel-pkg)
	if [ "\$filename" == "/sbin/true" ] ; then
		echo "WARNING: /sbin/new-kernel-pkg symlinked to /sbin/true"
		echo "\tmost likely /etc/rpm/macros has /sbin/new-kernel-pkg declared in _netsharedpath."
		echo "\tPlease remove /sbin/new-kernel-pkg from _netsharedpath and reintall mkinitrd."
		exit 1
	fi
    fi
    
    # customize root's prompt
    cat << PROFILE > /root/.profile
export PS1="[$vserver] \\w # "
PROFILE

    uid=2000
    gid=2000
    
    # add a "build" user to the system
    builduser=\$(grep "^build:" /etc/passwd | wc -l)
    if [ \$builduser -eq 0 ] ; then
	groupadd -o -g \$gid build;
	useradd -o -c 'Automated Build' -u \$uid -g \$gid -n -M -s /bin/bash build;
    fi

# Allow build user to build certain RPMs as root
    if [ -f /etc/sudoers ] ; then
	buildsudo=\$(grep "^build.*ALL=(ALL).*NOPASSWD:.*ALL"  /etc/sudoers | wc -l)
	if [ \$buildsudo -eq 0 ] ; then
	    echo "build   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
	fi
        sed -i 's,^Defaults.*requiretty,#Defaults requiretty,' /etc/sudoers
    fi
#
EOF

}

function post_install_myplc  () {
    set -x 
    set -e 
    trap failure ERR INT

    vserver=$1; shift
    personality=$1; shift

# be careful to backslash $ in this, otherwise it's the root context that's going to do the evaluation
    cat << EOF | $personality vserver $VERBOSE $vserver exec bash -x

    # customize root's prompt
    cat << PROFILE > /root/.profile
export PS1="[$vserver] \\w # "
PROFILE

EOF
}

COMMAND_VBUILD="vbuild-init-vserver.sh"
COMMAND_MYPLC="myplc-init-vserver.sh"
function usage () {
    set +x 
    echo "Usage: $COMMAND_VBUILD [-s|s|p] [-v] vserver-name distribution pldistro [personality]"
    echo "Usage: $COMMAND_MYPLC [-s|s|p] [-v] vserver-name distribution pldistro repo-url [personality]"
    echo "Requirements: you need to have a vserver-compliant kernel,"
    echo "  as well as the util-vserver RPM installed"
    echo "Description:"
    echo "  This command creates a fresh vserver instance"
    echo "  . vserver-name : the vserver's name"
    echo "  . distribution : for creating the root filesystem, e.g. fc6"
    echo "  . pldistro: e.g. onelab"
    echo "  . repo-url: for myplc vserver, used to create a yum repository"
    echo "  . personality: last, optional, argument defaults to linux32"
    echo "This is done in three steps"
    echo " (*) setup phase : vserver creation, yum internalization and config (from /etc/vservers)"
    echo " (*) tools install the tools required for building are installed"
    echo "     based on the folowing file for the actual set of packages and groups"
    echo "     vbuild mode :  <pldistro>-devel.lst"
    echo "     myplc mode :   <pldistro>-shell.lst"
    echo " (*) post-install : various tunings required, as well as create a build user (vbuild only)"
    echo "Options:"
    echo " -s : skips the setup phase"
    echo " -t : skips the tools phase"
    echo " -p : skips the post-install"
    echo " -v : passes -v to calls to vserver"
    exit 1
}

### parse args and 
function main () {

    set -e
    trap failure ERR INT

    case "$COMMAND" in
	$COMMAND_VBUILD)
	    VBUILD_MODE=true ;;
	$COMMAND_MYPLC)
	    MYPLC_MODE=true;;
	*)
	    usage ;;
    esac

    DO_SETUP=true
    DO_TOOLS=true
    DO_POST=true
    VERBOSE=
    while getopts "stpvh" opt ; do
	case $opt in
	    s) DO_SETUP="" ;;
	    t) DO_TOOLS="" ;;
	    p) DO_POST="" ;;
	    v) VERBOSE="-v" ;;
	    h|*) usage ;;
	esac
    done
	
    shift $(($OPTIND - 1))
    
    [[ -z "$@" ]] && usage
    vserver=$1 ; shift
    [[ -z "$@" ]] && usage
    fcdistro=$1 ; shift
    [[ -z "$@" ]] && usage
    pldistro=$1 ; shift
    if [ -n "$MYPLC_MODE" ] ; then
	[[ -z "$@" ]] && usage
	REPO_URL=$1 ; shift
    fi
    if [[ -z "$@" ]] ; then
	personality=linux32
    else
	personality=$1; shift
    fi
    [[ -n "$@" ]] && usage

    [ -n "$DO_SETUP" ] && setup_vserver $vserver $fcdistro $personality 
    [ -n "$DO_TOOLS" ] && devel_tools $vserver $fcdistro $pldistro $personality
    [ -n "$DO_POST" ] && post_install $vserver $personality

}

main "$@"
