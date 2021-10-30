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
         ! ${__launcher___Config[HasColor]} || __tput_____set___Code="$( tput "$@" )"

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

:tput:highlight_on()
{
   local __tput_____highlight_on___Var="${1:-__tput_____highlight_on___UnassignedVar}"               # The variable to set

   if ! ${__launcher___Config[HasColor]}; then
      printf -v "$__tput_____highlight_on___Var" ''

   elif tput "$@" &>/dev/null; then
      printf -v "$__tput_____highlight_on___Var" '%s' "$(tput setab 226)$(tput setaf 232)"

   else
      printf -v "$__tput_____highlight_on___Var" '%s' $'\E[48;5;226m\E[30m'
   fi
}

:tput:highlight_off()
{
   local __tput_____highlight_off___Var="${1:-__tput_____highlight_off___UnassignedVar}"               # The variable to set

   if ! ${__launcher___Config[HasColor]}; then
      printf -v "$__tput_____highlight_off___Var" ''

   elif tput "$@" &>/dev/null; then
      printf -v "$__tput_____highlight_off___Var" "$(tput op)"

   else
      printf -v "$__tput_____highlight_off___Var" $'\E[39;49m'
   fi
}
