#!/bin/bash

+ get_ip()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o 'v:' -l 'var:' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Var='(.)_UnspecifiedVar'                    # If unspecified, then emit to stdout

   while true ; do
      case "$1" in
      -v|--var)   (.)_Var="$2"; shift 2;;

      -h|--help)  $FUNCNAME%HELP; return 0;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   printf -v "$(.)_Var" "$(
      ip route get 1 |
      sed 's/^.*src \([^ ]*\).*$/\1/;q'
   )"

   if [[ $(.)_Var = (.)_UnspecifiedVar ]]; then
      echo "$(.)_UnspecifiedVar"                         # Emit the IP address to stdout
   fi
}
