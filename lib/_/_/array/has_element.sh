#!/bin/bash

+ has_element%HELP()
{
   local (.)_Synopsis='Determine if an array has the given element'

   :help: --set "$(.)_Synopsis" --usage '<array-name> <string>' <<EOF
DESCRIPTION:
   Determine if an array has the given element string

   If <string> is an element of the given <array-name>, then return 0;
   otherwise, return non-zero.

SCRIPTING EXAMPLE:
   local -a \(.)_tagline=(Knowledge is Power)             ^# Create an array

   if :array:has_element \(.)_tagline Knowledge; then     ^# Perform the test
      echo "Yes, 'Knowledge' is in the array"            ^# Found
   else^
      echo "No, 'Knowledge' is not in the array"         ^# Not found
   fi^
EOF
}

+ has_element()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'match' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Match=false
   while true ; do
      case "$1" in
      --match) (.)_Match=true; shift;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   local (.)_ArrayName="$1"                              # The array name to be checked
   local (.)_String="$2"                                 # The string: see if this is an element of the array
   local (.)_Indirect="$(.)_ArrayName[*]"                # Create an indirection string: expand in place

   local IFS=$'\x01'                                     # Use $IFS to separate array entries
   if $(.)_Match; then
      # Perform an anchored RegEx match
      [[ "$IFS${!(.)_Indirect}$IFS" =~ $IFS${(.)_String} ]]

   else
      # Perform a literal string match
      [[ "$IFS${!(.)_Indirect}$IFS" =~ "$IFS${(.)_String}$IFS" ]]
                                                         # Return whether the String is in the string expansion
   fi
}
