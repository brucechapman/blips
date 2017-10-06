#!/bin/bash
#

function print() {
    if [[ $1 =~ \.cons_.* ]] ; then
        echo -n '('
	ptr=$1
	while [[ -h $ptr/cdr && $(basename $(readlink $ptr/cdr)) =~ \.cons_.* ]] ; do
	    (print $(basename $(readlink $ptr/car)))
	    echo -n ' '
	    ptr=$(basename $(readlink $ptr/cdr))

	done
	(print $(basename $(readlink $ptr/car)))
	if [[ ! -h $ptr/cdr || $(basename $(readlink $ptr/cdr)) != nil ]] ; then
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

