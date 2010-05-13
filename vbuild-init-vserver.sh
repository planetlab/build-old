#!/bin/bash
# -*-shell-*-
# $Id$

#shopt -s huponexit

COMMAND=$(basename $0)
DIRNAME=$(dirname $0)

# pkgs parsing utilities
PATH=$(dirname $0):$PATH export PATH
. build.common

DEFAULT_FCDISTRO=f8
DEFAULT_PLDISTRO=planetlab
DEFAULT_PERSONALITY=linux32
DEFAULT_IFNAME=eth0

COMMAND_VBUILD="vbuild-init-vserver.sh"
COMMAND_MYPLC="vtest-init-vserver.sh"

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

    templates=/etc/vservers/.distributions/${fcdistro}
    if [ -f ${templates}/yum/yum.conf ] ; then
	echo "Initializing yum.conf in $vserver from ${templates}/yum"
        sed -e "s!@YUMETCDIR@!/etc!g;
                s!@YUMCACHEDIR@!/var/cache/yum!g;
                s!@YUMLOGDIR@!/var/log!g;
                s!@YUMLOCKDIR@!/var/lock!g;
               " ${templates}/yum/yum.conf > /vservers/$vserver/etc/yum.conf

	# post process the various @...@ variables from this yum.conf file.
    else
	echo "Using $fcdistro default for yum.conf"
    fi

    if [ -d ${templates}/yum.repos.d ] ; then
	echo "Initializing yum.repos.d in $vserver from ${templates}/yum.repos.d"
	rm -rf /vservers/$vserver/etc/yum.repos.d
	tar -C ${templates} -cf - yum.repos.d | tar -C /vservers/$vserver/etc -xvf -
    else
	echo "Cannot initialize yum.repos.d in $vserver"
    fi

    # for using vtest-init-vserver.sh as a general-purpose vserver creation wrapper
    # just mention 'none' as the repo url
    if [ -n "$MYPLC_MODE" -a "$REPO_URL" != "none" ] ; then
	if [ ! -d /vservers/$vserver/etc/yum.repos.d ] ; then
	    echo "WARNING : cannot create myplc repo"
	else
            # exclude kernel from fedora repos 
	    for repo in /vservers/$vserver/etc/yum.repos.d/* ; do
		[ -f $repo ] && yumconf_exclude $repo "exclude=$pl_KEXCLUDES" 
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
}    

# return yum or debootstrap
function package_method () {
    fcdistro=$1; shift
    case $fcdistro in
	f[0-9]*|centos[0-9]*) echo yum ;;
	lenny|etch) echo debootstrap ;;
	*) echo Unknown distro $fcdistro ;;
    esac 
}

# return arch from debian distro and personality
function canonical_arch () {
    personality=$1; shift
    fcdistro=$1; shift
    case $(package_method $fcdistro) in
	yum)
	    case $personality in *32) echo i386 ;; *64) echo x86_64 ;; *) echo Unknown-arch-1 ;; esac ;;
	debootstrap)
	    case $personality in *32) echo i386 ;; *64) echo amd64 ;; *) echo Unknown-arch-2 ;; esac ;;
	*)
	    echo Unknown-arch-3 ;;
    esac
}

function setup_vserver () {

    set -x
    set -e
    trap failure ERR INT

    vserver=$1; shift
    fcdistro=$1; shift
    personality=$1; shift

    if [ -d /vservers/$vserver ] ; then
	echo "$COMMAND : vserver $vserver seems to exist - bailing out"
	exit 1
    fi

    pkg_method=$(package_method $fcdistro)
    case $pkg_method in
	yum)
	    build_options="-m yum -- -d $fcdistro" 
	    ;;
	debootstrap)
	    arch=$(canonical_arch $personality $fcdistro)
	    build_options="-m debootstrap -- -d $fcdistro -- --arch $arch"
	    ;;
	*)
	    build_options="something wrong" ;;
    esac

    # create it
    # try to work around the vserver issue:
    # vc_ctx_migrate: No such process
    # rpm-fake.so: failed to initialize communication with resolver
    for i in $(seq 20) ; do
	$personality vserver $VERBOSE $vserver build $VSERVER_OPTIONS $build_options && break || true
	echo "* ${i}-th attempt to 'vserver build' failed - waiting for 3 seconds"
	sleep 3
    done
    # check success
    [ -d /vservers/$vserver ] 

    if [ ! -z "$personality" ] ; then
	if [ -f "/etc/vservers/$vserver/personality" ] ; then
	    registered_personality=$(grep $personality /etc/vservers/$vserver/personality | wc -l)
	else
	    registered_personality=0
	fi
	if [ $registered_personality -eq 0 -a "$personality" != "linux64" ] ; then
	    echo $personality >> /etc/vservers/$vserver/personality
	fi
    fi

    if [ -n "$VBUILD_MODE" ] ; then 
	### capabilities required for a build vserver
        # set up appropriate vserver capabilities to mount, mknod and IPC_LOCK
	BCAPFILE=/etc/vservers/$vserver/bcapabilities
	touch $BCAPFILE
	cap=$(grep ^CAP_SYS_ADMIN /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_SYS_ADMIN' >> /etc/vservers/$vserver/bcapabilities
	cap=$(grep ^CAP_MKNOD /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_MKNOD' >> /etc/vservers/$vserver/bcapabilities
	cap=$(grep ^CAP_IPC_LOCK /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_IPC_LOCK' >> /etc/vservers/$vserver/bcapabilities
    else
	### capabilities required for a myplc vserver
	# for /etc/plc.d/gpg - need to init /dev/random
	cap=$(grep ^CAP_MKNOD /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_MKNOD' >> /etc/vservers/$vserver/bcapabilities
	cap=$(grep ^CAP_NET_BIND_SERVICE /etc/vservers/$vserver/bcapabilities | wc -l)
	[ $cap -eq 0 ] && echo 'CAP_NET_BIND_SERVICE' >> /etc/vservers/$vserver/bcapabilities
    fi

    # Set persistent for the network context
    echo persistent,lback_allow > /etc/vservers/$vserver/nflags
 
    if [ "$pkg_method" = "yum" ] ; then
	$personality vyum $vserver -- -y install yum
        # ditto
	for i in $(seq 20) ; do
	    $personality vserver $VERBOSE $vserver pkgmgmt internalize && break || true
	    echo "* ${i}-th attempt to 'vserver pkgmgmt internalize' failed - waiting for 3 seconds"
	    sleep 3
	done
    fi

    # start the vserver so we can do the following operations
    # redirect out/err to protect against the vserver's init sequence getting stalled 
    # mostly used for f10 vservers created remotely through ssh
    $personality vserver $VERBOSE $vserver start >& /dev/null

    if [ "$pkg_method" == "yum" ] ; then
	$personality vserver $VERBOSE $vserver exec sh -c "rm -f /var/lib/rpm/__db*"

	# run the host rpmdb_dump and restore with the guest rpmdb_load
	function translate_rpm_hashes () {
	    set -x
	    set -e
	    local personality="$1"; shift
	    local vserver="$1"; shift
	    # need to have utilities installed
	    type -p file
	    type -p awk
	    type -p cut
	    guest_dir=/var/lib/rpm
	    host_dir=/vservers/$vserver/$guest_dir
	    files=$(cd $host_dir ; file * | grep Hash | cut -d: -f 1)
	    for file in $files; do
		(cd $host_dir && mv $file ${file}-foreign)
		/usr/lib/rpm/rpmdb_dump $host_dir/${file}-foreign | $personality vserver $VERBOSE $vserver exec /usr/lib/rpm/rpmdb_load $guest_dir/$file
	    done
	    $personality vserver $VERBOSE $vserver exec rpm --rebuilddb
	    return 0
	}

	# try the simple way, if that fails try to cross fix the rpm hashes
	$personality vserver $VERBOSE $vserver exec rpm --rebuilddb || translate_rpm_hashes $personality $vserver
    fi

    # check if the vserver kernel is using VSERVER_DEVICE (vdevmap) support
    need_vdevmap=$(grep "CONFIG_VSERVER_DEVICE=y" /boot/config-$(uname -r) | wc -l)

    if [ $need_vdevmap -eq 1 ] ; then
	ctx=$(cat /etc/vservers/$vserver/context)
	vdevmap --set --xid $ctx --open --create --target /dev/null
	vdevmap --set --xid $ctx --open --create --target /dev/root
    fi
	    
    # minimal config in the vserver for yum to work
    [ "$pkg_method" = "yum" ] && configure_yum_in_vserver $vserver $fcdistro 

    # set up resolv.conf
    cp /etc/resolv.conf /vservers/$vserver/etc/resolv.conf
    # and /etc/hosts for at least localhost
    [ -f /vservers/$vserver/etc/hosts ] || echo "127.0.0.1 localhost localhost.localdomain" > /vservers/$vserver/etc/hosts

}

function devel_or_vtest_tools () {

    set -x 
    set -e 
    trap failure ERR INT

    vserver=$1; shift
    fcdistro=$1; shift
    pldistro=$1; shift
    personality=$1; shift

    pkg_method=$(package_method $fcdistro)

    # check for .pkgs file based on pldistro
    if [ -n "$VBUILD_MODE" ] ; then
	pkgsname=devel.pkgs
    else
	pkgsname=vtest.pkgs
    fi
    pkgsfile=$(pl_locateDistroFile $DIRNAME $pldistro $pkgsname)

    ### install individual packages, then groups
    # get target arch - use uname -i here (we want either x86_64 or i386)
    vserver_arch=$($personality vserver $vserver exec uname -i)
    # on debian systems we get arch through the 'arch' command
    [ "$vserver_arch" = "unknown" ] && vserver_arch=$($personality vserver $vserver exec arch)
    
    packages=$(pl_getPackages -a $vserver_arch $fcdistro $pldistro $pkgsfile)
    groups=$(pl_getGroups -a $vserver_arch $fcdistro $pldistro $pkgsfile)

    [ "$pkg_method" = yum ] && [ -n "$packages" ] && $personality vserver $vserver exec yum -y install $packages
    [ "$pkg_method" = yum ] && for group_plus in $groups; do
	group=$(echo $group_plus | sed -e "s,+++, ,g")
        $personality vserver $vserver exec yum -y groupinstall "$group"
    done

    [ "$pkg_method" = debootstrap ] && $personality vserver $vserver exec apt-get update
    [ "$pkg_method" = debootstrap ] && for package in $packages ; do 
	$personality vserver $vserver exec apt-get install -y $package 
    done
    
    return 0
}

function post_install () {
    if [ -n "$VBUILD_MODE" ] ; then
	post_install_vbuild "$@" 
    else
	post_install_myplc "$@"
    fi
    # setup localtime from the host
    vserver=$1; shift 
    cp /etc/localtime /vservers/$vserver/etc/localtime
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
    [ ! -e "/dev/fd" ] && ln -s /proc/self/fd /dev/fd

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

    # create /etc/sysconfig/network if missing
    [ -f /etc/sysconfig/network ] || echo NETWORKING=yes > /etc/sysconfig/network

    # create symlink for /dev/fd
    [ ! -e "/dev/fd" ] && ln -s /proc/self/fd /dev/fd

    # turn off regular crond, as plc invokes plc_crond
    chkconfig crond off

    # take care of loginuid in /etc/pam.d 
    sed -i "s,#*\(.*loginuid.*\),#\1," /etc/pam.d/*

    # customize root's prompt
    cat << PROFILE > /root/.profile
export PS1="[$vserver] \\w # "
PROFILE

EOF
}

# parses ifconfig's output to find out ip address and mask
# will then be passed to vserver as e.g. --interface 138.96.250.126/255.255.0.0
# default is to use lo, that's enough for local mirrors
# use -i eth0 in case your fedora mirror is on a separate box on the network
function vserverIfconfig () {
    ifname=$1; shift
    local result="" 
    line=$(ifconfig $ifname 2> /dev/null | grep 'inet addr')
    if [ -n "$line" ] ; then
	set $line
	for word in "$@" ; do
	    addr=$(echo $word | sed -e s,[aA][dD][dD][rR]:,,)
	    mask=$(echo $word | sed -e s,[mM][aA][sS][kK]:,,)
	    if [ "$word" != "$addr" ] ; then
		result="${addr}"
	    elif [ "$word" != "$mask" ] ; then
		result="${result}/${mask}"
	    fi
	done
    fi
    if [ -z "$result" ] ; then 
	echo "vserverIfconfig failed to locate $ifname"
	exit 1
    else
	echo $result
    fi
}

function usage () {
    set +x 
    echo "Usage: $COMMAND_VBUILD [options] vserver-name [ -- vserver-options ]"
    echo "Usage: $COMMAND_MYPLC [options] vserver-name repo-url [ -- vserver-options ]"
    echo "Requirements: you need to have a vserver-compliant kernel,"
    echo "   as well as the util-vserver RPM installed"
    echo "Description:"
    echo "   This command creates a fresh vserver instance, for building, or running, myplc"
    echo "Supported options"
    echo " -f fcdistro - for creating the root filesystem - defaults to $DEFAULT_FCDISTRO"
    echo " -d pldistro - defaults to $DEFAULT_PLDISTRO"
    echo " -p personality - defaults to $DEFAULT_PERSONALITY"
    echo " -i ifname: determines ip and netmask attached to ifname, and passes it to the vserver"
    echo " -v : verbose - passes -v to calls to vserver"
    echo "vserver-options"
    echo "  all args after the optional -- are passed to vserver <name> build <options>"
    echo "  typical usage is e.g. --interface eth0:200.150.100.10/24"
    echo "With $COMMAND_MYPLC you can give 'none' as the URL, in which case"
    echo "   myplc.repo does not get created"
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

    VERBOSE=
    IFNAME=""
    VSERVER_OPTIONS=""
    while getopts "f:d:p:i:v" opt ; do
	case $opt in
	    f) fcdistro=$OPTARG;;
	    d) pldistro=$OPTARG;;
	    p) personality=$OPTARG;;
	    i) IFNAME=$OPTARG;;
	    v) VERBOSE="-v" ;;
	    *) usage ;;
	esac
    done
	
    shift $(($OPTIND - 1))

    # parse fixed arguments
    [[ -z "$@" ]] && usage
    vserver=$1 ; shift
    if [ -n "$MYPLC_MODE" ] ; then
	[[ -z "$@" ]] && usage
	REPO_URL=$1 ; shift
    fi

    # parse vserver options
    if [[ -n "$@" ]] ; then
	if [ "$1" == "--" ] ; then
	    shift
	    VSERVER_OPTIONS="$@"
	else
	    usage
	fi
    fi

    # with new util-vserver, it is mandatory to provide an IP even for building
    if [ -n "$VBUILD_MODE" ] ; then
	[ -z "$IFNAME" ] && IFNAME=$DEFAULT_IFNAME
    fi
    if [ -n "$IFNAME" ] ; then
	localip=$(vserverIfconfig $IFNAME)
	VSERVER_OPTIONS="$VSERVER_OPTIONS --interface $localip"
    fi

    [ -z "$fcdistro" ] && fcdistro=$DEFAULT_FCDISTRO
    [ -z "$pldistro" ] && pldistro=$DEFAULT_PLDISTRO
    [ -z "$personality" ] && personality=$DEFAULT_PERSONALITY

    setup_vserver $vserver $fcdistro $personality 
    devel_or_vtest_tools $vserver $fcdistro $pldistro $personality
    post_install $vserver $personality

}

main "$@"
