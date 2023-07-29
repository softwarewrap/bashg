#!/bin/bash

# If it is necessary to escape a string so that sed does not treat
# the string as a regex, this function can used to preprocess.
:sed:escape()
{
   local __sed__escape__escape___Options
   __sed__escape__escape___Options=$(getopt -o 'n' -l 'newlines' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__sed__escape__escape___Options"

   local __sed__escape__escape___EscapeNewlines=false
   while true ; do
      case "$1" in
      -n|--newlines)    __sed__escape__escape___EscapeNewlines=true; shift;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   {
      if (( $# > 0 )); then
         awk '{ gsub(/[][^$.*?+\\()&\/]/, "\\\\&"); print }' <<<"$@"
      else
         awk '{ gsub(/[][^$.*?+\\()&\/]/, "\\\\&"); print }'
      fi
   } |
   {
      if $__sed__escape__escape___EscapeNewlines; then
         LC_ALL=C sed -- ':a;N;$!ba;s/\n/\\n/g'
      else
         cat
      fi
   }
}
