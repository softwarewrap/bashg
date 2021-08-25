#!/bin/bash

:error:stacktrace()
{
   local -a ___error__stacktrace__stacktrace___Args=()
   local -i ___error__stacktrace__stacktrace___I
   local -i ___error__stacktrace__stacktrace___First=${BASH_ARGC[1]}+${BASH_ARGC[0]}-1
   local -i ___error__stacktrace__stacktrace___Last=${BASH_ARGC[0]}

   for (( ___error__stacktrace__stacktrace___I=$___error__stacktrace__stacktrace___First; ___error__stacktrace__stacktrace___I >= $___error__stacktrace__stacktrace___Last; ___error__stacktrace__stacktrace___I-- ));do
      ___error__stacktrace__stacktrace___Args[___error__stacktrace__stacktrace___First-___error__stacktrace__stacktrace___I]=${BASH_ARGV[___error__stacktrace__stacktrace___I]}
   done

cat <<EOF

Command:
   ${FUNCNAME[1]} ${___error__stacktrace__stacktrace___Args[@]}

Stacktrace:
EOF

   local -i ___error__stacktrace__stacktrace___frame
   local -i ___error__stacktrace__stacktrace___lastframe=${#BASH_SOURCE[@]}-1
   for (( ___error__stacktrace__stacktrace___frame=1; ___error__stacktrace__stacktrace___frame < ___error__stacktrace__stacktrace___lastframe - 2; ___error__stacktrace__stacktrace___frame++ )); do
      caller $___error__stacktrace__stacktrace___frame
   done | awk '{$NF=""; print $0}' | sed 's/^/   /'
}
