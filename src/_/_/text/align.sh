#!/bin/bash

+ align()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'd:' -l 'delimiter:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Delimiter='|'

   while true ; do
      case "$1" in
      -d|--delimiter)   (.)_Delimiter="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   LC_ALL=C sed -e "s~^[^$(.)_Delimiter]*$~$(.)_Delimiter~" -e "s~$(.)_Delimiter~\x01~" |
   column -t -s $'\x01' |
   LC_ALL=C sed 's~\s*$~~'
}
