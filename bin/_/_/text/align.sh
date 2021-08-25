#!/bin/bash

:text:align()
{
   local ___text__align__align___Options
   ___text__align__align___Options=$(getopt -o 'd:' -l 'delimiter:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___text__align__align___Options"

   local ___text__align__align___Delimiter='|'

   while true ; do
      case "$1" in
      -d|--delimiter)   ___text__align__align___Delimiter="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   LC_ALL=C sed "s~$___text__align__align___Delimiter~\x01~" | column -t -s $'\x01'
}
