#!/bin/bash

:need:packages:()
{
   :sudo || :reenter                                     # This function must run as root

   local __need__packages_____Package
   for __need__packages_____Package in "$@"; do
      if ! rpm -q "$__need__packages_____Package" &>/dev/null; then
         if ! yum -y install "$__need__packages_____Package" &>/dev/null; then
            :error: 1 "Failed to install package $__need__packages_____Package"
         fi
      fi
   done
}
