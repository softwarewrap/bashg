#!/bin/bash

:dns:get_nic()
{
   :sudo || :reenter                                     # This function must run as root

   local __dns__get_nic__get_nic___Options
   __dns__get_nic__get_nic___Options=$(getopt -o 'v:' -l 'var:' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$__dns__get_nic__get_nic___Options"

   local __dns__get_nic__get_nic___Var='__dns__get_nic__get_nic___UnspecifiedVar'                    # If unspecified, then emit to stdout

   while true ; do
      case "$1" in
      -v|--var)   __dns__get_nic__get_nic___Var="$2"; shift 2;;

      -h|--help)  $FUNCNAME%HELP; return 0;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   local -i __dns__get_nic__get_nic___Wait="${1:-1}"                           # Wait interval, start with 1 second
   local -i __dns__get_nic__get_nic___MaxWait="${2:-40}"                       # Max wait before giving up

   # There are many edge cases where a NIC name might not be valid; this function tries to get a good NIC name
   local __dns__get_nic__get_nic___FirstSample
   local __dns__get_nic__get_nic___SecondSample                                # File for sample data end

   __dns__get_nic__get_nic___FirstSample="$(mktemp)"
   __dns__get_nic__get_nic___SecondSample="$(mktemp)"

   :dns:get_nic:GetNetworkData >"$__dns__get_nic__get_nic___FirstSample"                # Get starting sample
   sleep $__dns__get_nic__get_nic___Wait                                       # Wait the interval
   :dns:get_nic:GetNetworkData >"$__dns__get_nic__get_nic___SecondSample"               # Get ending sample

   # Look for the NIC that is showing traffic
   local __dns__get_nic__get_nic___NIC
   __dns__get_nic__get_nic___NIC="$(comm -23 "$__dns__get_nic__get_nic___FirstSample" "$__dns__get_nic__get_nic___SecondSample" | tail -1 | awk '{print $1}' | sed 's/:$//')"
   /bin/rm -f "$__dns__get_nic__get_nic___FirstSample" "$__dns__get_nic__get_nic___SecondSample"     # Clean up

   if [[ -z $__dns__get_nic__get_nic___NIC && $__dns__get_nic__get_nic___Wait -le $MaxWait ]]; then  # If no data changes were observed...
      __dns__get_nic__get_nic___NIC="$( :dns:get_nic $(($__dns__get_nic__get_nic___Wait * 2)) )"      # then try again, doubling the wait time
   fi

   if [[ $__dns__get_nic__get_nic___Var = __dns__get_nic__get_nic___UnspecifiedVar ]]; then
      echo "$__dns__get_nic__get_nic___NIC"                                    # Emit the NIC (possibly the empty string)
   else
      printf -v "$__dns__get_nic__get_nic___Var" "$__dns__get_nic__get_nic___NIC"
   fi
}

:dns:get_nic:GetNetworkData()
{
   ip -s link show |                                     # Output information for all interfaces
   sed -e 's/^[0-9]*:\s*/###/'|                          # Lines that begin with a number begin info for a NIC.
   sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' |          # Concatenate lines until the next NIC entry.
   sed -e 's/###/\n/g' |                                 # And, normalize the lines after concatenation.
   sed -e '/^$/d' |                                      # Remove any empty lines
   grep -v "^\(lo\|qb\|qv\|tap\|br\)" |                  # Remove any known invalid NIC names
   sort                                                  # Normalize by sorting by NIC name
}
