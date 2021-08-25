#!/bin/bash

+ dump_associative()
{
   local (.)_array_Options
   (.)_array_Options=$(getopt -o '' -l 'no-color' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_array_Options"

   local -a (.)_array_Args=()
   local (.)_array_Color=true
   while true ; do
      case "$1" in
      --no-color) (.)_array_Color=false; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   local (.)_Var="$1"                                    # The associative array name to dump
   local (.)_array_Header="$2"                           # Any header to show before the K/V listing

   # Get the max length of the keys
   local -i (.)_array_MaxLength
   (.)_array_MaxLength="$(printf '%s\n' "${(.)_array_Keys[@]}" | wc -L)"+1

   if $(.)_array_Color && ${(+:launcher)_Config[HasColor]}; then
      local (.)_array_Format='<G>%s</G>'                 # Embolden the values
      IFS= read -rd '' (.)_array_Header < <( :highlight: <<<"$(.)_array_Header" ) || true
   else
      local (.)_array_Format='%s'                        # Leave values plain
      (.)_array_Args+=( '--render' 'plain' )
                                                         # Pass on request to not highlight
   fi

   # Get the associative array keys
   local -a '(.)_array_Keys=( "${!'"$(.)_Var"'[@]}" )'
   if (( ${#(.)_array_Keys[@]} == 0 )); then
      echo "<b>[EMPTY]</b>: $(.)_array_Header" | :highlight: "${(.)_array_Args[@]}"
      return 0
   fi

   if [[ -n $(.)_array_Header ]]; then
      echo "$(.)_array_Header"
   fi

   local (.)_Key
   for (.)_Key in "${(.)_array_Keys[@]}"; do
      printf "   <b>%*s</b> = $(.)_array_Format\n" "-$(.)_array_MaxLength" "$(.)_Key" "$( (+):dump_associative.Get "$(.)_Var" "$(.)_Key" )"
   done | LC_ALL=C sed 's|\\|\\\\|g' | LC_ALL=C sort -fV | :highlight: "${(.)_array_Args[@]}"

   echo
}

+ dump_associative.Get()
{
   local (.)_Var="$1"
   local (.)_Key="$(sed 's|"|\\"|g' <<<"$2")"

   printf '%q' "$(eval "echo \"\${$(.)_Var[$(.)_Key]}\"")"
}
