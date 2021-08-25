#!/bin/bash

:file:ensure_nl_at_end()
{
   :sudo || :reenter                                     # This function must run as root

   local ___file__ensure_nl_at_end__ensure_nl_at_end___File="$(readlink -fm "$1")"                 # Store the full path to the file
   local ___file__ensure_nl_at_end__ensure_nl_at_end___Dir="$(dirname "$___file__ensure_nl_at_end__ensure_nl_at_end___File")"                # Get the parent directory of File

   if [[ ! -e $___file__ensure_nl_at_end__ensure_nl_at_end___File ]]; then                         # If File doesn't exist, then create it
      if [[ ! -d $___file__ensure_nl_at_end__ensure_nl_at_end___Dir ]]; then                       # The parent directory is required
         :error: 1 "Missing directory: $___file__ensure_nl_at_end__ensure_nl_at_end___Dir"
      fi

      touch "$___file__ensure_nl_at_end__ensure_nl_at_end___File"                                  # Create the file
      chown --reference "$___file__ensure_nl_at_end__ensure_nl_at_end___Dir" "$___file__ensure_nl_at_end__ensure_nl_at_end___File"           # Set some sensible owner
      chmod 644 "$___file__ensure_nl_at_end__ensure_nl_at_end___File"                              # Set some sensible mode

   elif [[ ! -f $___file__ensure_nl_at_end__ensure_nl_at_end___File ]]; then                       # The File must be of type file
      :error: 1 "Not a file: $___file__ensure_nl_at_end__ensure_nl_at_end___File"

   elif [[ ! -s $___file__ensure_nl_at_end__ensure_nl_at_end___File ]]; then                       # If the file does not have any content, then just return
      return 0

   else
      sed -i '$a\' "$___file__ensure_nl_at_end__ensure_nl_at_end___File"                           # Ensure there is a newline at the end of the file
   fi
}
