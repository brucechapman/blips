#!/bin/bash
#

function gc() {
    b4=$(ls -a | wc | cut -c1-8)
    touch .gc_mark
    sleep 1
    touch -h *
    find -L . \( -depth 1 -a \( -name '.*' -a ! -name '.stack'  \) \) -prune -o -exec touch -h {} \; -exec touch -cam {} 2>/dev/null \; 
    find . \( \! -newer .gc_mark \) -delete
    afta=$(ls -a | wc | cut -c1-8)
    echo GC $b4 to $afta >&2
}

SRC_DIR=$(cd $(dirname $0) && pwd)
CWD_DIR=$(pwd)
MEM_DIR=$CWD_DIR/.blips_memory
mkdir -p $MEM_DIR
touch $MEM_DIR/garbageCounter
rm -f $MEM_DIR/.patch

source blips_eval.sh
source blips_functions.sh
source blips_print.sh
source blips_read.sh
source blips_utils.sh

echo SRC_DIR=$SRC_DIR
echo MEM_DIR=$MEM_DIR
echo CWD_DIR=$CWD_DIR

cd $MEM_DIR

install_implementations
bind T T
function rep() {
expr=`tokenise | create`
    #echo expr=$expr
    result=`eval_impl $expr`
    #set -vx
    #echo result of eval=$result >&2
    echo -n '='
    print $result
    echo ''
}

function repl() {
    while [ true ] ; do
        #echo -n '?:'
	read -e -p '?: ' line
	if [[ $line == '!exit' ]] ; then
	    break
	fi
	expr=$(echo $line | tokenise | create )
	result=$(eval_impl $expr)
	echo -n '='
	print $result
	echo ''
    done
}
repl


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
