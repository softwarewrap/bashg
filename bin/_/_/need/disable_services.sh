#!/bin/bash

:need:disable_services:linux()
{
   :sudo || :reenter                                     # This function must run as root

   (( $# > 0 )) || return

   local ___need__disable_services__linux___Options
   ___need__disable_services__linux___Options=$(getopt -o '' -l 'suffix:,no-suffix' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___need__disable_services__linux___Options"

   local ___need__disable_services__linux___Suffix='.service'
   while true ; do
      case "$1" in
      --suffix)      ___need__disable_services__linux___Suffix="$2"; shift 2;;
      --no-suffix)   ___need__disable_services__linux___Suffix=; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   :log: --push-section 'Disabling services' "$FUNCNAME $@"

   local ___need__disable_services__linux___Service
   for ___need__disable_services__linux___Service in "$@"; do
      ___need__disable_services__linux___Service+="$___need__disable_services__linux___Suffix"                         # Service names end with .service

      if [[ $( systemctl list-unit-files "$___need__disable_services__linux___Service" |
               grep "$___need__disable_services__linux___Service" |
               awk '{print $2}'
            ) = enabled ]] ; then

         :log: --push "Disabling service: $___need__disable_services__linux___Service"

         systemctl stop "$___need__disable_services__linux___Service"
         systemctl disable "$___need__disable_services__linux___Service"
         systemctl mask "$___need__disable_services__linux___Service"

         :log: --pop
      fi
   done

   :log: --pop
}
