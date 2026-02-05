#!/bin/bash

::string:to_array()
{
   local Options
   Options=$(getopt -o 'd:,v:' -l 'delim:,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$Options"

   local Delim=','
   local Var='UnspecifiedVar'

   while true ; do
      case "$1" in
      -d|--delim) Delim="$2"; shift 2;;
      -v|--var)   Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   [[ -v $Var ]] || local -ag "$Var"

   local String="$1"
   readarray -t "$Var" < <(sed "s|$Delim|\n|g" <<<"$String")
}
