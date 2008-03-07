#!/bin/bash
# this can help you create/update your fedora mirror
# $Id$

COMMAND=$(basename $0)

dry_run=
verbose=
skip_core=
root=/data/fedora/linux

us_rsyncurl=rsync://mirrors.kernel.org/fedora
eu_rsyncurl=rsync://ftp-stud.hs-esslingen.de/fedora/linux
# change this
jp_rsyncurl=rsync://ftp-stud.hs-esslingen.de/fedora/linux

default_distroname=f8
all_distronames="f7 f8"
default_arch=i386
all_archs="i386 x86_64"

case $(hostname) in 
    *.fr|*.de|*.uk)
	rsyncurl=$eu_rsyncurl ;;
    *.jp)
	rsyncurl=$jp_rsyncurl ;;
    *)
	rsyncurl=$us_rsyncurl ;;
esac

function usage () {
    echo "Usage: $COMMAND [-n] [-v] [-c] [-r root] [-u rsyncurl|-e] [-f distroname|-F] [-a arch|-A]"
    echo "Defaults to -r $root -u $rsyncurl -f $default_distroname -a $default_arch"
    echo "Options:"
    echo " -n : dry run"
    echo " -v : verbose"
    echo " -c : skips core repository"
    echo " -r root (default is $root)"
    echo " -u rsyncurl (default is $rsyncurl)"
    echo " -e : uses European mirror $eu_rsyncurl"
    echo " -f distroname - use vserver convention, e.g. fc6 and f7"
    echo " -F : for distroname in $all_distronames"
    echo " -a arch - use yum convention"
    echo " -A : for arch in $all_archs"
    exit 1
}

function mirror_distro_arch () {
    distroname=$1; shift
    arch=$1; shift

    case $distroname in
	fc*[1-6])
    	    distroindex=$(echo $distroname | sed -e "s,fc,,g")
	    distro="Fedora Core"
	    ;;
	f*[7-8])
	    distroindex=$(echo $distroname | sed -e "s,f,,g")
	    distro="Fedora"
	    ;;
	centos*[4-5])
	    distroindex=$(echo $distroname | sed -e "s,centos,,g")
	    distro="CentOS"
	    ;;
	*)
	    echo "Unknown distribution $distroname - skipped"
	    ;;
    esac

    excludelist="debug/ iso/ ppc/ source/"
    options="--archive --compress --delete --delete-excluded $dry_run $verbose"
    [ -n "$(rsync --help | grep no-motd)" ] && options="$options --no-motd"
    for e in $excludelist; do
	options="$options --exclude $e"
    done

    if [ -n "$verbose" ] ; then 
	echo "root=$root"
	echo "distro=$distroname"
	echo "distroname=$distroname"
	echo "distroindex=$distroindex"
	echo "arch=$arch"
	echo rsyncurl="$rsyncurl"
	echo "rsync options=$options"
    fi

    RES=1
    paths=""
    case $distro in
	[Ff]edora*)
            case $distroindex in
		2|4|6)
		    [ -z "$skip_core" ] && paths="core/$distroindex/$arch/os/"
		    paths="$paths core/updates/$distroindex/$arch/ extras/$distroindex/$arch/"
		    RES=0
		    ;;
		7|8)
		    [ -z "$skip_core" ] && paths="releases/$distroindex/Everything/$arch/os/"
		    paths="$paths updates/$distroindex/$arch/"
		    RES=0
		    ;;
	    esac
	    ;;
    
	CentOS*)
	    case $distroindex in
		5)
		    [ -z "$skip_core" ] && paths="$distroindex/os/$arch/"
		    paths="$paths $distroindex/updates/$arch/"
		    RES=0
		    ;;
	    esac
	    ;;

    esac

    if [ "$RES" = 1 ] ; then
	echo "$distro $distroindex currently unsupported - skipped"
    else
	for repopath in $paths; do
	    echo "============================== $distro -> $distroindex $repopath"
	    [ -z "$dry_run" ] && mkdir -p ${root}/${repopath}
	    command="rsync $options ${rsyncurl}/${repopath} ${root}/${repopath}"
	    echo $command
	    $command
	done
    fi

    return $RES 
}

function main () {
    distronames=""
    archs=""
    while getopts "nvcr:u:ef:Fa:Ah" opt ; do
	case $opt in
	    n) dry_run=--dry-run ; verbose=--verbose ;;
	    v) verbose=--verbose ;;
	    c) skip_core=true ;;
	    r) root=$OPTARG ;;
	    u) rsyncurl=$OPTARG ;;
	    e) rsyncurl=$eu_rsyncurl ;;
	    f) distronames="$distronames $OPTARG" ;;
	    F) distronames="$distronames $all_distronames" ;;
	    a) archs="$archs $OPTARG" ;;
	    A) archs="$archs $all_archs" ;;
	    h|*) usage ;;
	esac
    done
    [ -z "$distronames" ] && distronames=$default_distroname
    [ -z "$archs" ] && archs=$default_arch

    RES=0
    for arch in $archs; do 
	for distroname in $distronames ; do 
	    mirror_distro_arch "$distroname" "$arch" || RES=1
	done
    done

    exit $RES
}

main "$@"
