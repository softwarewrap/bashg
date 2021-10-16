#!/bin/bash

.dev:vim:configure%HELP()
{
   local _dev__vim__configure__configureHELP___Synopsis='Configure a home directory with vim configuration files'

   :help: --set "$_dev__vim__configure__configureHELP___Synopsis" --usage '[<home_directory>]' <<EOF
DESCRIPTION:
   Add vim configuration files to a home directory

   If the <home_directory> is given, then that directory is configured;
   otherwise, the current user's home directory is configured.
EOF
}

.dev:vim:configure()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Configuring directories for vim' "$FUNCNAME $@"

   (( $# > 0 )) || set -- "$_entry_home"

   local _dev__vim__configure__configure___HomeDir                                     # Install files into user home directories

   for _dev__vim__configure__configure___HomeDir; do                                   # Iterate over a set of home directories
      :log: "Configuring for vim: $_dev__vim__configure__configure___HomeDir"

      # Create the swap and backup directories
      mkdir -p "$_dev__vim__configure__configure___HomeDir"/.vim/{swp,save}

      # Remove any existing configuration files
      rm -f "$_dev__vim__configure__configure___HomeDir"/{.vimrc,.gvimrc}

      # Install the gvimrc file to /etc/skel
      cp '/etc/skel/.gvimrc' "$_dev__vim__configure__configure___HomeDir/.gvimrc"

      # Link the vimrc file
      sudo -u "$(stat -c '%U' "$_dev__vim__configure__configure___HomeDir")" bash -c "cd; ln -sf .gvimrc .vimrc"

      chown -R --reference="$_dev__vim__configure__configure___HomeDir" "$_dev__vim__configure__configure___HomeDir"/{.vim,.gvimrc}
   done

   :log: --pop
}
