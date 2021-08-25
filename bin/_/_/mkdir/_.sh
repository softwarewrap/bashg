#!/bin/bash

:mkdir:()
{
   local ___mkdir________Options
   ___mkdir________Options=$(getopt -o 'm:o:' -l 'mode:,owner:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___mkdir________Options"

   local ___mkdir________Owner=
   local ___mkdir________Mode=
   while true ; do
      case "$1" in
      -m|--mode)  ___mkdir________Mode="$2"; shift 2;;
      -o|--owner) ___mkdir________Owner="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $___mkdir________Owner && ! $___mkdir________Owner =~ : ]]; then
      local ___mkdir________Group
      ___mkdir________Group="$(id -ng "$___mkdir________Owner")"
      ___mkdir________Owner="$___mkdir________Owner:$___mkdir________Group"
   fi

   ########################################
   # Reduce directory list to minimal set #
   ########################################
   local -a ___mkdir________Paths
   :file:distinct_paths --var ___mkdir________Paths "$@"          # Optimize the list of directories to create

   local -a ___mkdir________Array
   local ___mkdir________Path
   for ___mkdir________Path in "${___mkdir________Paths[@]}"; do
      :log: ":mkdir: $___mkdir________Path"

      ___mkdir________Path="$(readlink -fm "$___mkdir________Path")"             # Normalize the path to an absolute path
      :string:to_array --delim / --var ___mkdir________Array "$___mkdir________Path"
                                                         # Convert the path string to an array of directory items
      local ___mkdir________Dir=
      local ___mkdir________Item
      for ___mkdir________Item in "${___mkdir________Array[@]}"; do
         if [[ ${___mkdir________Dir: -1} = / ]]; then
            ___mkdir________Dir+="$___mkdir________Item"
         else
            ___mkdir________Dir+="/$___mkdir________Item"
         fi

         if [[ ! -e $___mkdir________Dir ]]; then                    # Try to make the directory if it doesn't exist
            if ! mkdir -p "$___mkdir________Dir" 2>/dev/null; then
               if ! sudo mkdir -p "$___mkdir________Dir" 2>/dev/null; then
                  :error: 1 "Cannot mkdir $___mkdir________Dir"
               fi
            fi

            if [[ -n $___mkdir________Owner ]]; then
               if ! chown "$___mkdir________Owner" "$___mkdir________Dir" 2>/dev/null; then
                  if ! sudo chown "$___mkdir________Owner" "$___mkdir________Dir" 2>/dev/null; then
                     :error: 1 "Cannot chown $___mkdir________Owner $___mkdir________Dir"
                  fi
               fi
            fi

            if [[ -n $___mkdir________Mode ]]; then
               if ! chmod "$___mkdir________Mode" "$___mkdir________Dir" 2>/dev/null; then
                  if ! sudo chmod "$___mkdir________Mode" "$___mkdir________Dir" 2>/dev/null; then
                     :error: 1 "Cannot chmod $___mkdir________Mode $___mkdir________Dir"
                  fi
               fi
            fi

         elif [[ ! -d $___mkdir________Dir ]]; then
            :error: 1 "Cannot mkdir $___mkdir________Dir"
         fi
      done
   done
}
