#!/bin/bash

::yaml:to_json()
{
   local Options
   Options=$(getopt -o '' -l "var:" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$Options"

   local Var='UnspecifiedVar'

   while true ; do
      case "$1" in
      --var)   Var="$2"; shift 2;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   printf -v "$Var" '%s' "$(
      if (( $# > 0 )); then
         local File="$1"
         ruby -ryaml -rjson -e 'puts JSON.dump(YAML::load(STDIN.read))' < "$File"
      else
         ruby -ryaml -rjson -e 'puts JSON.dump(YAML::load(STDIN.read))'
      fi
   )"

   if [[ $Var = 'UnspecifiedVar' ]]; then
      echo "$UnspecifiedVar"
   fi
}
