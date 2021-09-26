#!/bin/bash

# If it is necessary to escape a string so that sed does not treat
# the string as a regex, this function can used to preprocess.
+ escape()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'n' -l 'newlines' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_EscapeNewlines=false
   while true ; do
      case "$1" in
      -n|--newlines)    (.)_EscapeNewlines=true; shift;;
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
      if $(.)_EscapeNewlines; then
         LC_ALL=C sed -- ':a;N;$!ba;s/\n/\\n/g'
      else
         cat
      fi
   }
}
