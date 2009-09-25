#!/bin/bash
# this can help you create/update your fedora mirror
# $Id$

COMMAND=$(basename $0)
LOGDIR=/var/log/fedora-mirroring
DATE=$(date '+%Y-%m-%d-%H-%M')
LOG=${LOGDIR}/${DATE}.log

dry_run=
verbose=
log=
skip_core=true
root=/mirror/


hozac_url=http://rpm.hozac.com/dhozac/centos/5/vserver
# Daniel mentions rsync://rpm.hozac.com/dhozac/centos/5/vserver/

us_fedora_url=rsync://mirrors.kernel.org/fedora
us_centos_url=rsync://mirrors.rit.edu/centos
us_epel_url=rsync://rsync.gtlib.gatech.edu/fedora-epel

# ircam's fedora8 repo has been turned off
#eu_fedora_url=rsync://mirrors.ircam.fr/fedora-linux
eu_fedora_url=rsync://mirror.ovh.net/download.fedora.redhat.com/linux
eu_centos_url=rsync://mirrors.ircam.fr/CentOS
eu_epel_url=rsync://mirrors.ircam.fr/fedora-epel

jp_fedora_url="jp_fedora_url-needs-to-be-defined"
jp_centos_url="jp_centos_url-needs-to-be-defined"
jp_epel_url="jp_epel_url-needs-to-be-defined"

default_distroname="centos5"
all_distronames="f8 f10 f11 centos5.3 epel5"
default_arch="i386"
all_archs="i386 x86_64"

case $(hostname) in 
    *.fr|*.de|*.uk)
	fedora_url=$eu_fedora_url ; centos_url=$eu_centos_url ; epel_url=$eu_epel_url ;;
    *.jp)
	fedora_url=$jp_fedora_url ; centos_url=$jp_centos_url ; epel_url=$jp_epel_url ;;
    *)
	fedora_url=$us_fedora_url ; centos_url=$us_centos_url ; epel_url=$us_epel_url ;;
esac

function mirror_distro_arch () {
    distroname=$1; shift
    arch=$1; shift

    LFTP=0

    distroname=$(echo $distroname | tr '[A-Z]' '[a-z]')
    case $distroname in
	fc*[1-6])
    	    distroindex=$(echo $distroname | sed -e "s,fc,,g")
	    distro="Fedora Core"
	    rsyncurl=$fedora_url
	    ;;
	f*[7-9]|f1?)
	    distroindex=$(echo $distroname | sed -e "s,f,,g")
	    distro="Fedora"
	    rsyncurl=$fedora_url
	    ;;
	centos[4-5]|centos[4-5].[0-9])
	    distroindex=$(echo $distroname | sed -e "s,centos,,g")
	    distro="CentOS"
	    rsyncurl=$centos_url
	    ;;
	epel5)
	    distroindex=5
	    distro=epel
	    rsyncurl=$epel_url
	    ;;
	hozac)
	    distroindex=5
	    distro="hozac"
	    rsyncurl=$hozac_url
	    ;;
	*)
	    echo "WARNING -- Unknown distribution $distroname -- skipped"
	    return 1
	    ;;
    esac

    excludelist="debug/ iso/ ppc/ source/"
    options="--archive --compress --delete --delete-excluded $dry_run $verbose"
    lftp_options="--delete $dry_run $verbose"
    [ -n "$(rsync --help | grep no-motd)" ] && options="$options --no-motd"
    for e in $excludelist; do
	options="$options --exclude $e"
	lftp_options="$lftp_options --exclude $e"
    done

    echo ">>>>>>>>>>>>>>>>>>>> root=$root distroname=$distroname arch=$arch rsyncurl=$rsyncurl"
    [ -n "$verbose" ] && echo "rsync options=$options"

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
		7|8|9|1?)
		    [ -z "$skip_core" ] && paths="releases/$distroindex/Everything/$arch/os/"
		    paths="$paths updates/$distroindex/$arch/"
		    # f8 and f9 have the additional newkey repo
		    case $distroindex in 
			8|9) paths="$paths updates/$distroindex/${arch}.newkey/" ;;
		    esac
		    RES=0
		    ;;
	    esac
	    localpath=fedora
	    ;;
    
	CentOS*)
	    case $distroindex in
		5*)
		    [ -z "$skip_core" ] && paths="$distroindex/os/$arch/"
		    paths="$paths $distroindex/updates/$arch/"
		    RES=0
		    ;;
	    esac
	    localpath=centos
	    ;;

	epel*)
	    case $distroindex in
		5)
		    paths="$paths $distroindex/$arch/"
		    RES=0
		    ;;
	    esac
	    localpath=epel
	    ;;

	hozac*)
	    case $distroindex in
		5)
		    # leave off trailing '/'
		    paths="$paths $arch"
		    RES=0
		    LFTP=1
		    ;;
	    esac
	    localpath=dhozac
	    ;;

    esac

    if [ "$RES" = 1 ] ; then
	echo "DISTRIBUTION $distro $distroindex CURRENTLY UNSUPPORTED - skipped"
    else
	for repopath in $paths; do
	    echo "===== $distro -> $distroindex $repopath"
	    [ -z "$dry_run" ] && mkdir -p ${root}/${localpath}/${repopath}
	    if [ "$LFTP" = 1 ]; then
	        command="lftp -c mirror $lftp_options ${rsyncurl}/${repopath} ${root}/${localpath}/${repopath}"
	    else
		command="rsync $options ${rsyncurl}/${repopath} ${root}/${localpath}/${repopath}"
	    fi
	    echo $command
	    $command
	done
    fi

    echo "<<<<<<<<<<<<<<<<<<<< $distroname $arch"

    return $RES 
}

function usage () {
    echo "Usage: $COMMAND [-n] [-v] [-c] [-r root] [-u|U rsyncurl] [-e|-j] [-f distroname|-F] [-a arch|-A]"
    echo "Defaults to -r $root -f $default_distroname -a $default_arch"
    echo "Default urls : $fedora_url $centos_url"
    echo "Options:"
    echo " -n : dry run"
    echo " -v : verbose"
    echo " -l : turns on autologging in $LOGDIR"
    echo " -c : skips core repository (default)"
    echo " -C : force syncing core repository"
    echo " -r root (default is $root)"
    echo " -u rsyncurl for fedora (default is $fedora_url)"
    echo " -U rsyncurl for centos (default is $centos_url)"
    echo " -E rsyncurl for epel (default is $epel_url)"
    echo " -s : uses standard (US) mirrors $us_fedora_url $us_centos_url $us_epel_url"
    echo " -e : uses European mirrors $eu_fedora_url $eu_centos_url $eu_epel_url"
    echo " -j : uses Japanese mirrors $jp_fedora_url $jp_centos_url $jp_epel_url"
    echo " -f distroname - use vserver convention, e.g. f8 or centos5"
    echo " -F : for distroname in $all_distronames"
    echo " -a arch - use yum convention"
    echo " -A : for arch in $all_archs"
    exit 1
}

function run () {
    RES=0
    for distroname in $distronames ; do 
	for arch in $archs; do 
	    mirror_distro_arch "$distroname" "$arch" || RES=1
	done
    done
    return $RES
}

function main () {
    distronames=""
    archs=""
    while getopts "nvlcCr:u:U:E:sejf:Fa:Ah" opt ; do
	case $opt in
	    n) dry_run=--dry-run ;;
	    v) verbose=--verbose ;;
	    l) log=true ;;
	    c) skip_core=true ;;
	    C) skip_core= ;;
	    r) root=$OPTARG ;;
	    u) fedora_url=$OPTARG ;;
	    U) centos_url=$OPTARG ;;
	    E) epel_url=$OPTARG ;;
	    s) fedora_url=$us_fedora_url ; centos_url=$us_centos_url ; epel_url=$us_epel_url;;
	    e) fedora_url=$eu_fedora_url ; centos_url=$eu_centos_url ; epel_url=$eu_epel_url ;;
	    j) fedora_url=$jp_fedora_url ; centos_url=$jp_centos_url ; epel_url=$jp_epel_url ;;
	    f) distronames="$distronames $OPTARG" ;;
	    F) distronames="$distronames $all_distronames" ;;
	    a) archs="$archs $OPTARG" ;;
	    A) archs="$archs $all_archs" ;;
	    h|*) usage ;;
	esac
    done
    [ -z "$distronames" ] && distronames=$default_distroname
    [ -z "$archs" ] && archs=$default_arch

    # auto log : if specified
    if [ -n "$log" ] ; then
	mkdir -p $LOGDIR
	run &> $LOG
    else
	run
    fi
    exit $?
}

main "$@"
