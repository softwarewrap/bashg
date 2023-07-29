#!/bin/bash

+ distinct_paths()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Var='(.)_UnspecifiedVar'
   local -a (.)_UnspecifiedVar=()

   while true ; do
      case "$1" in
      --var)   (.)_Var="$2"; shift 2;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   ######################
   # Perform Validation #
   ######################
   if [[ ! $(.)_Var =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      :error: 1 'The first argument must be a valid variable name'
   fi

   if [[ ! -v $(.)_Var ]]; then
      local -ag "$(.)_Var"
   fi

   if (( $# == 0 )); then
      readarray -t "$(.)_Var" </dev/null                 # If there are no args, set the array to empty

   elif (( $# > 1 )); then                               # If there are multiple args, do the optimization
      local -a (.)_List
      readarray -t (.)_List < <(
         printf '%s\n' "$@" |                            # Emit the paths one per line
         LC_ALL=C sort -u |                              # Remove duplicates
         awk '{ print length, $0 }' |                    # Add length as field 1
         LC_ALL=C sort -n -s |                           # Numeric sort only (-s: otherwise preserve order)
         cut -d' ' -f2- |                                # Remove the length field
         tac                                             # Reverse: longest lines are now first
      )

      local -ag (.)_Distinct=()                          # Start off with an empty array
      local (.)_Path                                     # Iterate
      for (.)_Path in "${(.)_List[@]}"; do
         if ! (+:array):has_element --match (.)_Distinct "$(.)_Path/*"; then
                                                         # If Path hasn't been encountered yet,
            (.)_Distinct+=( "$(.)_Path" )                # ... then add it to the Distinct list
         fi
      done

      set -- "${(.)_Distinct[@]}"                        # Set the positional args to the optimized list
   fi

   readarray -t "$(.)_Var" < <(printf '%s\n' "$@")
                                                         # Write the result back to the passed-in variable
   if [[ $(.)_Var = (.)_UnspecifiedVar ]] &&
      (( ${#(.)_UnspecifiedVar[@]} > 0 )); then

      printf '%s\n' "${(.)_UnspecifiedVar[@]}"
   fi
}
