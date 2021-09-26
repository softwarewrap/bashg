#!/bin/bash

+ set()
{
   if [[ $# -lt 2 ]]; then
      :error: 1 'Variable and tput settings are required'
      return
   fi

   local (.)_Var="${1:-(.)_UnassignedVar}"               # The variable to set
   shift

   local (.)_Code=

   if [[ $1 = -- ]]; then
      (.)_Code="$2"

   else
      if tput "$@" &>/dev/null; then
         (.)_Code="$( tput "$@" )"

      elif [[ $1 = cols ]]; then
         if [[ -n $COLUMNS ]]; then
            (.)_Code="$COLUMNS"
         else
            (.)_Code='120'
         fi
      fi
   fi

   [[ -v $(.)_Var ]] || local -g "$(.)_Var"              # Ensure the variable exists

   printf -v "$(.)_Var" '%s' "$(.)_Code"
}
