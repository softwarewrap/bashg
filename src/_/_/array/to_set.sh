#!/bin/bash

+ to_set%HELP()
{
   local (.)_Synopsis='Convert an array to a array set'

   :help: --set "$(.)_Synopsis" --usage '<set-variable> <list>...' <<'EOF'
OPTIONS:
   -a|--append    ^Append <list> into the <set-variable> [default: overwrite]

DESCRIPTION:
   Convert a parameter list that might have duplicates into an array that contains no duplicates (a set)

   The <set-variable> is required and must be the first argument.
   This variable must be an initialized array variable prior to calling this function.

   The <list> is any list of parameters that are to be examined and added uniquely to the <set-variable>.

   If --append is specified, then append the existing <set-variable> values into the <list>.
   Note: In this case, the original <set-variable> might not contain unique values; however,
   after this operation, the values of the <set-variable> will become unique.

RETURN STATUS:
   0  ^Success
   1  ^General error
   2  ^The first argument must be a variable name
   3  ^The <set-variable> must be initialized prior to calling this function

SCRIPTING EXAMPLE:
   local -ag ArrayVar=()                           ^# Where the result will go
   set -- 3 8                                      ^# Populate positional parameters
   local -ag Ref=(5 + 8 = 13)                      ^# Populate an array variable

   :array:to_set ArrayVar 1 1 2 3 5                ^# After: (1 2 3 5)
   :array:to_set ArrayVar 1 1 2 3 5 "$@"           ^# After: (1 2 3 5 8)
   :array:to_set ArrayVar 1 1 2 3 5 "${Ref[@]}"    ^# After: (1 2 3 5 + 8 = 13)
   :array:to_set ArrayVar 3 8 21 0 --append        ^# After: (1 2 3 5 + 8 = 13 21 0)
EOF
}

+ to_set()
{
   local (.)_SetVar="$1"
   shift

   :getopts: begin -o 'a' -l 'append' -- "$@"

   local (.)_Option                                      # Option letter or word
   local (.)_Value                                       # Value stores a value for options that take a value
   local (.)_Append=false

   while :getopts: next (.)_Option (.)_Value; do
      case "$(.)_Option" in
      -a|--append)   (.)_Append=true;;

      *)             break;;
      esac
   done

   :getopts: end


   ######################
   # Perform Validation #
   ######################
   if [[ -z $(.)_SetVar || ! $(.)_SetVar =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      :error: "The first argument must be a variable name"
      return 2
   fi

   if [[ ! -v $(.)_SetVar ]]; then
      :error: "The variable name must be initialized prior to calling this function"
      return 3
   fi

   if $(.)_Append; then
      local (.)_Indirect="$(.)_SetVar[@]"
      set -- "${!(.)_Indirect}" "$@"                     # Append list after existing array values
   fi

   if (( $# == 0 )); then
      readarray -t "$(.)_SetVar" < /dev/null             # If there are no args, set the array to empty

   elif (( $# > 1 )); then                               # If there are multiple args, do the optimization
      local -a (.)_Additions
      readarray -t (.)_Additions < <(
         printf '%s\n' "$@" |                            # Emit the additions one per line
         LC_ALL=C sort -u |                              # Remove duplicates
         awk '{ print length, $0 }' |                    # Add length as field 1
         LC_ALL=C sort -n -s |                           # Numeric sort only (-s: otherwise preserve order)
         cut -d' ' -f2- |                                # Remove the length field
         tac                                             # Reverse: longest lines are now first
      )

      local -a (.)_Unique=()                             # Start off with an empty array
      local (.)_Addition                                 # Iterator

      for (.)_Addition in "${(.)_Additions[@]}"; do
         if ! :array:has_element (.)_Unique "$(.)_Addition"; then
                                                         # If Addition hasn't been encountered yet,
            (.)_Unique+=( "$(.)_Addition" )              # ... then add it to the Distinct list
         fi
      done

      set -- "${(.)_Unique[@]}"                          # Set the positional args to the optimized list
   fi

   readarray -t "$(.)_SetVar" < <(printf '%s\n' "$@")
                                                         # Write the result back to the passed-in variable
}
