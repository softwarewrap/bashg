#!/bin/bash

:string:to_array()
{
   local ___string__to_array__to_array___Options
   ___string__to_array__to_array___Options=$(getopt -o 'd:,v:' -l 'delim:,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___string__to_array__to_array___Options"

   local ___string__to_array__to_array___Delim=','
   local ___string__to_array__to_array___Var='___string__to_array__to_array___UnspecifiedVar'

   while true ; do
      case "$1" in
      -d|--delim) ___string__to_array__to_array___Delim="$2"; shift 2;;
      -v|--var)   ___string__to_array__to_array___Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   [[ -v $___string__to_array__to_array___Var ]] || local -ag "$___string__to_array__to_array___Var"

   local ___string__to_array__to_array___String="$1"
   readarray -t "$___string__to_array__to_array___Var" < <(sed "s|$___string__to_array__to_array___Delim|\n|g" <<<"$___string__to_array__to_array___String")
}
