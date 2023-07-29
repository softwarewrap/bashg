#!/bin/bash

:file:ensure_nl_at_end()
{
   :sudo || :reenter                                     # This function must run as root

   local __file__ensure_nl_at_end__ensure_nl_at_end___File="$(readlink -fm "$1")"                 # Store the full path to the file
   local __file__ensure_nl_at_end__ensure_nl_at_end___Dir="$(dirname "$__file__ensure_nl_at_end__ensure_nl_at_end___File")"                # Get the parent directory of File

   if [[ ! -e $__file__ensure_nl_at_end__ensure_nl_at_end___File ]]; then                         # If File doesn't exist, then create it
      if [[ ! -d $__file__ensure_nl_at_end__ensure_nl_at_end___Dir ]]; then                       # The parent directory is required
         :error: 1 "Missing directory: $__file__ensure_nl_at_end__ensure_nl_at_end___Dir"
      fi

      touch "$__file__ensure_nl_at_end__ensure_nl_at_end___File"                                  # Create the file
      chown --reference "$__file__ensure_nl_at_end__ensure_nl_at_end___Dir" "$__file__ensure_nl_at_end__ensure_nl_at_end___File"           # Set some sensible owner
      chmod 644 "$__file__ensure_nl_at_end__ensure_nl_at_end___File"                              # Set some sensible mode

   elif [[ ! -f $__file__ensure_nl_at_end__ensure_nl_at_end___File ]]; then                       # The File must be of type file
      :error: 1 "Not a file: $__file__ensure_nl_at_end__ensure_nl_at_end___File"

   elif [[ ! -s $__file__ensure_nl_at_end__ensure_nl_at_end___File ]]; then                       # If the file does not have any content, then just return
      return 0

   else
      sed -i '$a\' "$__file__ensure_nl_at_end__ensure_nl_at_end___File"                           # Ensure there is a newline at the end of the file
   fi
}
