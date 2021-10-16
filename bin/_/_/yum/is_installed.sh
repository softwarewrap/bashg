#!/bin/bash

:yum:is_installed()
{
   local __yum__is_installed__is_installed___Options
   __yum__is_installed__is_installed___Options=$(getopt -o '' -l 'environment,group' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__yum__is_installed__is_installed___Options"

   local __yum__is_installed__is_installed___IsEnvironment=false
   local __yum__is_installed__is_installed___IsGroup=false
   while true ; do
      case "$1" in
      --environment) __yum__is_installed__is_installed___IsEnvironment=true; shift;;
      --group)       __yum__is_installed__is_installed___IsGroup=true; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   if $__yum__is_installed__is_installed___IsEnvironment && $__yum__is_installed__is_installed___IsGroup; then
      :error: 1 'The options --environment and --group cannot be used together'
   fi

   local __yum__is_installed__is_installed___Name="$1"

   if [[ -z $__yum__is_installed__is_installed___Name ]]; then
      :error: 2 'A group or package name must be specified'
   fi

   if $__yum__is_installed__is_installed___IsEnvironment; then
      yum grouplist |                                    # Get the list of install env and regular groups
      sed '
         /^Installed Environment Groups:/,$!d            # Delete OTHER than between Installed... and END
         /^Available Environment Groups:/,$d             # Delete from Available... and END
         /^Installed Environment Groups:/d               # Delete the heading line: Installed...
         s/^[[:space:]]*//                               # Remove leading spaces
         ' |
      grep -q "$__yum__is_installed__is_installed___Name"

   elif $__yum__is_installed__is_installed___IsGroup; then
      yum grouplist |                                    # Get the list of install env and regular groups
      sed '
         /^Installed Groups:/,$!d                        # Delete OTHER than between Installed... and END
         /^Available Groups:/,$d                         # Delete from Available... and END
         /^Installed Groups:/d                           # Delete the heading line: Installed...
         s/^[[:space:]]*//                               # Remove leading spaces
         ' |
      grep -q "$__yum__is_installed__is_installed___Name"

   else
      rpm --quiet -q "$__yum__is_installed__is_installed___Name"                         # Determine if the package is installed
   fi
}
