#!/bin/bash

+ configure%HELP()
{
   local (.)_Synopsis='Configure a home directory with vim configuration files'

   :help: --set "$(.)_Synopsis" --usage '[<home_directory>]' <<EOF
DESCRIPTION:
   Add vim configuration files to a home directory

   If the <home_directory> is given, then that directory is configured;
   otherwise, the current user's home directory is configured.
EOF
}

+ configure()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Configuring directories for vim' "$FUNCNAME $@"

   (( $# > 0 )) || set -- "$_entry_home"

   local (.)_HomeDir                                     # Install files into user home directories

   for (.)_HomeDir; do                                   # Iterate over a set of home directories
      :log: "Configuring for vim: $(.)_HomeDir"

      # Create the swap and backup directories
      mkdir -p "$(.)_HomeDir"/.vim/{swp,save}

      # Remove any existing configuration files
      rm -f "$(.)_HomeDir"/{.vimrc,.gvimrc}

      # Install the gvimrc file to /etc/skel
      cp '/etc/skel/.gvimrc' "$(.)_HomeDir/.gvimrc"

      # Link the vimrc file
      sudo -u "$(stat -c '%U' "$(.)_HomeDir")" bash -c "cd; ln -sf .gvimrc .vimrc"

      chown -R --reference="$(.)_HomeDir" "$(.)_HomeDir"/{.vim,.gvimrc}
   done

   :log: --pop
}
