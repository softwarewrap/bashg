#!/bin/bash

:array:dump_associative()
{
   local ___array__dump_associative__dump_associative___array_Options
   ___array__dump_associative__dump_associative___array_Options=$(getopt -o '' -l 'no-color' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___array__dump_associative__dump_associative___array_Options"

   local -a ___array__dump_associative__dump_associative___array_Args=()
   local ___array__dump_associative__dump_associative___array_Color=true
   while true ; do
      case "$1" in
      --no-color) ___array__dump_associative__dump_associative___array_Color=false; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   local ___array__dump_associative__dump_associative___Var="$1"                                    # The associative array name to dump
   local ___array__dump_associative__dump_associative___array_Header="$2"                           # Any header to show before the K/V listing

   # Get the max length of the keys
   local -i ___array__dump_associative__dump_associative___array_MaxLength
   ___array__dump_associative__dump_associative___array_MaxLength="$(printf '%s\n' "${___array__dump_associative__dump_associative___array_Keys[@]}" | wc -L)"+1

   if $___array__dump_associative__dump_associative___array_Color && ${___launcher___Config[HasColor]}; then
      local ___array__dump_associative__dump_associative___array_Format='<G>%s</G>'                 # Embolden the values
      IFS= read -rd '' ___array__dump_associative__dump_associative___array_Header < <( :highlight: <<<"$___array__dump_associative__dump_associative___array_Header" ) || true
   else
      local ___array__dump_associative__dump_associative___array_Format='%s'                        # Leave values plain
      ___array__dump_associative__dump_associative___array_Args+=( '--render' 'plain' )
                                                         # Pass on request to not highlight
   fi

   # Get the associative array keys
   local -a '___array__dump_associative__dump_associative___array_Keys=( "${!'"$___array__dump_associative__dump_associative___Var"'[@]}" )'
   if (( ${#___array__dump_associative__dump_associative___array_Keys[@]} == 0 )); then
      echo "<b>[EMPTY]</b>: $___array__dump_associative__dump_associative___array_Header" | :highlight: "${___array__dump_associative__dump_associative___array_Args[@]}"
      return 0
   fi

   if [[ -n $___array__dump_associative__dump_associative___array_Header ]]; then
      echo "$___array__dump_associative__dump_associative___array_Header"
   fi

   local ___array__dump_associative__dump_associative___Key
   for ___array__dump_associative__dump_associative___Key in "${___array__dump_associative__dump_associative___array_Keys[@]}"; do
      printf "   <b>%*s</b> = $___array__dump_associative__dump_associative___array_Format\n" "-$___array__dump_associative__dump_associative___array_MaxLength" "$___array__dump_associative__dump_associative___Key" "$( :array:dump_associative.Get "$___array__dump_associative__dump_associative___Var" "$___array__dump_associative__dump_associative___Key" )"
   done | LC_ALL=C sed 's|\\|\\\\|g' | LC_ALL=C sort -fV | :highlight: "${___array__dump_associative__dump_associative___array_Args[@]}"

   echo
}

:array:dump_associative.Get()
{
   local ___array__dump_associative__dump_associative___Var="$1"
   local ___array__dump_associative__dump_associative___Key="$(sed 's|"|\\"|g' <<<"$2")"

   printf '%q' "$(eval "echo \"\${$___array__dump_associative__dump_associative___Var[$___array__dump_associative__dump_associative___Key]}\"")"
}
