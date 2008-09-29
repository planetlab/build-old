#!/bin/bash

COMMAND=$(basename $0)
. $(dirname $0)/build.common

function usage () {
    echo "Usage: $COMMAND"
    echo "outputs the list of packages to exclude from the stock repositories"
    echo "this is set in build.common, and needs to fit the set of packages"
    echo "that we override in the planetlab build"
    exit 1
}

[[ -n "$@" ]] && usage

echo "$pl_KEXCLUDES"
