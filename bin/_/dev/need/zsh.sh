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

   if ! $_dev__need__zsh_____Force && :test:has_command zsh; then
      local _dev__need__zsh_____Version
      _dev__need__zsh_____Version="$(
         zsh --version |                                 # Many lines; first line has the version number in it
         head -1 |                                       # Limit to the first line
         sed -e 's|^[^0-9]*||' -e 's| .*||'              # The first number begins the version and ends with a space
      )"

      if :test:version_compare "$_dev__need__zsh_____Version" -lt 5; then
         _dev__need__zsh_____InstallIsRequired=true                      # It is an old version: update to current
      fi

   else
      _dev__need__zsh_____InstallIsRequired=true                         # zsh is not installed: install
   fi

   if $_dev__need__zsh_____InstallIsRequired; then
      _dev:zsh:
   fi
}
