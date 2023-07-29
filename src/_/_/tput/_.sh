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
         ! ${(+:launcher)_Config[HasColor]} || (.)_Code="$( tput "$@" )"

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

+ highlight_on()
{
   local (.)_Var="${1:-(.)_UnassignedVar}"               # The variable to set

   if ! ${(+:launcher)_Config[HasColor]}; then
      printf -v "$(.)_Var" ''

   elif tput "$@" &>/dev/null; then
      printf -v "$(.)_Var" '%s' "$(tput setab 226)$(tput setaf 232)"

   else
      printf -v "$(.)_Var" '%s' $'\E[48;5;226m\E[30m'
   fi
}

+ highlight_off()
{
   local (.)_Var="${1:-(.)_UnassignedVar}"               # The variable to set

   if ! ${(+:launcher)_Config[HasColor]}; then
      printf -v "$(.)_Var" ''

   elif tput "$@" &>/dev/null; then
      printf -v "$(.)_Var" "$(tput op)"

   else
      printf -v "$(.)_Var" $'\E[39;49m'
   fi
}
