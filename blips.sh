#!/bin/bash
#

source blips_eval.sh
source blips_functions.sh
source blips_print.sh
source blips_read.sh
source blips_utils.sh

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
