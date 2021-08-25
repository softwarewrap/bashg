#!/bin/bash

_dev:zsh:%HELP()
{
   local _dev__zsh_____HELP___Synopsis='Install zsh and configure accounts'

   :help: --set "$_dev__zsh_____HELP___Synopsis" <<'EOF'
DESCRIPTION:
   Install vim from source code

   This command requires no arguments and performs the following additional command:

      _dev:zsh:configure /root

   If this command is run as user other than root, then the _dev:zsh:configure command
   is run with that user's home directory as well.
EOF
}

_dev:zsh:()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push 'Adding zsh'

   :log: 'Installing prerequisites'
   yum -y install @development zsh || true               # Ensure necessary dependencies are installed and install zsh

   ### INSTALL SUPPORTING SYSTEM ZSH FILES, INCLUDING /etc/skel
   (
      cd "$_lib_dir/_/dev/zsh"/@files
      tar --owner=root -cpf - .
   ) | (
      cd /
      tar -xpf -
   )

   :log: 'Installing zsh prompt-related utilities into /usr/local/bin'

   local _dev__zsh________SourceFile
   local _dev__zsh________Executable

   cd "$_lib_dir/_/dev/zsh"/@src                                           # The location of the source files

   for _dev__zsh________SourceFile in *.c; do
      _dev__zsh________Executable="/usr/local/bin/${_dev__zsh________SourceFile%.c}"
                                                         # Strip off the .c extension
      gcc -o "$_dev__zsh________Executable" "$_dev__zsh________SourceFile"
   done

   _dev:zsh:configure /root "$_entry_home"                    # Configure these home directories

   :log: --pop
}

_dev:zsh:configure%HELP()
{
   local _dev__zsh_____configureHELP___Synopsis='Configure a home directory with zsh configuration files'

   :help: --set "$_dev__zsh_____configureHELP___Synopsis" --usage '[<home_directory>]' <<EOF
DESCRIPTION:
   Add zsh configuration files to a home directory

   If the <home_directory> is given, then that directory is configured;
   otherwise, the current user's home directory is configured.
EOF
}

_dev:zsh:configure()
{
   :sudo || :reenter                                     # This function must run as root

   (( $# > 0 )) || set -- "$_entry_home"

   local _dev__zsh_____configure___HomeDir                                     # Install files into user home directories

   for _dev__zsh_____configure___HomeDir; do                                   # Iterate over a set of home directories
      :log: "Configuring for zsh: $_dev__zsh_____configure___HomeDir"

      local _dev__zsh_____configure___File
      for _dev__zsh_____configure___File in .zshenv .zshrc; do
         rm -f "$_dev__zsh_____configure___HomeDir/$_dev__zsh_____configure___File"                  # Remove any existing file
         cp "/etc/skel/$_dev__zsh_____configure___File" "$_dev__zsh_____configure___HomeDir/$_dev__zsh_____configure___File"
                                                         # Copy the new file
         chown -R --reference="$_dev__zsh_____configure___HomeDir" "$_dev__zsh_____configure___HomeDir/$_dev__zsh_____configure___File"
                                                         # Make the owner match the home directory

         local _dev__zsh_____configure___HomeDirOwner                          # We need the user name corresponding to the home directory
         _dev__zsh_____configure___HomeDirOwner="$(stat -c '%U' "$_dev__zsh_____configure___HomeDir")"
                                                         # Use stat to get this information
         if [[ $_dev__zsh_____configure___HomeDirOwner != nobody ]]; then      # The user must be a real user, not nobody
            usermod -s /bin/zsh "$_dev__zsh_____configure___HomeDirOwner"      # Change the shell for the user to zsh
         fi
      done

      mkdir -p "$_dev__zsh_____configure___HomeDir/.zshrc.d"                   # Ensure the .zshrc.d directory exists
      chown --reference="$_dev__zsh_____configure___HomeDir" "$_dev__zsh_____configure___HomeDir/.zshrc.d"
                                                         # Make the owner match the home directory
   done
}
