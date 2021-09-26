#!/bin/bash

_dev:need:zsh:()
{
   local _dev__need__zsh_____Options
   _dev__need__zsh_____Options=$(getopt -o '' -l 'force' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__need__zsh_____Options"

   local _dev__need__zsh_____Force=false
   while true ; do
      case "$1" in
      --force) _dev__need__zsh_____Force=true; shift;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   local _dev__need__zsh_____InstallIsRequired=false                     # Assume that it is not necessary to install zsh

   if $_dev__need__zsh_____Force || ! :test:has_command zsh; then
      _dev__need__zsh_____InstallIsRequired=true                         # Forcing install or zsh is not installed

   else
      local _dev__need__zsh_____Version
      _dev__need__zsh_____Version="$(
         zsh --version |                                 # Many lines; first line has the version number in it
         head -1 |                                       # Limit to the first line
         sed -e 's|^[^0-9]*||' -e 's| .*||'              # The first number begins the version and ends with a space
      )"

      if [[ ! -f /etc/skel/.zshrc ]] ||
         [[ ! -f /usr/local/bin/path ]] ||
         :test:version_compare "$_dev__need__zsh_____Version" -lt 5 ||
         ! cmp -s "$_lib_dir/_/dev/zsh"/@files/etc/skel/.zshrc /etc/skel/.zshrc; then

         _dev__need__zsh_____InstallIsRequired=true                      # It is an old version: update to current
      fi
   fi

   if $_dev__need__zsh_____InstallIsRequired; then
      _dev:zsh:install
   fi
}
