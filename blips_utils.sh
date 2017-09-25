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
    if [ -r $1 ] ; then
	rm $1
    fi
    ln -s $2 $1
}

