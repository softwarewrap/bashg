#!/bin/bash

_dev:need:vim:()
{
   local _dev__need__vim_____Options
   _dev__need__vim_____Options=$(getopt -o '' -l 'force' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__need__vim_____Options"

   local _dev__need__vim_____Force=false
   while true ; do
      case "$1" in
      --force) _dev__need__vim_____Force=true; shift;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   local _dev__need__vim_____InstallIsRequired=false                     # Assume that it is not necessary to install vim

   if $_dev__need__vim_____Force || ! :test:has_command vim; then
      _dev__need__vim_____InstallIsRequired=true                         # Vim is not installed: install

   else
      local _dev__need__vim_____Version
      _dev__need__vim_____Version="$(
         vim --version |                                 # Many lines; first line has the version number in it
         head -1 |                                       # Limit to the first line
         sed -e 's|^[^0-9]*||' -e 's| .*||'              # The first number begins the version and ends with a space
      )"

      if [[ ! -f /etc/skel/.gvimrc ]] ||
         [[ ! -f /usr/local/share/vim/template/top ]] ||
         :test:version_compare "$_dev__need__vim_____Version" -lt 8.2 ||
         ! cmp -s "$_lib_dir/_/dev/vim"/@files/etc/skel/.gvimrc /etc/skel/.gvimrc; then

         _dev__need__vim_____InstallIsRequired=true                      # It is an old version: update to current
      fi
   fi

   if $_dev__need__vim_____InstallIsRequired; then
      _dev:vim:install
   fi
}
