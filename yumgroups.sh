#!/bin/bash

. build.common

function usage () {
    echo "Usage: $0 pldistro"
    exit 1
}

[ "$#" = 2 ] || usage
pldistro=$1; shift
pkgsname=$1; shift

toplevel_yumgroups $pldistro $pkgsname
