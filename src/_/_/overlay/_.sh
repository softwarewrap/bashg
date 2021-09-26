#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Overlay directory with another directory'
   local (.)_Usage='<source-dir> <destination-dir>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
OPTIONS:
   -o|--owner <owner>   ^Set the owner when overlaying

DESCRIPTION:
   Overlay a source directory onto a destination directory, possibly setting ownership

EXAMPLES:
   Example here               ^: comment here
EOF
}

+ ()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Src="$1"                                    # The source directory to copy
   local (.)_Dst="$2"                                    # The destination directory to overlay
   local (.)_User="$3"                                   # The user to run as

   if [[ ! -d $(.)_Src || ! -d $(.)_Dst ]]; then         # Ensure directories exist
      :error: 1 "Both source and destination directories must exist"
      return 1
   fi

   if [[ -z $(.)_User ]]; then                           # If User is not specified, use the owner of the Dst dir
      (.)_User="$( stat -c '%U' "$(.)_Dst" )"

   elif ! id "$(.)_User" &>/dev/null; then               # The specified user must exist
      :error: 1 "No such user: $(.)_User"
      return
   fi

   local (.)_Group                                       # Get the group corresponding to the user
   (.)_Group="$( id -n -g "$(.)_User" )"

   (
      cd "$(.)_Src"                                      # Create tar with owner/group specified from Src
      tar --owner="$(.)_User" --group="$(.)_Group" -cpf - .
   ) |
   (                                                     # Overlay by extracting the tar onto Dst
      cd "$(.)_Dst"
      tar -xpf -
   )
}
