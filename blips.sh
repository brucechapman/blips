#!/bin/bash
#
function create() {
(
headcons=
#while true; do
#    if read line;  then
while read line ; do
        if [[ "$line" == '(' ]]; then
	    next=`create`
	    while [[ $next != ')' ]] ; do
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
	    ln -s ../nil $nextcons/cdr
	    echo $headcons
	    break
	elif [[ $line == ')' ]] ; then
	    echo $line
	    break
	elif echo $line | grep -q -E '^\-?[0-9]+$' ; then
	    int=.int_$line
	    if [ ! -r $int ] ; then
		touch $int
	    fi
	    echo $int
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
#    else
#	echo EOF
#    fi
done
echo EOF
)

}



function remove_comments() {
    sed -E -e 's/;.*$//' 
}

function strings_to_own_line() {
    sed -E -e 's/"([^"]|\")*"/\
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

#set -vx
tokenise | create




