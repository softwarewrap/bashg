#!/bin/bash

:need:disable_services:linux-6()
{
   :sudo || :reenter                                     # This function must run as root

   local ___Service="$1"

   if [[ -f /etc/init.d/$___Service ]]; then
      if [[ $(service "$___Service" status) =~ 'is running' ]]; then
         :log: --push "Stopping service: $___Service"

         service "$___Service" stop                     # Stop the service

         if [[ $(service "$___Service" status) =~ 'is running' ]]; then
            :log: "Failed to stop service: $___Service"
         fi

         rm -f "/etc/init.d/$___Service.disabled"       # Remove any existing 'disabled' file
         mv -f "/etc/init.d/$___Service" "/etc/init.d/$___Service.disabled"
         :log: "Renamed service to /etc/init.d/$___Service.disabled"

         :log: --pop
      fi
   fi
}

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
}
