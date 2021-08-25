#!/bin/bash

:require:packages()
{
   local -i ___require__packages__packages___Return=0

   local ___require__packages__packages___Installer
   local ___require__packages__packages___Package

   for ___require__packages__packages___Package in "$@"; do
      if ! rpm -q "$___require__packages__packages___Package" &>/dev/null; then
         ___require__packages__packages___Installer="install_package_$( printf "$___require__packages__packages___Package" | tr -c 'a-zA-Z0-9_' '_' )"

         if :: --has-func "$___require__packages__packages___Installer"; then
            :: "$___require__packages__packages___Installer"

         else
            :error: 0 "Package not installed: $___require__packages__packages___Package"
            ___require__packages__packages___Return=1
         fi
      fi
   done

   return $___require__packages__packages___Return
}
