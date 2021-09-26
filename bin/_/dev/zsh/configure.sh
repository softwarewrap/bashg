#!/bin/bash

_dev:zsh:configure%HELP()
{
   local _dev__zsh__configure__configureHELP___Synopsis='Configure a home directory with zsh configuration files'

   :help: --set "$_dev__zsh__configure__configureHELP___Synopsis" --usage '[<home_directory>]' <<EOF
DESCRIPTION:
   Add zsh configuration files to a home directory

   If the <home_directory> is given, then that directory is configured;
   otherwise, the current user's home directory is configured.
EOF
}

_dev:zsh:configure()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Configuring directories for zsh' "$FUNCNAME $@"

   (( $# > 0 )) || set -- "$_entry_home"

   local _dev__zsh__configure__configure___HomeDir                                     # Install files into user home directories

   for _dev__zsh__configure__configure___HomeDir; do                                   # Iterate over a set of home directories
      :log: "Configuring for zsh: $_dev__zsh__configure__configure___HomeDir"

      local _dev__zsh__configure__configure___File
      for _dev__zsh__configure__configure___File in .zshenv .zshrc; do
         rm -f "$_dev__zsh__configure__configure___HomeDir/$_dev__zsh__configure__configure___File"                  # Remove any existing file
         cp "/etc/skel/$_dev__zsh__configure__configure___File" "$_dev__zsh__configure__configure___HomeDir/$_dev__zsh__configure__configure___File"
                                                         # Copy the new file
         chown -R --reference="$_dev__zsh__configure__configure___HomeDir" "$_dev__zsh__configure__configure___HomeDir/$_dev__zsh__configure__configure___File"
                                                         # Make the owner match the home directory

         local _dev__zsh__configure__configure___HomeDirOwner                          # We need the user name corresponding to the home directory
         _dev__zsh__configure__configure___HomeDirOwner="$(stat -c '%U' "$_dev__zsh__configure__configure___HomeDir")"
                                                         # Use stat to get this information
         if [[ $_dev__zsh__configure__configure___HomeDirOwner != nobody ]]; then      # The user must be a real user, not nobody
            usermod -s /bin/zsh "$_dev__zsh__configure__configure___HomeDirOwner"      # Change the shell for the user to zsh
         fi
      done

      mkdir -p "$_dev__zsh__configure__configure___HomeDir/.zshrc.d"                   # Ensure the .zshrc.d directory exists
      chown --reference="$_dev__zsh__configure__configure___HomeDir" "$_dev__zsh__configure__configure___HomeDir/.zshrc.d"
                                                         # Make the owner match the home directory
   done

   :log: --pop
}
