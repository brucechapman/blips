#!/bin/bash
#
function parse_s_expression() {
    headcons=
    while true; do
	if read -r line;  then
	    if [[ "$line" == '(' ]]; then
		next=$(parse_s_expression)
		while [[ $next != ')' ]] ; do
		    if [[ $next == EOF ]] ; then
			#echo EOF
			echo -n '>' >&2
			break
		    fi
		    nextcons=$(mktemp -u .cons_XXXX)
		    if [ -z "$headcons" ] ; then
			headcons=$nextcons
		    else
			ln -s "../$nextcons" "$prevcons/cdr"
		    fi
		    prevcons=$nextcons
		    mkdir "$nextcons"
		    ln -s "../$next" "$nextcons/car"
		    next=$(parse_s_expression)
		done
		if [[ $next == EOF ]] ; then
		    break
		fi
		if [[ $headcons ]] ; then
		    ln -s ../nil "$nextcons/cdr"
		    echo "$headcons"
		else
		    echo nil
		fi
		break
	    elif [[ $line == ')' ]] ; then
		echo "$line"
		break
	    elif echo "$line" | grep -q -E '^\-?[0-9]+$' ; then
	        make_int "$line"
		break
	    elif echo "$line" | grep -q -E '^"' ; then
		str=$(mktemp -u .str_XXXX)
		echo "$line" | sed -e 's/^"//' -e 's/"$//' > "$str"
		echo "$str"
		break
	    else
		# assume a symbol (once we deal with floats)
		if [ ! -f "$line" ] && [  ! -h "$line" ] ; then
		    touch "$line"
		fi
		echo "$line"
		break
	    fi
	    echo "$line"
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
    # shellcheck disable=1004
    sed -E -e 's/"([^"]|\\")*"/\
&\
/g'
}

function parens_to_own_line() {
    # shellcheck disable=1004
    sed  -e 's/(/\
(\
/g' | sed  -e 's/)/\
)\
/g' 
}


function tokens_to_own_line() {
    # shellcheck disable=1004
    sed -E -e '/^[^"]/s/[ 	]+/\
/g' 
}


function remove_blank_lines() {
    grep -vE '^	*$'
}

function tokenise() {
    remove_comments | strings_to_own_line |parens_to_own_line | tokens_to_own_line |remove_blank_lines
}

function read_s_expression() {
    tokenise | parse_s_expression
}


