#!/bin/bash
#
function setq_form_impl() {
    #echo setq_impl called with $* >&2
    while [ -n "$2" ] ; do
	# TODO check $1 is a symbol
	val=$(eval_impl $2)
	bind $1 $val
	shift 2
    done
    if [ -n "$1" ] ; then
	echo setq with odd number of arguments >&2
	exit 1
    fi
    echo $val
}

function set_func_impl() {
    bind $1 $2
}

function eval_func_impl() {
    eval_impl $1
}


function quote_form_impl() {
    echo $1
}

function defun_form2_impl() {
    #echo $(arglist $1) >&2
    #echo head is $1 car is $(car $1) cdr is $(cdr $1) >&2
    bind $(car $1) $(cdr $1)
    echo $(car $1) 
}

# return 0 (true) if $1 is not nil
function predicate() {
    if [[ -z $1 ]] ; then
	return 1
    elif [[ $1 == nil ]] ; then
	return 1
    else
	return 0
    fi
}

function if_form_impl() {
    if predicate $(eval_impl $1) ; then
	eval_impl $2
    elif [[ -n $3 ]] ; then
	eval_impl $3
    else
	echo nil
    fi
}

function +_func_impl() {
    #echo plus $* >&2
    result=$(cat $1)
    shift
    while [[ -n $1 ]] ; do
	result=$(($result+$(cat $1)))
	shift
    done
    #echo result=$result >&2
    make_int $result
}

function car_func_impl() {
    car $1
}

function cdr_func_impl() {
    cdr $1
}

function cons_func_impl() {
    make_cons $1 $2
}

function install_implementations() {
    declare -F | cut -d ' ' -f3 | while read fnc; do
	if [[ $fnc =~ .*_form_impl ]] ; then
	    fname=${fnc%_form_impl}
	    bind $fname .subf_$fname
	elif [[ $fnc =~ .*_form2_impl ]] ; then
	    fname=${fnc%_form2_impl}
	    bind $fname .subf2_$fname
	elif [[ $fnc =~ .*_func_impl ]] ; then
	    fname=${fnc%_func_impl}
	    bind $fname .subr_$fname
	fi
    done
}

