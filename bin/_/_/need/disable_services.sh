#!/bin/bash

:need:disable_services:linux()
{
   :sudo || :reenter                                     # This function must run as root

   (( $# > 0 )) || return

   local __need__disable_services__linux___Options
   __need__disable_services__linux___Options=$(getopt -o '' -l 'suffix:,no-suffix' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__need__disable_services__linux___Options"

   local __need__disable_services__linux___Suffix='.service'
   while true ; do
      case "$1" in
      --suffix)      __need__disable_services__linux___Suffix="$2"; shift 2;;
      --no-suffix)   __need__disable_services__linux___Suffix=; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   :log: --push-section 'Disabling services' "$FUNCNAME $@"

   local __need__disable_services__linux___Service
   for __need__disable_services__linux___Service in "$@"; do
      __need__disable_services__linux___Service+="$__need__disable_services__linux___Suffix"                         # Service names end with .service

      if [[ $( systemctl list-unit-files "$__need__disable_services__linux___Service" |
               grep "$__need__disable_services__linux___Service" |
               awk '{print $2}'
            ) = enabled ]] ; then

         :log: --push "Disabling service: $__need__disable_services__linux___Service"

         systemctl stop "$__need__disable_services__linux___Service"
         systemctl disable "$__need__disable_services__linux___Service"
         systemctl mask "$__need__disable_services__linux___Service"

         :log: --pop
      fi
   done

   :log: --pop
}
