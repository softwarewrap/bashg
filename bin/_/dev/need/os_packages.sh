#!/bin/bash

.dev:need:os_packages:()
{
   :sudo || :reenter                                     # This function must run as root

   local _dev__need__os_packages_____Options
   _dev__need__os_packages_____Options=$(getopt -o 'f' -l 'force,gui' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__need__os_packages_____Options"

   local _dev__need__os_packages_____Force=false
   local _dev__need__os_packages_____GUI=false

   while true ; do
      case "$1" in
      --gui)      _dev__need__os_packages_____GUI=true; shift;;
      -f|--force) _dev__need__os_packages_____Force=true; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if $_dev__need__os_packages_____GUI && ! $_dev__need__os_packages_____Force && :yum:is_installed --environment 'Server with GUI'; then
      return 0                                           # No need to take any action
   fi

   :log: --push-section 'Installing Server with GUI and supporting packages' "$FUNCNAME $@"

   local -a _dev__need__os_packages_____Items=(                                  # For @^ and @ shorthand, see yum -v grouplist and man 8 yum
      '@development'                                     # Development Tools;                @ =  group
      expect                                             # Automate interactive applications
      mlocate                                            # Provides: locate
      pv                                                 # Pipe Viewer for monitoring progress
      unzip                                              # Archive extraction
      xorg-x11-apps                                      # A collection of common X Window System applications
      xrdp                                               # X Remote Desktop, works with Windows Remote Desktop
   )

   if $_dev__need__os_packages_____GUI; then
      _dev__need__os_packages_____Items+=(
         '@^graphical-server-environment'                # Server with GUI;                  @^ = environment group
         '@graphical-admin-tools'                        # Graphical Administration Tools;   @ =  group
         gnome-shell-extension-dash-to-dock              # GNOME dashboard shell extension
         xorg-x11-apps                                   # A collection of common X Window System applications
         xrdp                                            # X Remote Desktop, works with Windows Remote Desktop
      )
   fi

   yum -y install "${_dev__need__os_packages_____Items[@]}"                      # Install items specified above

   if $_dev__need__os_packages_____GUI; then
      systemctl set-default graphical.target
      systemctl start graphical.target
   fi

   #############################################################################################
   # Bug fix: gnome-terminal as root won't work                                                #
   # Fixes throw: Error constructing proxy for org.gnome.Terminal:/org/gnome/Terminal/Factory0 #
   # See: https://wiki.gnome.org/Apps/Terminal/FAQ#Exit_status_8                               #
   #############################################################################################
   localectl set-locale LANG=en_US.UTF-8

   :log: --pop
}
