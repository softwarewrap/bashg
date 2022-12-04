#!/bin/bash

+ get_host()
{
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
      { host -TtA "$(hostname -s)" || true; } |          # Perform DNS lookup of the hostname, and get the A record
      { grep "has address" || true; } |                  # This will indicate A record lines
      tail -1 |                                          # Get at most just one entry (1 in most cases)
      awk '{print $1}'                                   # Get the symbolic name associated with the A record
   )"

   if [[ $(.)_Var = (.)_UnspecifiedVar ]]; then
      echo "$(.)_UnspecifiedVar"                         # Emit the hostname to stdout
   fi
}
