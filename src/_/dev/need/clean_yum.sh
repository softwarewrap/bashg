#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

- ()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Cleaning the yum and rpm cache' "$FUNCNAME $@"

   yum clean all                                         # Pre: Clean yum cache

   ########################
   # Manual Cache Cleanup #
   ########################
   rm -rf /var/cache/yum
   mkdir -p /var/lib/rpm-state                           # See: https://access.redhat.com/solutions/3573891

   yum -y update                                         # Perform initial update

   rm -f /var/lib/rpm/__db*                              # Rebuild RPM DB
   rpm --rebuilddb

   ##########################
   # Remove unused packages #
   ##########################
   local -A (.)_PackageList

   local Package
   for (.)_Package in $(rpm -qa); do                     # Gather installed RPM package list
      (.)_PackageList[$(.)_Package]=1
   done

   for (.)_Path in /var/lib/yum/yumdb/?/*; do
      (.)_Package=${(.)_Path#*-}                         # Extract package name out of path
      (.)_Package=${(.)_Package%-*}.${(.)_Package##*-}

      if [[ -z ${(.)_PackageList[$(.)_Package]} ]]; then # If the yum package is not in the RPM package list
         rm -rf "$(.)_Path"                              # ... then remove the unused path
      fi
   done

   ################################################
   # Ensure Cache is Rebuilt and Packages Updated #
   ################################################
   yum clean all                                         # Post: Clean yum cache

   yum -y update                                         # Rebuild the cache

   :log: --pop
}
