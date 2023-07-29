#!/bin/bash

+ packages()
{
   local -i (.)_Return=0

   local (.)_Installer
   local (.)_Package

   for (.)_Package in "$@"; do
      if ! rpm -q "$(.)_Package" &>/dev/null; then
         (.)_Installer="install_package_$( printf "$(.)_Package" | tr -c 'a-zA-Z0-9_' '_' )"

         if :: --has-func "$(.)_Installer"; then
            :: "$(.)_Installer"

         else
            :error: 0 "Package not installed: $(.)_Package"
            (.)_Return=1
         fi
      fi
   done

   return $(.)_Return
}
