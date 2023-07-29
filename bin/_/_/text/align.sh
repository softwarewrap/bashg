#!/bin/bash

:text:align()
{
   local __text__align__align___Options
   __text__align__align___Options=$(getopt -o 'd:' -l 'delimiter:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__text__align__align___Options"

   local __text__align__align___Delimiter='|'

   while true ; do
      case "$1" in
      -d|--delimiter)   __text__align__align___Delimiter="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   LC_ALL=C sed -e "s~^[^$__text__align__align___Delimiter]*$~$__text__align__align___Delimiter~" -e "s~$__text__align__align___Delimiter~\x01~" |
   column -t -s $'\x01' |
   LC_ALL=C sed 's~\s*$~~'
}
