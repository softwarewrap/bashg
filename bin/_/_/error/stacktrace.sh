#!/bin/bash

:error:stacktrace()
{
   local -a __error__stacktrace__stacktrace___Args=()
   local -i __error__stacktrace__stacktrace___I
   local -i __error__stacktrace__stacktrace___First=${BASH_ARGC[1]}+${BASH_ARGC[0]}-1
   local -i __error__stacktrace__stacktrace___Last=${BASH_ARGC[0]}

   for (( __error__stacktrace__stacktrace___I=$__error__stacktrace__stacktrace___First; __error__stacktrace__stacktrace___I >= $__error__stacktrace__stacktrace___Last; __error__stacktrace__stacktrace___I-- ));do
      __error__stacktrace__stacktrace___Args[__error__stacktrace__stacktrace___First-__error__stacktrace__stacktrace___I]=${BASH_ARGV[__error__stacktrace__stacktrace___I]}
   done

cat <<EOF

Command:
   ${FUNCNAME[1]} ${__error__stacktrace__stacktrace___Args[@]}

Stacktrace:
EOF

   local -i __error__stacktrace__stacktrace___frame
   local -i __error__stacktrace__stacktrace___lastframe=${#BASH_SOURCE[@]}-1
   for (( __error__stacktrace__stacktrace___frame=1; __error__stacktrace__stacktrace___frame < __error__stacktrace__stacktrace___lastframe - 2; __error__stacktrace__stacktrace___frame++ )); do
      caller $__error__stacktrace__stacktrace___frame
   done | awk '{$NF=""; print $0}' | sed 's/^/   /'
}
