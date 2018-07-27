#!/bin/bash
#

if [ -n $1 ] && [ "$1" = -v ] ; then
    verbose_output=y
fi

function gc() {
    # shellcheck disable=2012
    if [ -n "$verbose_output" ] ; then
	b4=$(ls -a | wc | cut -c1-8)
    fi
    touch .gc_mark
    sleep 1
    touch -h -- *
    case $(uname) in 
	Darwin)
	    find -L . \
		\( -depth 1 -a \( -name '.*' -a ! -name '.stack'  \) \) -prune \
		-o -exec touch -h {} \; -exec touch -cam {} 2>/dev/null \; 
	    ;;
	Linux)
	    find -L -- * .stack* \
		-exec touch -h {} \; -exec touch -cam {} 2>.loops_errors \; 
	    grep 'loop detected'  .loops_errors | \
	        sed -e 's/find: File system loop detected; .//' \
		    -e 's/. is part.*//' | xargs touch -h
	    rm .loops_errors
	    ;;
    esac
    find . \( \! -newer .gc_mark \) -delete
    if [ -n "$verbose_output" ] ; then
	# shellcheck disable=2012
	afta=$(ls -a | wc | cut -c1-8)
	echo GC "$b4" to "$afta" >&2
    fi
}

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
CWD_DIR=$(pwd)
MEM_DIR=$CWD_DIR/.blips_memory
mkdir -p "$MEM_DIR"
touch "$MEM_DIR/garbageCounter"
rm -f "$MEM_DIR/.patch"

source blips_eval.sh
source blips_functions.sh
source blips_print.sh
source blips_read.sh
source blips_utils.sh

if [ -n "$verbose_output" ] ; then
    echo SRC_DIR="$SRC_DIR"
    echo MEM_DIR="$MEM_DIR"
    echo CWD_DIR="$CWD_DIR"
fi

cd "$MEM_DIR" || exit

install_implementations
bind T T

function repl() {
    while true ; do
	read -er -p '?: ' line
	if [[ "$line" == '!exit' ]] ; then
	    break
	fi
	expr=$(echo "$line" | read_s_expression )
	result=$(eval_impl "$expr")
	echo -n '='
	print "$result"
	echo ''
    done
}

repl

