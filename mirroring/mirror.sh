#!/bin/bash
# $Id$

COMMAND=$(basename $0)
DIRNAME=$(dirname $0)

default_url="http://localhost/mirror/"
default_distro="f8"
all_distros="fc4 fc6 f7 f8 centos5"

function check_distro () {
    local distro=$1; shift
    if [ ! -d $DIRNAME/$distro ] ; then
	echo "Distro $distro not supported - skipped"
	return 1
    fi
    return 0
}

function do_init () { 
    local distro=$1; shift
    repo=/etc/vservers/.distributions/$distro/yum.repos.d/building.repo
    dir=/etc/vservers/.distributions/$distro/yum.repos.d/
    if [ ! -d $dir ] ; then
	[ -n "$VERBOSE" ] && echo Creating dir $dir
	mkdir -p -d $dir
    fi
    [ -n "$VERBOSE" ] && echo "Creating $repo"
    sed -e "s,@MIRRORURL@,$URL," < $DIRNAME/$distro/building.repo.in > $repo
}

function do_display () {
    local distro=$1; shift
    dir=/etc/vservers/.distributions/$distro/yum.repos.d/
    if [ -d $dir ] ; then
	echo "====================" Contents of $dir
	find $dir -name '*.repo' | xargs head --verbose --lines=1000
    else
	echo "====================" $dir does not exist
    fi
}

function do_clear () {
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
    echo "  init: creates /etc/vservers/.distributions/<distro>/yum.repos.d/building.repo"
    echo "       default is to use mirror root at $default_url"
    echo "       use -u URL to specify another location"
    echo "  display: shows content"
    echo "  clean: removes building.repo"
    echo "  superclean: removes yum.repos.d altogether"
    echo "Options"
    echo "  -f <distro> : defaults to $default_distro"
    echo "  -a : runs on all distros $all_distros"
    echo "  -v : verbose"
    echo "Examples"
    echo "  $COMMAND -a display "
    echo "  $COMMAND -a superclean"
    echo "  $COMMAND -a -u http://mirror.one-lab.org/ init"
    echo "  $COMMAND -a display"
    exit 1
}
    
DISTROS=""
URL=""
VERBOSE=""

function main () {

    while getopts "u:f:av" opt; do
	case $opt in
	    u) URL=$OPTARG ;;
	    f) DISTROS="$DISTROS $OPTARG" ;;
	    a) DISTROS="$DISTROS $all_distros" ;;
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
		init*) action=init ;;
		dis*) action=display ;;
		clea*) action=clear ;;
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
