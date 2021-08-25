#!/bin/bash

- ()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'force' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Force=false
   while true ; do
      case "$1" in
      --force) (.)_Force=true; shift;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   local (.)_InstallIsRequired=false                     # Assume that it is not necessary to install zsh

   if ! $(.)_Force && :test:has_command zsh; then
      local (.)_Version
      (.)_Version="$(
         zsh --version |                                 # Many lines; first line has the version number in it
         head -1 |                                       # Limit to the first line
         sed -e 's|^[^0-9]*||' -e 's| .*||'              # The first number begins the version and ends with a space
      )"

      if :test:version_compare "$(.)_Version" -lt 5; then
         (.)_InstallIsRequired=true                      # It is an old version: update to current
      fi

   else
      (.)_InstallIsRequired=true                         # zsh is not installed: install
   fi

   if $(.)_InstallIsRequired; then
      (+:zsh):
   fi
}
