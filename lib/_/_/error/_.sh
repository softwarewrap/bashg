#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis=''

   :help: --set "$(.)_Synopsis" --usage '[<return-status>] [<message>]' <<EOF
OPTIONS:
   -s|--stacktrace   ^Include a stack trace in the output

DESCRIPTION:
   Emit error information and return

   If <message> is included, then that message is emitted.

   If --stacktrace is specified, then also include a stack trace in the output.

   If <return-status>, an integer between 0 and 255 inclusive, is specified, then the return status
   for this command is the specified value.

   If the <return-status> is 0, then the message is emitted as a <b>Warning</b>.

RETURN STATUS:
   1  ^Is emitted if no explicit <return-status> is specified

SCRIPTING EXAMPLE:
   :error: --stacktrace 4 'A size must be specified'
EOF
}

+ ()
{
   local (.)_Options
   (.)_Options=$(getopt -o 's' -l 'stacktrace' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_ShowStacktrace=false
   while true ; do
      case "$1" in
      -s|--stacktrace)  (.)_ShowStacktrace=true; shift;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local (.)_Type='Error'                                # Used in the message display

   if [[ $1 =~ ^[0-9]+$ && $1 -ge 0 && $1 -le 255 ]]; then
      _return="$1"
      (( _return != 0 )) || (.)_Type='Warning'
      shift

   else
      _return=1                                          # No return code was provided: use 1 as a generic return code
   fi

   local IFS=
   :highlight: <<<"<b>[$(.)_Type: ${FUNCNAME[1]}]</b> $*"
                                                         # Emit standardized message
   if $(.)_ShowStacktrace; then
      (+):stacktrace                                     # Dump the calling stack
   fi

   return $_return                                       # Return
}
