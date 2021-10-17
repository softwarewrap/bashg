#!/bin/bash

.dev:need:os_packages:()
{
   :sudo || :reenter                                     # This function must run as root

   local _dev__need__os_packages_____Options
   _dev__need__os_packages_____Options=$(getopt -o 'f' -l 'force' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__need__os_packages_____Options"

   local _dev__need__os_packages_____Force=false
   while true ; do
      case "$1" in
      -f|--force) _dev__need__os_packages_____Force=true; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if $_dev__need__os_packages_____Force || ! :yum:is_installed --environment 'Server with GUI'; then
      :log: --push-section 'Installing Server with GUI and supporting packages' "$FUNCNAME $@"

      local -a _dev__need__os_packages_____Items=(                               # For @^ and @ shorthand, see yum -v grouplist and man 8 yum
         '@^graphical-server-environment'                # Server with GUI;                  @^ = environment group
         '@development'                                  # Development Tools;                @ =  group
         '@graphical-admin-tools'                        # Graphical Administration Tools;   @ =  group
         expect                                          # Automate interactive applications
         gnome-shell-extension-dash-to-dock              # GNOME dashboard shell extension
         mlocate                                         # Provides: locate
         postgresql                                      # PostgreSQL DB
         pv                                              # Pipe Viewer for monitoring progress
         unzip                                           # Archive extraction
         xorg-x11-apps                                   # A collection of common X Window System applications
         xrdp                                            # X Remote Desktop, works with Windows Remote Desktop
      )

      yum -y install "${_dev__need__os_packages_____Items[@]}"                   # Install items specified above

      systemctl set-default graphical.target
      systemctl start graphical.target

      :log: --pop
   fi
}
