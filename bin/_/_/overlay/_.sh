#!/bin/bash

:overlay:%HELP()
{
   local __overlay_____HELP___Synopsis='Overlay directory with another directory'
   local __overlay_____HELP___Usage='<source-dir> <destination-dir>'

   :help: --set "$__overlay_____HELP___Synopsis" --usage "$__overlay_____HELP___Usage" <<EOF
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

   local __overlay________Src="$1"                                    # The source directory to copy
   local __overlay________Dst="$2"                                    # The destination directory to overlay
   local __overlay________User="$3"                                   # The user to run as

   if [[ ! -d $__overlay________Src || ! -d $__overlay________Dst ]]; then         # Ensure directories exist
      :error: 1 "Both source and destination directories must exist"
      return 1
   fi

   if [[ -z $__overlay________User ]]; then                           # If User is not specified, use the owner of the Dst dir
      __overlay________User="$( stat -c '%U' "$__overlay________Dst" )"

   elif ! id "$__overlay________User" &>/dev/null; then               # The specified user must exist
      :error: 1 "No such user: $__overlay________User"
      return
   fi

   local __overlay________Group                                       # Get the group corresponding to the user
   __overlay________Group="$( id -n -g "$__overlay________User" )"

   (
      cd "$__overlay________Src"                                      # Create tar with owner/group specified from Src
      tar --owner="$__overlay________User" --group="$__overlay________Group" -cpf - .
   ) |
   (                                                     # Overlay by extracting the tar onto Dst
      cd "$__overlay________Dst"
      tar -xpf -
   )
}
