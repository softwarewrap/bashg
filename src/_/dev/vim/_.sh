#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Install vim and configure accounts'
   (++:help): --set "$(.)_Synopsis" <<'EOF'
OPTIONS:
   -u|--update <value>     ^If vim is already installed, allow updates

DESCRIPTION:
   Install vim from source code
EOF
}

+ ()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o 'u' -l 'update' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Update=false
   while true ; do
      case "$1" in
      -u|--update)   (.)_Update=true; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   # Assert that there is no vim share directory nor a vim executable
   if ! $(.)_Update && [[ -d /usr/local/share/vim && -x /usr/local/bin/vim ]]; then
      :log: 'Skipping vim: already installed'

      return 0                                           # Not updating and vim directory and executable exists
   fi

   :log: --push 'Adding vim-enhanced'

   :log: 'Removing any existing vim installation'
   yum -y erase vim-enhanced vim-common vim-filesystem

   :log: 'Installing prerequisites'
   local -a (.)_PrerequisitePackages=(
      @development                                       # Provide compilation prerequisites
      ncurses                                            # Screen motion
      ncurses-devel
      python3                                            # Used for many purposes, including json->yaml->json
      python3-devel
      python3-pip
      ruby                                               # Used by some vim plugins
      ruby-devel
   )
   yum -y install "${(.)_PrerequisitePackages[@]}" || true

   :log: 'Downloading vim source'
   local (.)_TmpDir
   (.)_TmpDir="$(mktemp -d)"                             # Build vim in a throw-away area
   cd "$(.)_TmpDir"

   git clone https://github.com/vim/vim.git              # Official git project location
   cd vim

   local -a (.)_VimFeatures=(
      --with-features=huge                               # Provide a rich set of features
      --enable-multibyte                                 # Include unicode support
      --enable-pythoninterp
      --enable-rubyinterp
   )

   :log: 'Configuring for vim build'
   ./configure "${(.)_VimFeatures[@]}"

   :log: 'Building vim'
   make

   :log: 'Installing vim'
   make install

   cd /usr/local/bin
   ln -sf vim vi

   mkdir -p /orig/usr/bin

   local (.)_Target
   for (.)_Target in vi vim; do
      if [[ -f /usr/bin/$(.)_Target && ! -f /orig/usr/bin/$(.)_Target ]]; then
         mv /usr/bin/$(.)_Target /orig/usr/bin/.
      fi

      ln -sf /usr/local/bin/$(.)_Target "/usr/bin/$(.)_Target"
   done

   ### INSTALL SUPPORTING SYSTEM VIM FILES, INCLUDING /etc/skel/.gvimrc
   (
      cd (+)/@files
      tar --owner=root -cpf - .
   ) | (
      cd /
      tar -xpf -
   )

   mkdir -p /etc/skel/.vim/{swp,save}                    # Create the empty directories needed by vim

   # Configure user files
   (+):configure /root "$_entry_home"                    # Configure these home directories

   cd "$_invocation_dir"
   rm -rf "$(.)_TmpDir"

   :log: --pop
}

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
}
