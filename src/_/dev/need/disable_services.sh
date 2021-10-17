#!/bin/bash

- linux()
{
   :sudo || :reenter                                     # This function must run as root

   (( $# > 0 )) || return

   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'suffix:,no-suffix' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Suffix='.service'
   while true ; do
      case "$1" in
      --suffix)      (.)_Suffix="$2"; shift 2;;
      --no-suffix)   (.)_Suffix=; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   :log: --push-section 'Disabling services' "$FUNCNAME $@"

   local (.)_Service
   for (.)_Service in "$@"; do
      (.)_Service+="$(.)_Suffix"                         # Service names end with .service

      if [[ $( systemctl list-unit-files "$(.)_Service" |
               grep "$(.)_Service" |
               awk '{print $2}'
            ) = enabled ]] ; then

         :log: --push "Disabling service: $(.)_Service"

         systemctl stop "$(.)_Service"
         systemctl disable "$(.)_Service"
         systemctl mask "$(.)_Service"

         :log: --pop
      fi
   done

   :log: --pop
}
