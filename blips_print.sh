#!/bin/bash
#
function create() {
    headcons=
    while true; do
	if read line;  then
	    if [[ "$line" == '(' ]]; then
		next=`create`
		while [[ $next != ')' ]] ; do
		    if [[ $next == EOF ]] ; then
			#echo EOF
			echo -n '>' >&2
			break
		    fi
		    nextcons=`mktemp -u .cons_XXXX`
		    if [ -z "$headcons" ] ; then
			headcons=$nextcons
		    else
			ln -s ../$nextcons $prevcons/cdr
		    fi
		    prevcons=$nextcons
		    mkdir $nextcons
		    ln -s ../$next $nextcons/car
		    next=`create`
		done
		if [[ $next == EOF ]] ; then
		    break
		fi
		if [[ $headcons ]] ; then
		    ln -s ../nil $nextcons/cdr
		    echo $headcons
		else
		    echo nil
		fi
		break
	    elif [[ $line == ')' ]] ; then
		echo $line
		break
	    elif echo $line | grep -q -E '^\-?[0-9]+$' ; then
	        make_int $line
		break
	    elif echo $line | grep -q -E '^"' ; then
		str=`mktemp -u .str_XXXX`
		echo $line | sed -e 's/^"//' -e 's/"$//' > $str
		echo $str
		break
	    else
		# assume a symbol (once we deal with floats)
		if [ ! -f $line ] ; then
		    touch $line
		fi
		echo $line
		break
	    fi
	    echo $line
	else
	    echo EOF
	    break 
	fi
    done
}

function make_int() {
    int=.int_$1
    if [ ! -r $int ] ; then
	touch $int
	echo $1 > $int
    fi
    echo $int
}

function remove_comments() {
    sed -E -e 's/;.*$//' 
}

function strings_to_own_line() {
    sed -E -e 's/"([^"]|\\")*"/\
&\
/g'
}

function parens_to_own_line() {
    sed  -e 's/(/\
(\
/g' | sed  -e 's/)/\
)\
/g' 
}


function tokens_to_own_line() {
    sed -E -e '/^[^"]/s/[ ]+/\
/g' 
}


function remove_blank_lines() {
    sed -e '/^$/d'
}

function tokenise() {
    remove_comments | strings_to_own_line |parens_to_own_line | tokens_to_own_line |remove_blank_lines
}


function print() {
    if [[ $1 =~ \.cons_.* ]] ; then
        echo -n '('
	ptr=$1
	while [[ $(basename $(readlink $ptr/cdr)) =~ \.cons_.* ]] ; do
	    (print $(basename $(readlink $ptr/car)))
	    echo -n ' '
	    ptr=$(basename $(readlink $ptr/cdr))
	done
	(print $(basename $(readlink $ptr/car)))
	if [[ $(basename $(readlink $ptr/cdr)) != nil ]] ; then
	    echo -n ' . '
	    (print $(basename $(readlink $ptr/cdr)))
	fi
	echo -n ')'

    elif [[ $1 =~ \.int_.* ]];  then
	echo -n `cat $1`
    elif [[ $1 =~ \.str_.* ]]; then
        echo -n '"'
	echo -n `cat $1`
	echo -n '"'
    else
	echo -n $1
    fi
}

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

# $1 is symbol $2 is a value
function bind() {
    if [ -r $1 ] ; then
	rm $1
    fi
    ln -s $2 $1
}

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

function quote_form_impl() {
    echo $1
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

function install_implementations() {
    declare -F | cut -d ' ' -f3 | while read fnc; do
	if [[ $fnc =~ .*_form_impl ]] ; then
	    fname=${fnc%_form_impl}
	    bind $fname .subf_$fname
	elif [[ $fnc =~ .*_func_impl ]] ; then
	    fname=${fnc%_func_impl}
	    bind $fname .subr_$fname
	fi
    done
}

install_implementations

expr=`tokenise | create`
#echo expr=$expr
result=`eval_impl $expr`
#set -vx
#echo result of eval=$result >&2
echo -n '='
print $result
echo ''

# close to garbage collector
# find -L . \( -depth 1 -a -name '.*' \) -prune -o -exec ls -l {} \;
# then touch the found files, also prune files newer than fixed file used for gc
# once all non garbage files are found as above then delete all files older than the fixed file
# but beware this
#./set
#./setq
#./x
#touch: ./x/.cons_I3XM: Too many levels of symbolic links
#./x/car
#./x/cdr
#./x/cdr/car
#./x/cdr/cdr
# this is better
# find -L . \( -depth 1 -a -name '.*' \) -prune -o -exec touch -h {} \; -print
