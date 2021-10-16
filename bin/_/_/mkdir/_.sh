#!/bin/bash

:mkdir:()
{
   local __mkdir________Options
   __mkdir________Options=$(getopt -o 'm:o:' -l 'mode:,owner:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__mkdir________Options"

   local __mkdir________Owner=
   local __mkdir________Mode=
   while true ; do
      case "$1" in
      -m|--mode)  __mkdir________Mode="$2"; shift 2;;
      -o|--owner) __mkdir________Owner="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $__mkdir________Owner && ! $__mkdir________Owner =~ : ]]; then
      local __mkdir________Group
      __mkdir________Group="$(id -ng "$__mkdir________Owner")"
      __mkdir________Owner="$__mkdir________Owner:$__mkdir________Group"
   fi

   ########################################
   # Reduce directory list to minimal set #
   ########################################
   local -a __mkdir________Paths
   :file:distinct_paths --var __mkdir________Paths "$@"          # Optimize the list of directories to create

   local -a __mkdir________Array
   local __mkdir________Path
   for __mkdir________Path in "${__mkdir________Paths[@]}"; do
      :log: ":mkdir: $__mkdir________Path"

      __mkdir________Path="$(readlink -fm "$__mkdir________Path")"             # Normalize the path to an absolute path
      :string:to_array --delim / --var __mkdir________Array "$__mkdir________Path"
                                                         # Convert the path string to an array of directory items
      local __mkdir________Dir=
      local __mkdir________Item
      for __mkdir________Item in "${__mkdir________Array[@]}"; do
         if [[ ${__mkdir________Dir: -1} = / ]]; then
            __mkdir________Dir+="$__mkdir________Item"
         else
            __mkdir________Dir+="/$__mkdir________Item"
         fi

         if [[ ! -e $__mkdir________Dir ]]; then                    # Try to make the directory if it doesn't exist
            if ! mkdir -p "$__mkdir________Dir" 2>/dev/null; then
               if ! sudo mkdir -p "$__mkdir________Dir" 2>/dev/null; then
                  :error: 1 "Cannot mkdir $__mkdir________Dir"
               fi
            fi

            if [[ -n $__mkdir________Owner ]]; then
               if ! chown "$__mkdir________Owner" "$__mkdir________Dir" 2>/dev/null; then
                  if ! sudo chown "$__mkdir________Owner" "$__mkdir________Dir" 2>/dev/null; then
                     :error: 1 "Cannot chown $__mkdir________Owner $__mkdir________Dir"
                  fi
               fi
            fi

            if [[ -n $__mkdir________Mode ]]; then
               if ! chmod "$__mkdir________Mode" "$__mkdir________Dir" 2>/dev/null; then
                  if ! sudo chmod "$__mkdir________Mode" "$__mkdir________Dir" 2>/dev/null; then
                     :error: 1 "Cannot chmod $__mkdir________Mode $__mkdir________Dir"
                  fi
               fi
            fi

         elif [[ ! -d $__mkdir________Dir ]]; then
            :error: 1 "Cannot mkdir $__mkdir________Dir"
         fi
      done
   done
}
