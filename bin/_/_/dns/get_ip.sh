#!/bin/bash

:dns:get_ip()
{
   :sudo || :reenter                                     # This function must run as root

   local __dns__get_ip__get_ip___Options
   __dns__get_ip__get_ip___Options=$(getopt -o 'v:' -l 'var:' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$__dns__get_ip__get_ip___Options"

   local __dns__get_ip__get_ip___Var='__dns__get_ip__get_ip___UnspecifiedVar'                    # If unspecified, then emit to stdout

   while true ; do
      case "$1" in
      -v|--var)   __dns__get_ip__get_ip___Var="$2"; shift 2;;

      -h|--help)  $FUNCNAME%HELP; return 0;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   printf -v "$__dns__get_ip__get_ip___Var" "$(
      ip route get 1 |
      sed 's/^.*src \([^ ]*\).*$/\1/;q'
   )"

   if [[ $__dns__get_ip__get_ip___Var = __dns__get_ip__get_ip___UnspecifiedVar ]]; then
      echo "$__dns__get_ip__get_ip___UnspecifiedVar"                         # Emit the IP address to stdout
   fi
}
