#!/bin/bash
#

function make_int() {
    int=.int_$1
    if [ ! -r $int ] ; then
	touch $int
	echo $1 > $int
    fi
    echo $int
}


# $1 is symbol $2 is a value
function bind() {
    if [[ -n $2 ]] ; then
	ln -sf $2 $1
    else
	if [ -f $1 ] ; then
	    rm $1
	fi
	touch $1
    fi
}

function make_cons() {
    rslt=$(mktemp -d -u .cons_XXXX)
    mkdir $rslt
    if [[ -n $1 ]] ; then
	bind $rslt/car ../$1
    else
	bind $rslt/car
    fi
    if [[ -n $2 ]] ; then
	bind $rslt/cdr ../$2
    else
	bind $rslt/cdr
    fi
    echo $rslt
}


function car() {
    if [[ $1 =~ \.cons_.* ]] ; then
	if [ -h $1/car ] ; then
	    basename $(readlink $1/car)
	elif [ -f $1/car ] ; then
	    echo nil
	else
	    echo cannot take car of $1 >&2
	    return 1
	fi
    else
	echo cannot take car of $1 >&2
	return 1
    fi
}

function cdr() {
    if [[ $1 =~ \.cons_.* ]] ; then
	if [ -h $1/cdr ] ; then
	    basename $(readlink $1/cdr)
	elif [ -r $1/cdr ] ; then
	    echo nil
	else
	    echo cannot take cdr of $1 >&2
	    return 1
	fi
    else
	echo cannot take cdr of $1 >&2
	return 1
    fi
}


