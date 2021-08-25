#!/bin/bash

+ ()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'm:o:' -l 'mode:,owner:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Owner=
   local (.)_Mode=
   while true ; do
      case "$1" in
      -m|--mode)  (.)_Mode="$2"; shift 2;;
      -o|--owner) (.)_Owner="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $(.)_Owner && ! $(.)_Owner =~ : ]]; then
      local (.)_Group
      (.)_Group="$(id -ng "$(.)_Owner")"
      (.)_Owner="$(.)_Owner:$(.)_Group"
   fi

   ########################################
   # Reduce directory list to minimal set #
   ########################################
   local -a (.)_Paths
   (+:file):distinct_paths --var (.)_Paths "$@"          # Optimize the list of directories to create

   local -a (.)_Array
   local (.)_Path
   for (.)_Path in "${(.)_Paths[@]}"; do
      :log: ":mkdir: $(.)_Path"

      (.)_Path="$(readlink -fm "$(.)_Path")"             # Normalize the path to an absolute path
      (+:string):to_array --delim / --var (.)_Array "$(.)_Path"
                                                         # Convert the path string to an array of directory items
      local (.)_Dir=
      local (.)_Item
      for (.)_Item in "${(.)_Array[@]}"; do
         if [[ ${(.)_Dir: -1} = / ]]; then
            (.)_Dir+="$(.)_Item"
         else
            (.)_Dir+="/$(.)_Item"
         fi

         if [[ ! -e $(.)_Dir ]]; then                    # Try to make the directory if it doesn't exist
            if ! mkdir -p "$(.)_Dir" 2>/dev/null; then
               if ! sudo mkdir -p "$(.)_Dir" 2>/dev/null; then
                  :error: 1 "Cannot mkdir $(.)_Dir"
               fi
            fi

            if [[ -n $(.)_Owner ]]; then
               if ! chown "$(.)_Owner" "$(.)_Dir" 2>/dev/null; then
                  if ! sudo chown "$(.)_Owner" "$(.)_Dir" 2>/dev/null; then
                     :error: 1 "Cannot chown $(.)_Owner $(.)_Dir"
                  fi
               fi
            fi

            if [[ -n $(.)_Mode ]]; then
               if ! chmod "$(.)_Mode" "$(.)_Dir" 2>/dev/null; then
                  if ! sudo chmod "$(.)_Mode" "$(.)_Dir" 2>/dev/null; then
                     :error: 1 "Cannot chmod $(.)_Mode $(.)_Dir"
                  fi
               fi
            fi

         elif [[ ! -d $(.)_Dir ]]; then
            :error: 1 "Cannot mkdir $(.)_Dir"
         fi
      done
   done
}
