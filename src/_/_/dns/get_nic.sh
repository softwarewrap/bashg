#!/bin/bash

+ get_nic()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o 'v:' -l 'var:' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Var='(.)_UnspecifiedVar'                    # If unspecified, then emit to stdout

   while true ; do
      case "$1" in
      -v|--var)   (.)_Var="$2"; shift 2;;

      -h|--help)  $FUNCNAME%HELP; return 0;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   local -i (.)_Wait="${1:-1}"                           # Wait interval, start with 1 second
   local -i (.)_MaxWait="${2:-40}"                       # Max wait before giving up

   # There are many edge cases where a NIC name might not be valid; this function tries to get a good NIC name
   local (.)_FirstSample
   local (.)_SecondSample                                # File for sample data end

   (.)_FirstSample="$(mktemp)"
   (.)_SecondSample="$(mktemp)"

   (-):GetNetworkData >"$(.)_FirstSample"                # Get starting sample
   sleep $(.)_Wait                                       # Wait the interval
   (-):GetNetworkData >"$(.)_SecondSample"               # Get ending sample

   # Look for the NIC that is showing traffic
   local (.)_NIC
   (.)_NIC="$(comm -23 "$(.)_FirstSample" "$(.)_SecondSample" | tail -1 | awk '{print $1}' | sed 's/:$//')"
   /bin/rm -f "$(.)_FirstSample" "$(.)_SecondSample"     # Clean up

   if [[ -z $(.)_NIC && $(.)_Wait -le $(.)_MaxWait ]]; then
                                                         # If no data changes were observed...
      (.)_NIC="$( (+):get_nic $(($(.)_Wait * 2)) )"      # then try again, doubling the wait time
   fi

   if [[ $(.)_Var = (.)_UnspecifiedVar ]]; then
      echo "$(.)_NIC"                                    # Emit the NIC (possibly the empty string)
   else
      printf -v "$(.)_Var" "$(.)_NIC"
   fi
}

- GetNetworkData()
{
   ip -s link show |                                     # Output information for all interfaces
   sed -e 's/^[0-9]*:\s*/###/'|                          # Lines that begin with a number begin info for a NIC.
   sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' |          # Concatenate lines until the next NIC entry.
   sed -e 's/###/\n/g' |                                 # And, normalize the lines after concatenation.
   sed -e '/^$/d' |                                      # Remove any empty lines
   grep -v "^\(lo\|qb\|qv\|tap\|br\)" |                  # Remove any known invalid NIC names
   sort                                                  # Normalize by sorting by NIC name
}
