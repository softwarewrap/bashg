#!/bin/bash

:require:packages()
{
   local -i __require__packages__packages___Return=0

   local __require__packages__packages___Installer
   local __require__packages__packages___Package

   for __require__packages__packages___Package in "$@"; do
      if ! rpm -q "$__require__packages__packages___Package" &>/dev/null; then
         __require__packages__packages___Installer="install_package_$( printf "$__require__packages__packages___Package" | tr -c 'a-zA-Z0-9_' '_' )"

         if :: --has-func "$__require__packages__packages___Installer"; then
            :: "$__require__packages__packages___Installer"

         else
            :error: 0 "Package not installed: $__require__packages__packages___Package"
            __require__packages__packages___Return=1
         fi
      fi
   done

   return $__require__packages__packages___Return
}
