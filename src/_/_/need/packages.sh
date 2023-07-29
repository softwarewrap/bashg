#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Package
   for (.)_Package in "$@"; do
      if ! rpm -q "$(.)_Package" &>/dev/null; then
         if ! yum -y install "$(.)_Package" &>/dev/null; then
            :error: 1 "Failed to install package $(.)_Package"
         fi
      fi
   done
}
