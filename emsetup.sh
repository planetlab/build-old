#!/bin/bash
#
# Copyright (c) 2005  The Trustees of Princeton University (Trustees).
# All Rights Reserved.
#
# Original from Mark Huang to setup uml
# Adapted by Marc Fiucznski to support qemu
#
# umsetup is used to create a filesystem image, kernel, and related
# files needed to run either UML or qemu.  It is intended to be used
# either by individuals for their own testing purposes, or as a
# nightly script on an build/qa system for automated testing.
#
# $Id:$

STEPS="Mkfs Install InstallKernel InstallVRef Config"

usage ()
{
    echo "usage: $0 [-s $STEPS] [-t uml|qemu] [-y yum.conf] [kernelbuilddir] [installroot] [package ...]"
    exit 1
}    

# default filesystem setup for uml
TYPE="qemu"

# defaults
YUMCONF=
UTS_RELEASE=

# Must be root for some tasks
if [ $UID -ne 0 ] ; then
    echo "Must be root to run $0"
    exit 1
fi

# Get options
while getopts 's:i:t:y:h' OPT ; do
    case "$OPT" in
        s)
	    STEPS=$OPTARG
	    ;;

	t)
	    case "$OPTARG" in
		uml)
			TYPE="uml"
			;;
		qemu)
			TYPE="qemu"
			;;
	   	*)
			echo "expecting 'uml' or 'qemu', got $OPTARG"
			usage
			;;
	    esac
	    ;;

	  y)
		YUMCONF=$OPTARG
		if [ ! -f "$YUMCONF" ]; then
			echo "yum configuration file $YUMCONF not found"
			usage
		fi
   		;;	

	  h)
		usage
		;;
    esac
done

# Get arguments
shift $(($OPTIND - 1))
KERNEL=$1
shift
INSTALLROOT=$1
PACKAGE="$@"


# setup the UTS_RELEASE
if [ -d "$KERNEL" -a -f "$KERNEL/include/linux/version.h" ] ; then
    eval UTS_RELEASE=$(echo "#include <linux/version.h>" | cpp -I "$KERNEL/include" -dM - | awk '/UTS_RELEASE/ { print $3 }')
else
    echo "$KERNEL is not a valid linux kernel directory"
    exit 0
fi

# set installation mount point
if [ -z "$INSTALLROOT" ] ; then
    INSTALLROOT=$(mktemp -d "/tmp/mountpoint.XXXXXX")
fi
# Convert to absolute path
INSTALLROOT=$(cd $INSTALLROOT && pwd)

# set packages
if [ -z "$PACKAGE" ] ; then
    PACKAGE=PlanetLab
fi

# Bail on any simple error
set -e

# Be verbose
set -x

Unmount ()
{
    # Unmount / image
    if grep -q $INSTALLROOT /etc/mtab ; then
	umount $INSTALLROOT
	rmdir $INSTALLROOT
    fi
}

Mount ()
{
    # Mount / image
    if ! grep -q $INSTALLROOT /etc/mtab ; then
	mkdir -p $INSTALLROOT
	modprobe loop
	mount -o loop fs.img $INSTALLROOT
    fi
}

Mkfs ()
{
    # Make / image
    if [ ! -f fs.img ] ; then
	dd bs=1M count=2048 < /dev/zero > fs.img
    fi
    /sbin/mkfs.ext2 -F -j fs.img
}

MakeDevs () 
{
    FAKEROOT=$1
    if [ ! -z "$FAKEROOT" -a "$FAKEROOT" != "/" ] ; then
    	rm -rf $FAKEROOT/dev
	mkdir -p $FAKEROOT/dev
	mknod -m 666 $FAKEROOT/dev/null c 1 3
	mknod -m 666 $FAKEROOT/dev/zero c 1 5
	mknod -m 666 $FAKEROOT/dev/full c 1 7
	mknod -m 644 $FAKEROOT/dev/random c 1 8
	mknod -m 644 $FAKEROOT/dev/urandom c 1 9
	mknod -m 666 $FAKEROOT/dev/tty c 5 0
	mknod -m 666 $FAKEROOT/dev/ptmx c 5 2
	mkdir -p $FAKEROOT/dev/pts
	# well, /proc really is not in /dev
	mkdir -p $FAKEROOT/proc
    fi
}

Install ()
{
    Mount

    # Bootstrap RPM
    mkdir -p $INSTALLROOT/var/lib/rpm
    mkdir -p $INSTALLROOT/etc/rpm

    # Only install English language locale files
    cat > $INSTALLROOT/etc/rpm/macros <<EOF
%_install_langs en_US:en
EOF

    # Initialize RPM database
    rpm --root $INSTALLROOT --initdb

    # Write TYPE specific fstab 
    if [ "$TYPE" = "uml" ] ; then
        # Mount home directory inside UML
	mkdir -p $INSTALLROOT/$HOME

    	cat > $INSTALLROOT/etc/fstab <<EOF
/dev/ubd/0	/		ext3	defaults 0 0
/dev/ubd/1	/vservers	ext3	defaults 0 0
EOF
    else
    	cat > $INSTALLROOT/etc/fstab <<EOF
/dev/hda	/		ext3	defaults 0 0
EOF
    fi

    # Write rest of fstab
    cat >> $INSTALLROOT/etc/fstab <<EOF
none		/proc		proc	defaults 0 0
none		/dev/shm	tmpfs	defaults 0 0
none		/dev/pts	devpts	defaults 0 0
none		/rcfs   	rcfs	defaults 0 0
EOF

    TMP=$(mktemp "/tmp/yum.conf.XXXXXX")
    if [ -z "$YUMCONF" ] ; then
	cp yum.conf $TMP
    else
	cp $YUMCONF $TMP
    fi
	
    MakeDevs $INSTALLROOT
    # create mount points for /dev/pts and /proc
    mount -t devpts none $INSTALLROOT/dev/pts
    mount -t proc none $INSTALLROOT/proc

    # Install
    yum -c $TMP -y --installroot $INSTALLROOT install glibc yum
    yum -c $TMP -y --installroot $INSTALLROOT groupinstall $PACKAGE
    rm -f $TMP

    umount $INSTALLROOT/dev/pts
    umount $INSTALLROOT/proc

    Unmount
}

InstallKernel () 
{
    Mount

    mkdir -p $INSTALLROOT/boot

    if [ -f $KERNEL/System.map ] ; then
    	cp $KERNEL/System.map $INSTALLROOT/boot/System.map-$UTS_RELEASE
    fi
    if [ -f $KERNEL/init/kerntypes.o ] ; then
    	cp $KERNEL/init/kerntypes.o $INSTALLROOT/boot/Kerntypes-$UTS_RELEASE
    fi
    make -C $KERNEL modules_install INSTALL_MOD_PATH=$INSTALLROOT DEPMOD=/bin/true

    rm -f ./initrd-$UTS_RELEASE.img ./bzImage-$UTS_RELEASE $INSTALLROOT/boot/initrd-$UTS_RELEASE.img
    /usr/sbin/chroot $INSTALLROOT /sbin/depmod -ae -F /boot/System.map-$UTS_RELEASE $UTS_RELEASE
    /usr/sbin/chroot $INSTALLROOT mkinitrd /boot/initrd-$UTS_RELEASE.img $UTS_RELEASE
    cp $INSTALLROOT/boot/initrd-$UTS_RELEASE.img .

    rm -f ./bzImage-$UTS_RELEASE ./vmlinux-$UTS_RELEASE
    ln $KERNEL/arch/i386/boot/bzImage ./bzImage-$UTS_RELEASE
    ln $KERNEL/vmlinux ./vmlinux-$UTS_RELEASE

    ln -fs ./bzImage-$UTS_RELEASE ./bzImage
    ln -fs ./initrd-$UTS_RELEASE.img ./initrd
    ln -fs ./vmlinux-$UTS_RELEASE ./vmlinux

    Unmount
}

InstallVRef ()
{
    Mount
    
    # Based on vserver-reference

    VROOTDIR=$INSTALLROOT/vservers

    # Make /vservers
    mkdir -p $VROOTDIR
    chmod 000 $VROOTDIR
    chattr +t $VROOTDIR
    
    # Build image in /vservers/.vtmp
    mkdir -p $VROOTDIR/.vtmp
    VROOT=$(mktemp -d $VROOTDIR/.vtmp/vserver-reference.XXXXXX)

    # Make /vservers/.vtmp/vserver-reference.XXXXXX
    mkdir -p $VROOT
    chattr -t $VROOT
    chmod 755 $VROOT

    echo $"Building VServer reference: "

    MakeDevs $VROOT
    # create fake drive
    touch $VROOT/dev/hdv1

    # create mount points for /dev/pts and /proc
    mount -t devpts none $VROOT/dev/pts
    mount -t proc none $VROOT/proc

    # Create a dummy /etc/fstab in reference image
    mkdir -p $VROOT/etc

    cat > $VROOT/etc/fstab <<EOF
# This fake fstab exists only to please df and linuxconf.
/dev/hdv1	/	ext2	defaults	1 1
EOF

    cp $VROOT/etc/fstab $VROOT/etc/mtab

    # Prevent all locales from being installed in reference image
    mkdir -p $VROOT/etc/rpm
    cat > $VROOT/etc/rpm/macros <<EOF
%_install_langs en_US:en
%_excludedocs 1
%__file_context_path /dev/null
EOF

    # Initialize RPM database in reference image
    mkdir -p $VROOT/var/lib/rpm
    rpm --root $VROOT --initdb

    # Install RPMs in reference image
    TMP=$(mktemp "/tmp/yum.conf.XXXXXX")
    if [ -z "$YUMCONF" ] ; then
	cp yum.conf $TMP
    else
	cp $YUMCONF $TMP
    fi

    SSLCERTDIR=
    yum $SSLCERTDIR -c $TMP --installroot=$VROOT -y groupinstall VServer
    rm -f $TMP

    # Clean up /dev in reference image
    umount $VROOT/dev/pts

    # Disable all services in reference image
    chroot $VROOT /bin/sh -c "chkconfig --list | awk '{ print \$1 }' | xargs -i chkconfig {} off"

    # Copy configuration files from host to reference image
    for file in /etc/hosts /etc/resolv.conf /etc/yum.conf ; do
	if [ -f $file ] ; then
	    echo $file | cpio -p -d -u $VROOT
	fi
    done

    # Clean up
    umount $VROOT/proc

    # Swap them when complete
    mv $VROOT $VROOTDIR
    if [ -d $VROOTDIR/vserver-reference ] ; then
	mv $VROOTDIR/vserver-reference $VROOT
	rm -rf $VROOT
    fi
    mv $VROOTDIR/$(basename $VROOT) $VROOTDIR/vserver-reference

    # turn off vserver-reference in host image
    chkconfig --del vserver-reference


    Unmount
}


Config ()
{
    Mount

    # Set local time to UTC
    ln -sf /usr/share/zoneinfo/UTC $INSTALLROOT/etc/localtime

    # Write network configuration
    cat > $INSTALLROOT/etc/hosts <<EOF
127.0.0.1	localhost
EOF
    cp /etc/resolv.conf $INSTALLROOT/etc/

    # Disable unneeded services
    SERVICES="netfs rawdevices cpuspeed smartd"
    # i686 only
    SERVICES="$SERVICES microcode_ctl"
    # syslogd and sendmail broken for some reason
    SERVICES="$SERVICES syslog sendmail"
    # Not now
    SERVICES="$SERVICES pl_conf pl_nm pl_spd PlanetLabID PlanetLabConf"
    for service in $SERVICES ; do
	/usr/sbin/chroot $INSTALLROOT chkconfig $service off || :
    done

    Unmount
}

trap "Unmount ; exit 255"

for step in $STEPS ; do
    eval $step
done
