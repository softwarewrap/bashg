#!/bin/bash

:overlay:%HELP()
{
   local ___overlay_____HELP___Synopsis='Overlay directory with another directory'
   local ___overlay_____HELP___Usage='<source-dir> <destination-dir>'

   :help: --set "$___overlay_____HELP___Synopsis" --usage "$___overlay_____HELP___Usage" <<EOF
OPTIONS:
   -o|--owner <owner>   ^Set the owner when overlaying

DESCRIPTION:
   Overlay a source directory onto a destination directory, possibly setting ownership

EXAMPLES:
   Example here               ^: comment here
EOF
}

:overlay:()
{
   :sudo || :reenter                                     # This function must run as root

   local ___overlay________Src="$1"                                    # The source directory to copy
   local ___overlay________Dst="$2"                                    # The destination directory to overlay
   local ___overlay________User="$3"                                   # The user to run as

   if [[ ! -d $___overlay________Src || ! -d $___overlay________Dst ]]; then         # Ensure directories exist
      :error: 1 "Both source and destination directories must exist"
      return 1
   fi

   if [[ -z $___overlay________User ]]; then                           # If User is not specified, use the owner of the Dst dir
      ___overlay________User="$( stat -c '%U' "$___overlay________Dst" )"

   elif ! id "$___overlay________User" &>/dev/null; then               # The specified user must exist
      :error: 1 "No such user: $___overlay________User"
      return
   fi

   local ___overlay________Group                                       # Get the group corresponding to the user
   ___overlay________Group="$( id -n -g "$___overlay________User" )"

   (
      cd "$___overlay________Src"                                      # Create tar with owner/group specified from Src
      tar --owner="$___overlay________User" --group="$___overlay________Group" -cpf - .
   ) |
   (                                                     # Overlay by extracting the tar onto Dst
      cd "$___overlay________Dst"
      tar -xpf -
   )
}
