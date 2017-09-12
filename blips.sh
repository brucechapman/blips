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
		int=.int_$line
		if [ ! -r $int ] ; then
		    touch $int
		    echo $line > $int
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
	else
	    echo EOF
	    break 
	fi
    done
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
	    (print $basename $readlink $ptr/cdr)
	fi
	echo -n ')'

    elif [[ $1 =~ \.int_.* ]];  then
	echo -n `cat $1`
    elif [[ $1 =~ \.str_.* ]]; then
        echo -n '"'
	echo -n `cat $1`
	echo '"'
    else
	echo -n $1
    fi
}


#set -vx
print `tokenise | create`

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
