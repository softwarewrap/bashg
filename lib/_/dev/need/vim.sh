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

   local (.)_InstallIsRequired=false                     # Assume that it is not necessary to install vim

   if $(.)_Force || ! :test:has_command vim; then
      (.)_InstallIsRequired=true                         # Vim is not installed: install

   else
      local (.)_Version
      (.)_Version="$(
         vim --version |                                 # Many lines; first line has the version number in it
         head -1 |                                       # Limit to the first line
         sed -e 's|^[^0-9]*||' -e 's| .*||'              # The first number begins the version and ends with a space
      )"

      if [[ ! -f /etc/skel/.gvimrc ]] ||
         [[ ! -f /usr/local/share/vim/template/top ]] ||
         :test:version_compare "$(.)_Version" -lt 8.2 ||
         ! cmp -s (+:vim)/@files/etc/skel/.gvimrc /etc/skel/.gvimrc; then

         (.)_InstallIsRequired=true                      # It is an old version: update to current
      fi
   fi

   if $(.)_InstallIsRequired; then
      (+:vim):install
   fi
}
