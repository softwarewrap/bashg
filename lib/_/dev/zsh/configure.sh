#!/bin/bash

+ configure%HELP()
{
   local (.)_Synopsis='Configure a home directory with zsh configuration files'

   :help: --set "$(.)_Synopsis" --usage '[<home_directory>]' <<EOF
DESCRIPTION:
   Add zsh configuration files to a home directory

   If the <home_directory> is given, then that directory is configured;
   otherwise, the current user's home directory is configured.
EOF
}

+ configure()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Configuring directories for zsh' "$FUNCNAME $@"

   (( $# > 0 )) || set -- "$_entry_home"

   local (.)_HomeDir                                     # Install files into user home directories

   for (.)_HomeDir; do                                   # Iterate over a set of home directories
      :log: "Configuring for zsh: $(.)_HomeDir"

      local (.)_File
      for (.)_File in .zshenv .zshrc; do
         rm -f "$(.)_HomeDir/$(.)_File"                  # Remove any existing file
         cp "/etc/skel/$(.)_File" "$(.)_HomeDir/$(.)_File"
                                                         # Copy the new file
         chown -R --reference="$(.)_HomeDir" "$(.)_HomeDir/$(.)_File"
                                                         # Make the owner match the home directory

         local (.)_HomeDirOwner                          # We need the user name corresponding to the home directory
         (.)_HomeDirOwner="$(stat -c '%U' "$(.)_HomeDir")"
                                                         # Use stat to get this information
         if [[ $(.)_HomeDirOwner != nobody ]]; then      # The user must be a real user, not nobody
            usermod -s /bin/zsh "$(.)_HomeDirOwner"      # Change the shell for the user to zsh
         fi
      done

      mkdir -p "$(.)_HomeDir/.zshrc.d"                   # Ensure the .zshrc.d directory exists
      chown --reference="$(.)_HomeDir" "$(.)_HomeDir/.zshrc.d"
                                                         # Make the owner match the home directory
   done

   :log: --pop
}
