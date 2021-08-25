#!/bin/bash

+ stacktrace()
{
   local -a (.)_Args=()
   local -i (.)_I
   local -i (.)_First=${BASH_ARGC[1]}+${BASH_ARGC[0]}-1
   local -i (.)_Last=${BASH_ARGC[0]}

   for (( (.)_I=$(.)_First; (.)_I >= $(.)_Last; (.)_I-- ));do
      (.)_Args[(.)_First-(.)_I]=${BASH_ARGV[(.)_I]}
   done

cat <<EOF

Command:
   ${FUNCNAME[1]} ${(.)_Args[@]}

Stacktrace:
EOF

   local -i (.)_frame
   local -i (.)_lastframe=${#BASH_SOURCE[@]}-1
   for (( (.)_frame=1; (.)_frame < (.)_lastframe - 2; (.)_frame++ )); do
      caller $(.)_frame
   done | awk '{$NF=""; print $0}' | sed 's/^/   /'
}
