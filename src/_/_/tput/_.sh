#!/bin/bash

+ set()
{
   if [[ $# -lt 2 ]]; then
      :error: 1 'Variable and tput settings are required'
      return
   fi

   local (.)_Var="${1:-(.)_UnassignedVar}"               # The variable to set
   shift

   local (.)_Code

   if [[ $1 = -- ]]; then
      (.)_Code="$2"

   elif [[ $1 = cols ]]; then
      (.)_Code="$(tput cols 2>/dev/null)" || true        # The number of columns
      if [[ -z $(.)_Code || ! $(.)_Code =~ ^[0-9]+$ ]]; then
         (.)_Code='120'
      fi

   elif ! (.)_Code="$( tput "$@" 2>/dev/null )"; then
      (.)_Code=
   fi

   [[ -v $(.)_Var ]] || local -g "$(.)_Var"              # Ensure the variable exists

   printf -v "$(.)_Var" '%s' "$(.)_Code"
}
