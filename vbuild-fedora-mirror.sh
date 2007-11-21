#!/bin/bash
# this can help you create/update your fedora mirror

COMMAND=$(basename $0)

dry_run=
root=/data/fedora/linux
rsyncurl=rsync://mirrors.kernel.org/fedora
#rsyncurl=rsync://fr.rpmfind.net/linux/fedora
distroname=fc6
arch=i386


function usage () {
    echo "Usage: $COMMAND [-n] [-v] [-r root] [-u rsyncurl] [-f distroname] [-a arch]"
    echo "Defaults to -r $root -u $rsyncurl -f $distroname -a $arch"
    echo "Use vserver conventions for distroname, e.g. fc6 and f7"
    exit 1
}

while getopts "nvr:u:f:a:h" opt ; do
    case $opt in
	n) dry_run=-n ;;
	v) set -x ;;
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

excludelist="debug/ iso/ ppc/ opx"
options="$dry_run -avz --delete --delete-excluded"
for e in $excludelist
do
  options="$options --exclude $e"
done

echo "root=$root"
echo "distro=$distroname"
echo "distroname=$distroname"
echo "distroindex=$distroindex"
echo "arch=$arch"
echo rsyncurl="$rsyncurl"
echo "rsync options=$options"

case $distro in
    [Ff]edora*)
        case $distroindex in
	    2|4|6)
		for repopath in core/$distroindex/$arch/os/ core/updates/$distroindex/$arch/ extras/$distroindex/$arch/
		  do
		  echo "============================== $distro -> $distroindex $repopath"
		  mkdir -p ${root}/${repopath}
		  rsync $options ${rsyncurl}/${repopath} ${root}/${repopath}
		done
		RES=0
		;;

	    7|8)
		for repopath in releases/$distroindex/Everything/$arch/os/ updates/$distroindex/$arch/
		  do
		  echo "============================== $distro -> $distroindex $repopath"
		  mkdir -p ${root}/${repopath}
		  rsync $options ${rsyncurl}/${repopath} ${root}/${repopath}
		done
		RES=0
		;;
	    *)
		echo "Unknown fedora index $distroindex - exiting"
		RES=1
		;;
	esac
	;;
    *)
	echo "$distro $distroindex currently unsupported - exiting"
	RES=1
	;;
esac

exit $RES 
