#!/bin/bash
#
function setq_form_impl() {
    #echo setq_impl called with $* >&2
    while [ -n "$2" ] ; do
        # TODO check $1 is a symbol
	val=$(eval_impl "$2")
	bind "$1" "$val"
	shift 2
    done
    if [ -n "$1" ] ; then
	echo setq with odd number of arguments >&2
	exit 1
    fi
    echo "$val"
}

function set_func_impl() {
    bind "$1" "$2"
}

function eval_func_impl() {
    eval_impl "$1"
}


function quote_form_impl() {
    echo "$1"
}
function =_func_impl() {
    if [[ $1 =~ \.int_.* && $2 =~ \.int_.* ]] ; then
	if [[ "$1" == "$2" ]] ; then
	    echo T
	else
	    echo nil
	fi
    else
	echo "= only implemented for ints" >&2
	echo nil
    fi
}

function not_func_impl() {
    if predicate "$1" ; then
	echo nil
    else
	echo T
    fi
}

function defun_form2_impl() {
    #echo $(arglist $1) >&2
    #echo head is $1 car is $(car $1) cdr is $(cdr $1) >&2
    bind "$(car "$1")" "$(cdr "$1")"
    car "$1" 
}

function gc_func_impl() {
    gc
    echo nil
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
    if predicate "$(eval_impl "$1")" ; then
	eval_impl "$2"
    elif [[ -n $3 ]] ; then
	eval_impl "$3"
    else
	echo nil
    fi
}

function while_form_impl() {
    pred=$1
    shift
    while predicate "$(eval_impl "$pred")" ; do
	for expr; do
	    result=$(eval_impl "$expr")
	done
    done
    echo "$result"
}

function +_func_impl() {
    #echo plus $* >&2
    result=$(cat "$1")
    shift
    while [[ -n $1 ]] ; do
	result=$((result+$(cat "$1")))
	shift
    done
    #echo result=$result >&2
    make_int $result
}

function car_func_impl() {
    car "$1"
}

function cdr_func_impl() {
    cdr "$1"
}

function cons_func_impl() {
    make_cons "$1" "$2"
}

function print_func_impl() {
    print "$1" >&2
    echo '' >&2
    echo "$1"
}

function load_func_impl() {
    if [[ $1 =~ \.str_.* ]] ; then
	if [ -r "$CWD_DIR/$(cat "$1")" ] ; then
	    #exprs=$(cat "$CWD_DIR/$(cat "$1")" | tokenise | tee debug.tmp | createlots )
	    exprs=$(tokenise < "$CWD_DIR/$(cat "$1")" | tee debug.tmp | createlots )
	    #echo exprs $exprs >&2
	    for expr in $exprs ; do
	        #echo evaluating $(print $expr) >&2
		result=$(eval_impl "$expr")
		#echo evaluating $expr gives $result >&2
	    done
	    echo "$result"
	else
	    echo Cannot read "$CWD_DIR/$(cat "$1")" >&2
	    return 1
	fi
    else
	echo load must specify file name >&2
	return 1
    fi 
}

function createlots() {
    while true ; do
	expr=$(create)
	#echo createlots - next expr is $expr >&2
	if [[ $expr == EOF ]] ; then
	    break
	else
	    echo -n "$expr "
	fi
    done
}

function install_implementations() {
    declare -F | cut -d ' ' -f3 | while read -r fnc; do
	if [[ $fnc =~ .*_form_impl ]] ; then
	    fname=${fnc%_form_impl}
	    bind "$fname" ".subf_$fname"
	elif [[ $fnc =~ .*_form2_impl ]] ; then
	    fname=${fnc%_form2_impl}
	    bind "$fname" ".subf2_$fname"
	elif [[ $fnc =~ .*_func_impl ]] ; then
	    fname=${fnc%_func_impl}
	    bind "$fname" ".subr_$fname"
	fi
    done
}

