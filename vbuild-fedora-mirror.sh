#!/bin/bash
# this can help you create/update your fedora mirror
# $Id$

COMMAND=$(basename $0)

dry_run=
verbose=
skip_core=
root=/data/fedora/linux
rsyncurl=rsync://mirrors.kernel.org/fedora
distroname=f8
arch=i386


function usage () {
    echo "Usage: $COMMAND [-n] [-v] [-c] [-r root] [-u rsyncurl] [-f distroname] [-a arch]"
    echo "Defaults to -r $root -u $rsyncurl -f $distroname -a $arch"
    echo "Use vserver conventions for distroname, e.g. fc6 and f7"
    echo "Options:"
    echo " -n : dry run"
    echo " -v : verbose"
    echo " -c : skips core repository"
    exit 1
}

while getopts "nvcr:u:f:a:h" opt ; do
    case $opt in
	n) dry_run=--dry-run ;;
	v) verbose=--verbose ;;
	c) skip_core=true ;;
	r) root=$OPTARG ;;
	u) rsyncurl=$OPTARG ;;
	f) distroname=$OPTARG ;;
	a) arch=$OPTARG ;;
	h|*) usage ;;
    esac
done

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
	echo "Unknown redhat distribution $distroname - exiting"
	RES=1
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
    echo "$distro $distroindex currently unsupported - exiting"
else
    for repopath in $paths; do
	echo "============================== $distro -> $distroindex $repopath"
	[ -z "$dry_run" ] && mkdir -p ${root}/${repopath}
	command="rsync $options ${rsyncurl}/${repopath} ${root}/${repopath}"
	echo $command
	$command
    done
fi

exit $RES 
