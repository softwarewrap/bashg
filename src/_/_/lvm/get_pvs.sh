#!/bin/bash

+ get_pvs%HELP()
{
   local (.)_Synopsis='Get the list of physical volume names'

   :help: --set "$(.)_Synopsis" <<EOF
OPTIONS:
   -v|--var <array-name>   ^Store the results in the named array

DESCRIPTION:
   Get the list of physical volumes

   The list of physical volumes is stored in <array-name> if --var is specified;
   otherwise, the list is emitted to stdout.
EOF
}

+ get_pvs()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Var

   local (.)_Options
   (.)_Options=$(getopt -o 'v:' -l 'var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Var='(.)_UnspecifiedVar'                    # By default, store the results locally
   local -a (.)_UnspecifiedVar                           # Create a local array (not used if --var is specified)

   while true ; do
      case "$1" in
      -v|--var)   (.)_Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   readarray -t "$(.)_Var" < <(
      (-:launcher):CloseCustomFDs                        # lvm(1): requires only the std file descriptors are open

      pvs --noheadings -o pv_name |                      # Get the list of pvs; leading/trailing spaces are present
      sed 's/^\s*\([^ ]*\)\s*$/\1/' |                    # Trim whitespace
      LC_ALL=C sort -V                                   # Sort numerically: helps to get the next available PV name
   )

   if [[ $(.)_Var = (.)_UnspecifiedVar && ${#(.)_UnspecifiedVar[@]} -gt 0 ]]; then
      printf '%s\n' "${(.)_UnspecifiedVar[@]}"           # Emit array if not storing and size > 0
   fi
}
