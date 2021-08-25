#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Install zsh and configure accounts'

   :help: --set "$(.)_Synopsis" <<'EOF'
DESCRIPTION:
   Install vim from source code

   This command requires no arguments and performs the following additional command:

      (+):configure /root

   If this command is run as user other than root, then the (+):configure command
   is run with that user's home directory as well.
EOF
}

+ ()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push 'Adding zsh'

   :log: 'Installing prerequisites'
   yum -y install @development zsh || true               # Ensure necessary dependencies are installed and install zsh

   ### INSTALL SUPPORTING SYSTEM ZSH FILES, INCLUDING /etc/skel
   (
      cd (+)/@files
      tar --owner=root -cpf - .
   ) | (
      cd /
      tar -xpf -
   )

   :log: 'Installing zsh prompt-related utilities into /usr/local/bin'

   local (.)_SourceFile
   local (.)_Executable

   cd (+)/@src                                           # The location of the source files

   for (.)_SourceFile in *.c; do
      (.)_Executable="/usr/local/bin/${(.)_SourceFile%.c}"
                                                         # Strip off the .c extension
      gcc -o "$(.)_Executable" "$(.)_SourceFile"
   done

   (+):configure /root "$_entry_home"                    # Configure these home directories

   :log: --pop
}

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
}
