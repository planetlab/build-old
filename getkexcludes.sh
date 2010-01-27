#!/bin/bash

COMMAND=$(basename $0)
. $(dirname $0)/build.common

function usage () {
    echo "Usage: $COMMAND [-f fcdistro]"
    echo "outputs the list of packages to exclude from the stock repositories"
    echo "this is set in build.common, and needs to fit the set of packages"
    echo "that we override in the planetlab build"
    exit 1
}

while getopts "f:" opt ; do
    case $opt in
	f) FCDISTRO=$OPTARG ;;
	h|*) usage ;;
    esac
done
	
toshift=$(($OPTIND - 1))
shift $toshift

[[ -n "$@" ]] && usage

# if the fcdistro is passed in argument
if [ -n "$FCDISTRO" ] ; then
    pl_getKexcludes "$FCDISTRO"
# otherwise use the value for the current system
else
    echo "$pl_KEXCLUDES"
fi
