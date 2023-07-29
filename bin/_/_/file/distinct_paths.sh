#!/bin/bash

:file:distinct_paths()
{
   local __file__distinct_paths__distinct_paths___Options
   __file__distinct_paths__distinct_paths___Options=$(getopt -o '' -l 'var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__file__distinct_paths__distinct_paths___Options"

   local __file__distinct_paths__distinct_paths___Var='__file__distinct_paths__distinct_paths___UnspecifiedVar'
   local -a __file__distinct_paths__distinct_paths___UnspecifiedVar=()

   while true ; do
      case "$1" in
      --var)   __file__distinct_paths__distinct_paths___Var="$2"; shift 2;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   ######################
   # Perform Validation #
   ######################
   if [[ ! $__file__distinct_paths__distinct_paths___Var =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      :error: 1 'The first argument must be a valid variable name'
   fi

   if [[ ! -v $__file__distinct_paths__distinct_paths___Var ]]; then
      local -ag "$__file__distinct_paths__distinct_paths___Var"
   fi

   if (( $# == 0 )); then
      readarray -t "$__file__distinct_paths__distinct_paths___Var" </dev/null                 # If there are no args, set the array to empty

   elif (( $# > 1 )); then                               # If there are multiple args, do the optimization
      local -a __file__distinct_paths__distinct_paths___List
      readarray -t __file__distinct_paths__distinct_paths___List < <(
         printf '%s\n' "$@" |                            # Emit the paths one per line
         LC_ALL=C sort -u |                              # Remove duplicates
         awk '{ print length, $0 }' |                    # Add length as field 1
         LC_ALL=C sort -n -s |                           # Numeric sort only (-s: otherwise preserve order)
         cut -d' ' -f2- |                                # Remove the length field
         tac                                             # Reverse: longest lines are now first
      )

      local -ag __file__distinct_paths__distinct_paths___Distinct=()                          # Start off with an empty array
      local __file__distinct_paths__distinct_paths___Path                                     # Iterate
      for __file__distinct_paths__distinct_paths___Path in "${__file__distinct_paths__distinct_paths___List[@]}"; do
         if ! :array:has_element --match __file__distinct_paths__distinct_paths___Distinct "$__file__distinct_paths__distinct_paths___Path/*"; then
                                                         # If Path hasn't been encountered yet,
            __file__distinct_paths__distinct_paths___Distinct+=( "$__file__distinct_paths__distinct_paths___Path" )                # ... then add it to the Distinct list
         fi
      done

      set -- "${__file__distinct_paths__distinct_paths___Distinct[@]}"                        # Set the positional args to the optimized list
   fi

   readarray -t "$__file__distinct_paths__distinct_paths___Var" < <(printf '%s\n' "$@")
                                                         # Write the result back to the passed-in variable
   if [[ $__file__distinct_paths__distinct_paths___Var = __file__distinct_paths__distinct_paths___UnspecifiedVar ]] &&
      (( ${#__file__distinct_paths__distinct_paths___UnspecifiedVar[@]} > 0 )); then

      printf '%s\n' "${__file__distinct_paths__distinct_paths___UnspecifiedVar[@]}"
   fi
}
