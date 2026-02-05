#!/bin/bash

:array:dump_associative()
{
   local __array__dump_associative__dump_associative___array_Options
   __array__dump_associative__dump_associative___array_Options=$(getopt -o '' -l 'no-color' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__array__dump_associative__dump_associative___array_Options"

   local -a __array__dump_associative__dump_associative___array_Args=()
   local __array__dump_associative__dump_associative___array_Color=true
   while true ; do
      case "$1" in
      --no-color) __array__dump_associative__dump_associative___array_Color=false; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   local __array__dump_associative__dump_associative___Var="$1"                                    # The associative array name to dump
   local __array__dump_associative__dump_associative___array_Header="$2"                           # Any header to show before the K/V listing

   # Get the max length of the keys
   local -i __array__dump_associative__dump_associative___array_MaxLength
   __array__dump_associative__dump_associative___array_MaxLength="$(printf '%s\n' "${__array__dump_associative__dump_associative___array_Keys[@]}" | wc -L)"+1

   if $__array__dump_associative__dump_associative___array_Color && ${__launcher___Config[HasColor]}; then
      local __array__dump_associative__dump_associative___array_Format='<G>%s</G>'                 # Embolden the values
      IFS= read -rd '' __array__dump_associative__dump_associative___array_Header < <( :highlight: <<<"$__array__dump_associative__dump_associative___array_Header" ) || true
   else
      local __array__dump_associative__dump_associative___array_Format='%s'                        # Leave values plain
      __array__dump_associative__dump_associative___array_Args+=( '--render' 'plain' )
                                                         # Pass on request to not highlight
   fi

   # Get the associative array keys
   local -a '__array__dump_associative__dump_associative___array_Keys=( "${!'"$__array__dump_associative__dump_associative___Var"'[@]}" )'
   if (( ${#__array__dump_associative__dump_associative___array_Keys[@]} == 0 )); then
      echo "<b>[EMPTY]</b>: $__array__dump_associative__dump_associative___array_Header" | :highlight: "${__array__dump_associative__dump_associative___array_Args[@]}"
      return 0
   fi

   if [[ -n $__array__dump_associative__dump_associative___array_Header ]]; then
      echo "$__array__dump_associative__dump_associative___array_Header"
   fi

   local __array__dump_associative__dump_associative___Key
   for __array__dump_associative__dump_associative___Key in "${__array__dump_associative__dump_associative___array_Keys[@]}"; do
      printf "   <b>%*s</b> = $__array__dump_associative__dump_associative___array_Format\n" "-$__array__dump_associative__dump_associative___array_MaxLength" "$__array__dump_associative__dump_associative___Key" "$( :array:dump_associative.Get "$__array__dump_associative__dump_associative___Var" "$__array__dump_associative__dump_associative___Key" )"
   done | LC_ALL=C sed 's|\\|\\\\|g' | LC_ALL=C sort -fV | :highlight: "${__array__dump_associative__dump_associative___array_Args[@]}"

   echo
}

:array:dump_associative.Get()
{
   local __array__dump_associative__dump_associative___Var="$1"
   local __array__dump_associative__dump_associative___Key="$(sed 's|"|\\"|g' <<<"$2")"

   printf '%q' "$(eval "echo \"\${$__array__dump_associative__dump_associative___Var[$__array__dump_associative__dump_associative___Key]}\"")"
}
