#!/bin/bash
# this can help you create/update your fedora mirror

COMMAND=$(basename $0)

dry_run=
root=/data/fedora/linux
rsyncurl=rsync://fr.rpmfind.net/linux/fedora
fcdistro=fc6
arch=i386


function usage () {
    echo "Usage: $COMMAND [-n] [-v] [-r root] [-u rsyncurl] [-f fcdistro] [-a arch]"
    echo "Defaults to -r $root -u $rsyncurl -f $fcdistro -a $arch"
    echo "Use vserver conventions for fcdistro, e.g. fc6 and f7"
    exit 1
}

while getopts "nvr:u:f:a:h" opt ; do
    case $opt in
	n) dry_run=-n ;;
	v) set -x ;;
	r) root=$OPTARG ;;
	u) rsyncurl=$OPTARG ;;
	f) fcdistro=$OPTARG ;;
	a) arch=$OPTARG ;;
	h|*) usage ;;
    esac
done

case $fcdistro in
    fc*[1-6])
	findex=$(echo $fcdistro | sed -e s,fc,,g)
	;;
    *)
	findex=$(echo $fcdistro | sed -e s,f,,g)
	;;
esac

echo "root=$root"
echo rsyncurl="$rsyncurl"
echo "fcdistro=$fcdistro"
echo "findex=$findex"
echo "arch=$arch"

case $findex in
    2|4|6)
	echo "============================== $findex core"
	mkdir -p ${root}/core/$findex/$arch/os/
	rsync $dry_run -avz --delete --exclude debug/ ${rsyncurl}/core/$findex/$arch/os/ ${root}/core/$findex/$arch/os/
	echo "============================== $findex updates"
	mkdir -p  ${root}/core/updates/$findex/$arch/
	rsync $dry_run -avz --delete --exclude debug/ ${rsyncurl}/core/updates/$findex/$arch/ ${root}/core/updates/$findex/$arch/
	echo "============================== $findex extras"
	mkdir -p ${root}/extras/$findex/$arch/
	rsync $dry_run -avz --delete --exclude debug/ ${rsyncurl}/extras/$findex/$arch/ ${root}/extras/$findex/$arch/
	;;
    7)
	echo "============================== $findex core"
	mkdir -p ${root}/core/$findex/$arch/os/
	rsync $dry_run -avz --delete --exclude debug/ ${rsyncurl}/core/$findex/Everything/$arch/os/ ${root}/core/$findex/$arch/os/
	echo "============================== $findex updates"
	mkdir -p ${root}/core/updates/$findex/$arch/
	rsync $dry_run -avz --delete --exclude debug/ ${rsyncurl}/core/updates/$findex/$arch/ ${root}/core/updates/$findex/$arch/
	;;
    8)
    # somehow the layout on my favorite mirror is different in 7 and 8, /Everything/ has gone 
	echo "============================== $findex core"
	mkdir -p ${root}/core/$findex/$arch/os/
	rsync $dry_run -avz --delete --exclude debug/ ${rsyncurl}/core/$findex/$arch/os/ ${root}/core/$findex/$arch/os/
	echo "============================== $findex updates"
	mkdir -p ${root}/core/updates/$findex/$arch/
	rsync $dry_run -avz --delete --exclude debug/ ${rsyncurl}/core/updates/$findex/$arch/ ${root}/core/updates/$findex/$arch/
	;;
    *)
	echo "Unknown fedora index $findex - exiting"
	exit 1
	;;
esac
