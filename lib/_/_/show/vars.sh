#!/bin/bash

+ vars%HELP()
{
   local (.)_Synopsis='Show user or special variable names and values'
   :help: --set "$(.)_Synopsis" --usage '[[/[/]]<variable>]...' <<EOF
DESCRIPTION:
   Show variable information depending on the arguments provided:

   Without Arguments^<K
      If this command is invoked without and <variable> names,
      then the complete list of special variables is shown.

   With Arguments^<K
      If <variable> names are provided, then those variable names and values are shown.
      If a requested <variable> is not defined, the value is shown as <R>Undefined</R>.

      If a requested <variable> is prefixed with <B>/</B>, the <variable> is taken to be a regex.
      All variables that match the regex are shown.

      If a requested <variable> is prefixed with <B>//</B>, the regex is taken to be case insensitive.

   NOTE: this function can show exported variables from the calling environment.
EOF
}

+ vars()
{
   local (.)_Var                                         # Iterator

   if (( $# == 0 )); then                                # If no variables are explicitly requested
      local -a (.)_VarList=(                             # ... create a list of special variables to show
         _program
         __
         _base_dir
         _lib_dir
         _bin_dir
         _etc_dir
         _invocation_dir
         _whoami
         _entry_group
         _entry_home
         _entry_user
      )

      set -- "${(.)_VarList[@]}"                         # Set the arg list to the special variables

   else
      local -a (.)_Candidates                            # A candidate list is needed to deal with duplicates
      readarray -t (.)_Candidates < <(                   # Load candidates
         for (.)_Var in "$@"; do                         # ... by iterating over each request
            if [[ $(.)_Var = /* ]]; then                 # If the request begins with a /
               if [[ $(.)_Var = //* ]]; then
                  compgen -A variable | grep -iP "${(.)_Var:2}"

               else
                  compgen -A variable | grep -P "${(.)_Var:1}"
               fi
                                                         # ... then take it to be a regex against all variables
            else
               echo "$(.)_Var"                           # Otherwise, just add the request to the candidate list
            fi
         done | LC_ALL=C sort -u                         # Remove any duplicates
      )
      set -- "${(.)_Candidates[@]}"                      # ... and set the arg list to these requests
   fi

   if (( $# == 0 )); then
      echo "No results"                                  # Emit a message on no results
      return
   fi

   ##################
   # Output Results #
   ##################
   {
   echo 'Variable|Value'                                 # Emit a header. The | is used for alignment.
   echo '========|====='

   for (.)_Var in "$@"; do                               # Iterate over each result
      if [[ -v $(.)_Var ]]; then                         # If the variable exists
         echo "$(.)_Var|${!(.)_Var}"                     # ... then emit it and the value with the alignment character

      else
         echo -e "$(.)_Var|(.)_Undefined"                # ... otherwise, indicate that this result is undefined
      fi
   done
   } |

   :text:align |                                         # Expand to form columns, removing the | character

   {
      sed '
         1,2s|.*|<G>&</G>|                               # Embolden the header with green
         3,$s|^\([^ ]\+\)\( \+\)\(.*\)|<B>\1</B>\2<b>\3</b>|
                                                         # Variables are blue; Values are bold
         s|^\([^ ]\+ \+\)<b>(.)_Undefined</b>|\1<R>Undefined</R>|
                                                         # Show Undefined in red
      '
   } |

   :highlight:                                           # And render as requested
}
