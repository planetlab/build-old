#!/bin/bash

kernelrpm=$1
vnetrpm=$2

tmpdir=
files=

bail () 
{
    rm -rf $tmpdir $files
    exit -1
}

usage ()
{
    echo "$0 kernel.rpm vnet.rpm"
    exit -1
}

checkrpm ()
{
    filename=$1
    if [ -f "$filename" -a $(rpm -qip $filename | wc -l) -eq 1 ] ; then
	echo "$filename not a valid rpm file"
	usage
    fi
}

[ -z "$kernelrpm" -o  -z "$vnetrpm" ] && usage
checkrpm $kernelrpm
checkrpm $vnetrpm

isofs=/plc/root/usr/share/bootcd/build/isofs
tmpdir=$(mktemp -d /tmp/bootcd.XXXXXX)
cur=`pwd`
if [ -d ../bootmanager ] ; then
    MERGE=${cur}/../bootmanager/source/merge_hw_tables.py
else
    echo "cannot find merge_hw_tables.py"
    exit -1
fi

myplcwebdir=/plc/data/var/www/html

echo -n "Updating myplc planetlab yum repository with $kernelrpm"
rm -f ${myplcwebdir}/install-rpms/planetlab/kernel-*
cp $cur/$kernelrpm ${myplcwebdir}/install-rpms/planetlab

echo -n " and $vnetrpm"
rm -f ${myplcwebdir}/install-rpms/planetlab/vnet-*
cp $cur/$vnetrpm ${myplcwebdir}/install-rpms/planetlab
echo " ... done"

trap "bail" ERR INT
echo "Updating bootcd image with $kernelrpm"
pushd $tmpdir
mkdir bootcd
pushd bootcd
gzip -d -c $isofs/bootcd.img | cpio -diu
rm -rf boot/*
rm -rf lib/modules
rpm2cpio  $cur/$kernelrpm | cpio -diu
version=$(cd ./boot && ls vmlinuz* | sed 's,vmlinuz-,,')
depmod -b . $version
pci_map_file=./lib/modules/${version}/modules.pcimap
module_dep_file=./lib/modules/${version}/modules.dep
pci_table=./usr/share/hwdata/pcitable
$MERGE $module_dep_file $pci_map_file $pci_table ./etc/pl_pcitable
cp boot/vmlinuz* ${tmpdir}/kernel
find . | cpio --quiet -c -o | gzip -9 > ${tmpdir}/bootcd.img
popd
popd
mv ${tmpdir}/kernel $isofs
mv ${tmpdir}/bootcd.img $isofs
rm -rf $tmpdir
echo " ... done"
trap - ERR

echo -n "update PlanetLab-Bootstrap.tar.bz2 with $kernelrpm"
tmpdir=$(mktemp -d ${myplcwebdir}/boot/bootstrap.XXXXXX)
trap "bail" ERR INT
cur=`pwd`
cp $cur/$kernelrpm ${tmpdir}/kernel.rpm
cp $cur/$vnetrpm ${tmpdir}/vnet.rpm
echo -n " ... untarring PlanetLab-Bootstrap.tar.bz2"
pushd $tmpdir
tar -jxpf ${myplcwebdir}/boot/PlanetLab-Bootstrap.tar.bz2
popd
chroot $tmpdir rpm -e --allmatches --nodeps --noscripts vnet
chroot $tmpdir rpm -e --allmatches --nodeps kernel
files="${tmpdir}/kernel.rpm ${tmpdir}/vnet.rpm"
chroot $tmpdir rpm -Uvh kernel.rpm
chroot $tmpdir rpm -Uvh vnet.rpm
rm -f ./kernel.rpm
rm -f ./vnet.rpm
echo -n " ... tarring PlanetLab-Bootstrap.tar.bz2"
pushd $tmpdir
tar -jcpf ${myplcwebdir}/boot/PlanetLab-Bootstrap.tar.bz2.new ./
popd
mv ${myplcwebdir}/boot/PlanetLab-Bootstrap.tar.bz2.new ${myplcwebdir}/boot/PlanetLab-Bootstrap.tar.bz2
rm -rf $tmpdir
echo " ... done"
trap - ERR

exit 0
