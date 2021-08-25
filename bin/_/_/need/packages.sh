#!/bin/bash

:need:packages:()
{
   :sudo || :reenter                                     # This function must run as root

   local ___need__packages_____Package
   for ___need__packages_____Package in "$@"; do
      if ! rpm -q "$___need__packages_____Package" &>/dev/null; then
         if ! yum -y install "$___need__packages_____Package" &>/dev/null; then
            :error: 1 "Failed to install package $___need__packages_____Package"
         fi
      fi
   done
}
