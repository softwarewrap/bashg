#!/bin/bash

:tput:set()
{
   if [[ $# -lt 2 ]]; then
      :error: 1 'Variable and tput settings are required'
      return
   fi

   local ___tput_____set___Var="${1:-___tput_____set___UnassignedVar}"               # The variable to set
   shift

   local ___tput_____set___Code=

   if [[ $1 = -- ]]; then
      ___tput_____set___Code="$2"

   else
      if tput "$@" &>/dev/null; then
         ___tput_____set___Code="$( tput "$@" )"

      elif [[ $1 = cols ]]; then
         if [[ -n $COLUMNS ]]; then
            ___tput_____set___Code="$COLUMNS"
         else
            ___tput_____set___Code='120'
         fi
      fi
   fi

   [[ -v $___tput_____set___Var ]] || local -g "$___tput_____set___Var"              # Ensure the variable exists

   printf -v "$___tput_____set___Var" '%s' "$___tput_____set___Code"
}
