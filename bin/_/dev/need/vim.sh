#!/bin/bash

_dev:need:vim:()
{
   local _dev__need__vim_____InstallIsRequired=false                     # Assume that it is not necessary to install vim

   if :test:has_command vim; then
      local _dev__need__vim_____Version
      _dev__need__vim_____Version="$(
         vim --version |                                 # Many lines; first line has the version number in it
         head -1 |                                       # Limit to the first line
         sed -e 's|^[^0-9]*||' -e 's| .*||'              # The first number begins the version and ends with a space
      )"

      if :test:version_compare "$_dev__need__vim_____Version" -lt 8.2; then
         _dev__need__vim_____InstallIsRequired=true                      # It is an old version: update to current
      fi

   else
      _dev__need__vim_____InstallIsRequired=true                         # Vim is not installed: install
   fi

   if $_dev__need__vim_____InstallIsRequired; then
      _dev:vim:
   fi
}
