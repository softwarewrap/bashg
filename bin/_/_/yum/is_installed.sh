#!/bin/bash

:yum:is_installed()
{
   local ___yum__is_installed__is_installed___Options
   ___yum__is_installed__is_installed___Options=$(getopt -o '' -l 'environment,group' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___yum__is_installed__is_installed___Options"

   local ___yum__is_installed__is_installed___IsEnvironment=false
   local ___yum__is_installed__is_installed___IsGroup=false
   while true ; do
      case "$1" in
      --environment) ___yum__is_installed__is_installed___IsEnvironment=true; shift;;
      --group)       ___yum__is_installed__is_installed___IsGroup=true; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   if $___yum__is_installed__is_installed___IsEnvironment && $___yum__is_installed__is_installed___IsGroup; then
      :error: 1 'The options --environment and --group cannot be used together'
   fi

   local ___yum__is_installed__is_installed___Name="$1"

   if [[ -z $___yum__is_installed__is_installed___Name ]]; then
      :error: 2 'A group or package name must be specified'
   fi

   if $___yum__is_installed__is_installed___IsEnvironment; then
      yum grouplist |                                    # Get the list of install env and regular groups
      sed '
         /^Installed Environment Groups:/,$!d            # Delete OTHER than between Installed... and END
         /^Available Environment Groups:/,$d             # Delete from Available... and END
         /^Installed Environment Groups:/d               # Delete the heading line: Installed...
         s/^[[:space:]]*//                               # Remove leading spaces
         ' |
      grep -q "$___yum__is_installed__is_installed___Name"

   elif $___yum__is_installed__is_installed___IsGroup; then
      yum grouplist |                                    # Get the list of install env and regular groups
      sed '
         /^Installed Groups:/,$!d                        # Delete OTHER than between Installed... and END
         /^Available Groups:/,$d                         # Delete from Available... and END
         /^Installed Groups:/d                           # Delete the heading line: Installed...
         s/^[[:space:]]*//                               # Remove leading spaces
         ' |
      grep -q "$___yum__is_installed__is_installed___Name"

   else
      rpm --quiet -q "$___yum__is_installed__is_installed___Name"                         # Determine if the package is installed
   fi
}
