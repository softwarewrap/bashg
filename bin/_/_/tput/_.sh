#!/bin/bash

:tput:set()
{
   if [[ $# -lt 2 ]]; then
      :error: 1 'Variable and tput settings are required'
      return
   fi

   local __tput_____set___Var="${1:-__tput_____set___UnassignedVar}"               # The variable to set
   shift

   local __tput_____set___Code=

   if [[ $1 = -- ]]; then
      __tput_____set___Code="$2"

   else
      if tput "$@" &>/dev/null; then
         __tput_____set___Code="$( tput "$@" )"

      elif [[ $1 = cols ]]; then
         if [[ -n $COLUMNS ]]; then
            __tput_____set___Code="$COLUMNS"
         else
            __tput_____set___Code='120'
         fi
      fi
   fi

   [[ -v $__tput_____set___Var ]] || local -g "$__tput_____set___Var"              # Ensure the variable exists

   printf -v "$__tput_____set___Var" '%s' "$__tput_____set___Code"
}
