#!/bin/bash

. build.common

function usage () {
    echo "Usage: $0 pldistro"
    exit 1
}

[ "$#" = 1 ] || usage
pldistro=$1; shift

# gather all known pkgs files
here=$(pwd)
all_pkgs=$( (cd $here/config.planetlab ; ls -1 *.pkgs ; cd $here/config.$pldistro; ls *.pkgs) | sort -u)

yumgroups_from_pkgs $(dirname $0) $pldistro $pl_DISTRO_NAME $all_pkgs
