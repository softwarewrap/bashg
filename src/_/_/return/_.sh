#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Perform a function return'
   local (.)_Usage='[OPTIONS] [<return-value>]'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
OPTIONS:
   --emit <message>     ^Emit the provided message before returning
   --stacktrace         ^Emit a stacktrace for return values other than 0

DESCRIPTION:
   Perform any pre-steps and then return with a return value

   If --emit is specified, then emit via <B>:log:</B> or <B>:error:</B> the <message>,
   depending upon whether the return value is 0 or non-zero, respectively.
   If <message> is the empty string, then do not emit the message.

   The return value is a non-negative integer in the range of 0 to 255.
   If <return-value> is an integer outside of this range, then the return
   value is taken to be the absolute value modulo 256.

   If <return-value> is not an integer, then the behavior is presently
   undefined pending additional behaviors to be implemented.

   <R>Note:</R> In the above case, this function returns 0; but, this
   should not be relied on as, by specification, the behavior is not defined.

   If <return-value> is not specified, then return with a value of 0.

   If --stacktrace is specified and the return value is not 0, then
   emit a stacktrace after any <message> before returning.

EXAMPLES:
   :exit: 37   ^Return with the return value of 37
   :exit:      ^Return with the return value of 0
EOF
}

+ ()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'emit:,stacktrace' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Message=
   local (.)_Stacktrace=

   while true ; do
      case "$1" in
      --emit)        (.)_Message="$2"; shift 2;;
      --stacktrace)  (.)_Stacktrace='--stacktrace'; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local -i N="${1:-0}"                                  # A missing <return-value> is taken to be 0

   if [[ $N =~ ^-?[0-9]+$ ]]; then                       # If an integer
      if (( N < 0 )); then
         N="${N#-}"
      fi
      if (( N > 255 )); then
         N=$(( N % 256 ))
      fi

   else
      N=0                                                # Define some behavior; but, it cannot be relied on
   fi

   if [[ -n $(.)_Message ]]; then
      if (( N == 0 )); then
         :log: "$(.)_Message"

      else
         :error: $(.)_Stacktrace "$N" "$(.)_Message"
      fi

   else
      if [[ $N -gt 0 && -n $(.)_Stacktrace ]]; then
         (+:error):stacktrace
      fi

      return $N                                          # Quotes omitted: 0<= N <= 255 is guaranteed
   fi
}
