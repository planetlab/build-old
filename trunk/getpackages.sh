#!/bin/bash

. build.common

function usage () {
    echo "Usage: $0 pldistro rhdistro lstfiles"
    exit 1
}

#[ "$#" = 1 ] || usage
pldistro=$1; shift
rhdistro=$1; shift
lstfiles=$@

function pkgs_from_lst () {
    builddir=$1; shift
    pldistro=$1; shift
    rhdistro=$1; shift
    lstfiles=$@

    for lstfile in $lstfiles; do
	pkgsfile=$(pl_locateDistroFile $builddir $pldistro $lstfile 2> /dev/null) 
	packages=$(pl_getPackages $rhdistro $pldistro $pkgsfile)
	echo $packages
    done
}

pkgs_from_lst $(dirname $0) $pldistro $rhdistro $lstfiles
