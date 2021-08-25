#!/bin/bash

+ ensure_nl_at_end()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_File="$(readlink -fm "$1")"                 # Store the full path to the file
   local (.)_Dir="$(dirname "$(.)_File")"                # Get the parent directory of File

   if [[ ! -e $(.)_File ]]; then                         # If File doesn't exist, then create it
      if [[ ! -d $(.)_Dir ]]; then                       # The parent directory is required
         :error: 1 "Missing directory: $(.)_Dir"
      fi

      touch "$(.)_File"                                  # Create the file
      chown --reference "$(.)_Dir" "$(.)_File"           # Set some sensible owner
      chmod 644 "$(.)_File"                              # Set some sensible mode

   elif [[ ! -f $(.)_File ]]; then                       # The File must be of type file
      :error: 1 "Not a file: $(.)_File"

   elif [[ ! -s $(.)_File ]]; then                       # If the file does not have any content, then just return
      return 0

   else
      sed -i '$a\' "$(.)_File"                           # Ensure there is a newline at the end of the file
   fi
}
