#!/bin/bash
# $Id$

COMMAND=$(basename $0)
DIRNAME=$(dirname $0)

default_url="http://localhost/mirror/"
default_distro="f8"
all_distros="f8 f10 f11 centos5"

function check_distro () {
    local distro=$1; shift
    if [ ! -d $DIRNAME/$distro/yum.repos.d ] ; then
	echo "Distro $distro not supported - skipped"
	return 1
    fi
    return 0
}

function do_repo () {
    local distro=$1; shift
    sedargs="-e s,@MIRRORURL@,$URL,"
    [ -n "$GPGOFF" ] && sedargs="$sedargs -e "'s,gpgcheck\W*=\W*1,gpgcheck=0,'
    sed $sedargs $DIRNAME/$distro/yum.repos.d/building.repo.in
}

function do_init () { 
    local distro=$1; shift
    repo=/etc/vservers/.distributions/$distro/yum.repos.d/building.repo
    dir=/etc/vservers/.distributions/$distro/yum.repos.d/
    if [ ! -d $dir ] ; then
	[ -n "$VERBOSE" ] && echo Creating dir $dir
	mkdir -p $dir
    fi
    [ -n "$VERBOSE" ] && echo "Creating $repo"
    do_repo $distro > $repo
}

function do_diff () {
    local distro=$1; shift
    repo=/etc/vservers/.distributions/$distro/yum.repos.d/building.repo
    if [ ! -f $repo ] ; then
	echo "Cannot find $repo"
    else
	would=/tmp/$COMMAND.$$
	do_repo $distro > $would
	echo "==================== DIFF for $distro" '(current <-> would be)'
	diff $repo $would 
	rm $would
    fi
}

function do_display () {
    local distro=$1; shift
    dir=/etc/vservers/.distributions/$distro/yum.repos.d/
    if [ -d $dir ] ; then
	echo "====================" Contents of $dir
	ls $dir/*.repo 2> /dev/null | xargs head --verbose --lines=1000
    else
	echo "====================" $dir does not exist
    fi
}

function do_clean () {
    local distro=$1; shift
    repo=/etc/vservers/.distributions/$distro/yum.repos.d/building.repo
    [ -n "$VERBOSE" ] && echo Removing $repo
    rm $repo
}

function do_superclean () {
    local distro=$1; shift
    dir=/etc/vservers/.distributions/$distro/yum.repos.d/
    [ -n "$VERBOSE" ] && echo Removing all repo files in $dir
    rm $dir/*.repo
}

function usage () {
    echo "Usage $COMMAND [options] <command>"
    echo "  a help to manage the yum.repos.d template in /etc/vservers/.distributions/<distro>"
    echo "Available commands"
    echo "  display: shows content (default if <command> is missing)"
    echo "  diff: shows diff between current and what init would do"
    echo "  init: creates /etc/vservers/.distributions/<distro>/yum.repos.d/building.repo"
    echo "  clean: removes building.repo"
    echo "  superclean: removes yum.repos.d altogether"
    echo "Options"
    echo "  -u URL to specify another location"
    echo "     default is to use mirror root at $default_url"
    echo "  -f <distro> : defaults to $default_distro"
    echo "  -a : runs on all distros $all_distros"
    echo "  -0 : turns off gpgcheck"
    echo "  -v : verbose"
    echo "Examples"
    echo "  $COMMAND -a display "
    echo "  $COMMAND -a superclean"
    echo "  $COMMAND -a -u http://mirror.onelab.eu/ init"
    echo "  $COMMAND -a display"
    exit 1
}
    
DISTROS=""
URL=""
VERBOSE=""
GPGOFF=""

function main () {

    while getopts "u:f:a0v" opt; do
	case $opt in
	    u) URL=$OPTARG ;;
	    f) DISTROS="$DISTROS $OPTARG" ;;
	    a) DISTROS="$DISTROS $all_distros" ;;
	    0) GPGOFF=true ;;
	    v) VERBOSE=true ;;
	    *) usage ;;
	esac
    done

    shift $(($OPTIND - 1))
    
    # no action = display
    case "$#" in 
	0)
	    action=display ;;
	1) 
	    action=$1; shift
	    case $action in
		disp*) action=display ;;
		init*) action=init ;;
		diff*) action=diff ;;
		clea*) action=clean ;;
		super*) action=superclean ;;
		*) usage ;;
	    esac ;;
	*)
	    usage ;;
    esac

    [ -z "$URL" ] && URL=$default_url
    [ -z "$DISTROS" ] && DISTROS="$default_distro"

    # remove trailing slash
    URL=$(echo $URL | sed -e 's,/$,,')

    for distro in $DISTROS; do
	[ -n "$VERBOSE" ] && echo ==================== Running $action for $distro
	check_distro $distro && do_$action $distro
    done

    exit 0
}

main "$@"
