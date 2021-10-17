#!/bin/bash

.dev:need:disable_services:linux()
{
   :sudo || :reenter                                     # This function must run as root

   (( $# > 0 )) || return

   local _dev__need__disable_services__linux___Options
   _dev__need__disable_services__linux___Options=$(getopt -o '' -l 'suffix:,no-suffix' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__need__disable_services__linux___Options"

   local _dev__need__disable_services__linux___Suffix='.service'
   while true ; do
      case "$1" in
      --suffix)      _dev__need__disable_services__linux___Suffix="$2"; shift 2;;
      --no-suffix)   _dev__need__disable_services__linux___Suffix=; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   :log: --push-section 'Disabling services' "$FUNCNAME $@"

   local _dev__need__disable_services__linux___Service
   for _dev__need__disable_services__linux___Service in "$@"; do
      _dev__need__disable_services__linux___Service+="$_dev__need__disable_services__linux___Suffix"                         # Service names end with .service

      if [[ $( systemctl list-unit-files "$_dev__need__disable_services__linux___Service" |
               grep "$_dev__need__disable_services__linux___Service" |
               awk '{print $2}'
            ) = enabled ]] ; then

         :log: --push "Disabling service: $_dev__need__disable_services__linux___Service"

         systemctl stop "$_dev__need__disable_services__linux___Service"
         systemctl disable "$_dev__need__disable_services__linux___Service"
         systemctl mask "$_dev__need__disable_services__linux___Service"

         :log: --pop
      fi
   done

   :log: --pop
}
