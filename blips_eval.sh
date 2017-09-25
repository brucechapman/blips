#!/bin/bash
#

# $1 is function name 
# $2 .. $(n) are args
function process_internal_form() {
    #echo Process internal form $* >&2
    fname=${1#.subf_}_form_impl
    #echo function name is $fname type is $(type -t $fname) >&2
    if [ -n "$(type -t $fname)" ] && [ "$(type -t $fname)" = function ]; then
        shift 1
	$fname $*
    else
	echo Internal function $fname not found >&2
	exit 1
    fi
}

function process_internal_func() {
    #echo Process internal form $* >&2
    fname=${1#.subr_}_func_impl
    #echo function name is $fname type is $(type -t $fname) >&2
    if [ -n "$(type -t $fname)" ] && [ "$(type -t $fname)" = function ]; then
        shift 1
	$fname $*
    else
	echo Internal function $fname not found >&2
	exit 1
    fi
}

# $1 is cons of 1st arg
# return a list of all the args in the list
function arglist() {
    #echo arglist of $1 >&2
    ptr=$1
    while [[ $(basename $(readlink $ptr/cdr)) =~ \.cons_.* ]] ; do
	echo -n $(basename $(readlink $ptr/car))
	echo -n ' '
	ptr=$(basename $(readlink $ptr/cdr))
    done
    echo $(basename $(readlink $ptr/car))
    if [[ $(basename $(readlink $ptr/cdr)) != nil ]] ; then
        echo Dotted list illegal as function call >&2
	exit 1
    fi
}

# $1 is an atom
function eval_impl() {
    if [[ $1 =~ \.cons_.* ]] ; then
        # the hard one with all the interesting stuff
        fname=$(basename $(readlink $1/car))
        if [ -h $fname ] ; then
	    #echo eval_impl $fname is a link >&2
	    target=$(readlink $fname)
	    #echo TODO eval_impl "($fname -> $target"  >&2
	    if [[ $target =~ \.subf_.* ]] ; then
		#echo An internal form >&2
		process_internal_form $target $(arglist $(basename $(readlink $1/cdr)))
	    elif [[ $target =~ \.subr_.* ]] ; then
		#echo An internal function >&2
		process_internal_func $target $(eval_all_args $(arglist $(basename $(readlink $1/cdr))))
	    elif [[ $target =~ \.cons_.* ]] ; then
		#echo A user function TODO >&2
		process_external_func $target $(eval_all_args $(arglist $(basename $(readlink $1/cdr))))
	    else
		echo unknown function call type >&2
	    fi
	else
	    echo call to unbound function name $fname >&2
	fi
    elif [[ $1 =~ \.int_.* ]];  then
       echo $1
    elif [[ $1 =~ \.str_.* ]]; then
       echo $1
    else
        # a symbol
        if [ -h $1 ] ; then
	    readlink $1
	else
	    echo nil
	fi
    fi
}

function eval_all_args() {
    while [ -n "$1" ] ; do
     	echo -n $(eval_impl $1)
	echo -n ' '
	shift
    done
}


