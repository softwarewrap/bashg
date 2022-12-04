#!/bin/bash

:dns:get_host()
{
   local __dns__get_host__get_host___Options
   __dns__get_host__get_host___Options=$(getopt -o 'v:' -l 'var:' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$__dns__get_host__get_host___Options"

   local __dns__get_host__get_host___Var='__dns__get_host__get_host___UnspecifiedVar'                    # If unspecified, then emit to stdout

   while true ; do
      case "$1" in
      -v|--var)   __dns__get_host__get_host___Var="$2"; shift 2;;

      -h|--help)  $FUNCNAME%HELP; return 0;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   printf -v "$__dns__get_host__get_host___Var" "$(
      { host -TtA "$(hostname -f)" || true; } |          # Perform DNS lookup of the hostname, and get the A record
      { grep "has address" || true; } |                  # This will indicate A record lines
      tail -1 |                                          # Get at most just one entry (1 in most cases)
      awk '{print $1}'                                   # Get the symbolic name associated with the A record
   )"

   if [[ $__dns__get_host__get_host___Var = __dns__get_host__get_host___UnspecifiedVar ]]; then
      echo "$__dns__get_host__get_host___UnspecifiedVar"                         # Emit the hostname to stdout
   fi
}
