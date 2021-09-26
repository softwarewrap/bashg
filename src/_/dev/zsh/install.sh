#!/bin/bash

+ install%HELP()
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

+ install()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Adding zsh' "$FUNCNAME $@"

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
