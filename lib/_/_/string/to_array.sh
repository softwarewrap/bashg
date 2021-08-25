#!/bin/bash

+ to_array()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'd:,v:' -l 'delim:,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Delim=','
   local (.)_Var='(.)_UnspecifiedVar'

   while true ; do
      case "$1" in
      -d|--delim) (.)_Delim="$2"; shift 2;;
      -v|--var)   (.)_Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   [[ -v $(.)_Var ]] || local -ag "$(.)_Var"

   local (.)_String="$1"
   readarray -t "$(.)_Var" < <(sed "s|$(.)_Delim|\n|g" <<<"$(.)_String")
}
