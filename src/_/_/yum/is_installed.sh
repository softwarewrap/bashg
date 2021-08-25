#!/bin/bash

+ is_installed()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'environment,group' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_IsEnvironment=false
   local (.)_IsGroup=false
   while true ; do
      case "$1" in
      --environment) (.)_IsEnvironment=true; shift;;
      --group)       (.)_IsGroup=true; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   if $(.)_IsEnvironment && $(.)_IsGroup; then
      :error: 1 'The options --environment and --group cannot be used together'
   fi

   local (.)_Name="$1"

   if [[ -z $(.)_Name ]]; then
      :error: 2 'A group or package name must be specified'
   fi

   if $(.)_IsEnvironment; then
      yum grouplist |                                    # Get the list of install env and regular groups
      sed '
         /^Installed Environment Groups:/,$!d            # Delete OTHER than between Installed... and END
         /^Available Environment Groups:/,$d             # Delete from Available... and END
         /^Installed Environment Groups:/d               # Delete the heading line: Installed...
         s/^[[:space:]]*//                               # Remove leading spaces
         ' |
      grep -q "$(.)_Name"

   elif $(.)_IsGroup; then
      yum grouplist |                                    # Get the list of install env and regular groups
      sed '
         /^Installed Groups:/,$!d                        # Delete OTHER than between Installed... and END
         /^Available Groups:/,$d                         # Delete from Available... and END
         /^Installed Groups:/d                           # Delete the heading line: Installed...
         s/^[[:space:]]*//                               # Remove leading spaces
         ' |
      grep -q "$(.)_Name"

   else
      rpm --quiet -q "$(.)_Name"                         # Determine if the package is installed
   fi
}
