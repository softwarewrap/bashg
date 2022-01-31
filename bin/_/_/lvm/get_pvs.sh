#!/bin/bash

:lvm:get_pvs%HELP()
{
   local __lvm__get_pvs__get_pvsHELP___Synopsis='Get the list of physical volume names'

   :help: --set "$__lvm__get_pvs__get_pvsHELP___Synopsis" <<EOF
OPTIONS:
   -v|--var <array-name>   ^Store the results in the named array

DESCRIPTION:
   Get the list of physical volumes

   The list of physical volumes is stored in <array-name> if --var is specified;
   otherwise, the list is emitted to stdout.
EOF
}

:lvm:get_pvs()
{
   :sudo || :reenter                                     # This function must run as root

   local __lvm__get_pvs__get_pvs___Var

   local __lvm__get_pvs__get_pvs___Options
   __lvm__get_pvs__get_pvs___Options=$(getopt -o 'v:' -l 'var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__lvm__get_pvs__get_pvs___Options"

   local __lvm__get_pvs__get_pvs___Var='__lvm__get_pvs__get_pvs___UnspecifiedVar'                    # By default, store the results locally
   local -a __lvm__get_pvs__get_pvs___UnspecifiedVar                           # Create a local array (not used if --var is specified)

   while true ; do
      case "$1" in
      -v|--var)   __lvm__get_pvs__get_pvs___Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   readarray -t "$__lvm__get_pvs__get_pvs___Var" < <(
      :lvm:launcher:CloseCustomFDs                        # lvm(1): requires only the std file descriptors are open

      pvs --noheadings -o pv_name |                      # Get the list of pvs; leading/trailing spaces are present
      sed 's/^\s*\([^ ]*\)\s*$/\1/' |                    # Trim whitespace
      LC_ALL=C sort -V                                   # Sort numerically: helps to get the next available PV name
   )

   if [[ $__lvm__get_pvs__get_pvs___Var = __lvm__get_pvs__get_pvs___UnspecifiedVar && ${#__lvm__get_pvs__get_pvs___UnspecifiedVar[@]} -gt 0 ]]; then
      printf '%s\n' "${__lvm__get_pvs__get_pvs___UnspecifiedVar[@]}"           # Emit array if not storing and size > 0
   fi
}
