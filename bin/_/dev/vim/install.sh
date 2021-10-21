#!/bin/bash

.dev:vim:install%HELP()
{
   local _dev__vim__install__installHELP___Synopsis='Install vim and configure accounts'
   :help: --set "$_dev__vim__install__installHELP___Synopsis" <<'EOF'
OPTIONS:
   -u|--update <value>     ^If vim is already installed, allow updates

DESCRIPTION:
   Install vim from source code
EOF
}

.dev:vim:install()
{
   :sudo || :reenter                                     # This function must run as root

   local _dev__vim__install__install___Options
   _dev__vim__install__install___Options=$(getopt -o 'u' -l 'update' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__vim__install__install___Options"

   local _dev__vim__install__install___Update=false
   while true ; do
      case "$1" in
      -u|--update)   _dev__vim__install__install___Update=true; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   # Assert that there is no vim share directory nor a vim executable
   if ! $_dev__vim__install__install___Update && [[ -d /usr/local/share/vim && -x /usr/local/bin/vim ]]; then
      :log: 'Skipping vim: already installed'

      return 0                                           # Not updating and vim directory and executable exists
   fi

   :log: --push-section 'Adding vim-enhanced' "$FUNCNAME $@"

   :log: 'Removing any existing vim installation'
   yum -y erase vim-enhanced vim-common vim-filesystem

   :log: 'Installing prerequisites'
   local -a _dev__vim__install__install___PrerequisitePackages=(
      @development                                       # Provide compilation prerequisites
      ncurses                                            # Screen motion
      ncurses-devel
      python3                                            # Used for many purposes, including json->yaml->json
      python3-devel
      python3-pip
      ruby                                               # Used by some vim plugins
      ruby-devel
   )
   yum -y install "${_dev__vim__install__install___PrerequisitePackages[@]}" || true

   :log: 'Downloading vim source'
   local _dev__vim__install__install___TmpDir
   _dev__vim__install__install___TmpDir="$(mktemp -d)"                             # Build vim in a throw-away area
   cd "$_dev__vim__install__install___TmpDir"

   git clone https://github.com/vim/vim.git              # Official git project location
   cd vim

   local -a _dev__vim__install__install___VimFeatures=(
      --with-tlib=ncurses
      --with-features=huge                               # Provide a rich set of features
      --enable-multibyte                                 # Include unicode support
      --enable-pythoninterp
      --enable-rubyinterp
   )

   :log: 'Configuring for vim build'
   CFLAGS='-fPIC -O2' ./configure "${_dev__vim__install__install___VimFeatures[@]}"

   :log: 'Building vim'
   make

   :log: 'Installing vim'
   make install

   cd /usr/local/bin
   ln -sf vim vi

   mkdir -p /orig/usr/bin

   local _dev__vim__install__install___Target
   for _dev__vim__install__install___Target in vi vim; do
      if [[ -f /usr/bin/$_dev__vim__install__install___Target && ! -f /orig/usr/bin/$_dev__vim__install__install___Target ]]; then
         mv /usr/bin/$_dev__vim__install__install___Target /orig/usr/bin/.
      fi

      ln -sf /usr/local/bin/$_dev__vim__install__install___Target "/usr/bin/$_dev__vim__install__install___Target"
   done

   ### INSTALL SUPPORTING SYSTEM VIM FILES, INCLUDING /etc/skel/.gvimrc
   (
      cd "$_lib_dir/_/dev/vim"/@files
      tar --owner=root -cpf - .
   ) | (
      cd /
      tar -xpf -
   )

   mkdir -p /etc/skel/.vim/{swp,save}                    # Create the empty directories needed by vim

   # Configure user files
   .dev:vim:configure /root "$_entry_home"                    # Configure these home directories

   cd "$_invocation_dir"
   rm -rf "$_dev__vim__install__install___TmpDir"

   :log: --pop
}
