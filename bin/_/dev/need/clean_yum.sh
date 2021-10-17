#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

.dev:need:clean_yum:()
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
   local -A _dev__need__clean_yum_____PackageList

   local Package
   for _dev__need__clean_yum_____Package in $(rpm -qa); do                     # Gather installed RPM package list
      _dev__need__clean_yum_____PackageList[$_dev__need__clean_yum_____Package]=1
   done

   for _dev__need__clean_yum_____Path in /var/lib/yum/yumdb/?/*; do
      _dev__need__clean_yum_____Package=${_dev__need__clean_yum_____Path#*-}                         # Extract package name out of path
      _dev__need__clean_yum_____Package=${_dev__need__clean_yum_____Package%-*}.${_dev__need__clean_yum_____Package##*-}

      if [[ -z ${_dev__need__clean_yum_____PackageList[$_dev__need__clean_yum_____Package]} ]]; then # If the yum package is not in the RPM package list
         rm -rf "$_dev__need__clean_yum_____Path"                              # ... then remove the unused path
      fi
   done

   ################################################
   # Ensure Cache is Rebuilt and Packages Updated #
   ################################################
   yum clean all                                         # Post: Clean yum cache

   yum -y update                                         # Rebuild the cache

   :log: --pop
}
