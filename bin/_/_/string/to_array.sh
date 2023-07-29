#!/bin/bash

:string:to_array()
{
   local __string__to_array__to_array___Options
   __string__to_array__to_array___Options=$(getopt -o 'd:,v:' -l 'delim:,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__string__to_array__to_array___Options"

   local __string__to_array__to_array___Delim=','
   local __string__to_array__to_array___Var='__string__to_array__to_array___UnspecifiedVar'

   while true ; do
      case "$1" in
      -d|--delim) __string__to_array__to_array___Delim="$2"; shift 2;;
      -v|--var)   __string__to_array__to_array___Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   [[ -v $__string__to_array__to_array___Var ]] || local -ag "$__string__to_array__to_array___Var"

   local __string__to_array__to_array___String="$1"
   readarray -t "$__string__to_array__to_array___Var" < <(sed "s|$__string__to_array__to_array___Delim|\n|g" <<<"$__string__to_array__to_array___String")
}
