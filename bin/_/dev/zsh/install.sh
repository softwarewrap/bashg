#!/bin/bash

_dev:zsh:install%HELP()
{
   local _dev__zsh__install__installHELP___Synopsis='Install zsh and configure accounts'

   :help: --set "$_dev__zsh__install__installHELP___Synopsis" <<'EOF'
DESCRIPTION:
   Install vim from source code

   This command requires no arguments and performs the following additional command:

      _dev:zsh:configure /root

   If this command is run as user other than root, then the _dev:zsh:configure command
   is run with that user's home directory as well.
EOF
}

_dev:zsh:install()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Adding zsh' "$FUNCNAME $@"

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

   local _dev__zsh__install__install___SourceFile
   local _dev__zsh__install__install___Executable

   cd "$_lib_dir/_/dev/zsh"/@src                                           # The location of the source files

   for _dev__zsh__install__install___SourceFile in *.c; do
      _dev__zsh__install__install___Executable="/usr/local/bin/${_dev__zsh__install__install___SourceFile%.c}"
                                                         # Strip off the .c extension
      gcc -o "$_dev__zsh__install__install___Executable" "$_dev__zsh__install__install___SourceFile"
   done

   _dev:zsh:configure /root "$_entry_home"                    # Configure these home directories

   :log: --pop
}
