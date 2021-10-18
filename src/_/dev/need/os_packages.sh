#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o 'f' -l 'force' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Force=false
   while true ; do
      case "$1" in
      -f|--force) (.)_Force=true; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if ! $(.)_Force && :yum:is_installed --environment 'Server with GUI'; then
      return 0                                           # No need to take any action
   fi

   :log: --push-section 'Installing Server with GUI and supporting packages' "$FUNCNAME $@"

   local -a (.)_Items=(                                  # For @^ and @ shorthand, see yum -v grouplist and man 8 yum
      '@^graphical-server-environment'                   # Server with GUI;                  @^ = environment group
      '@development'                                     # Development Tools;                @ =  group
      '@graphical-admin-tools'                           # Graphical Administration Tools;   @ =  group
      expect                                             # Automate interactive applications
      gnome-shell-extension-dash-to-dock                 # GNOME dashboard shell extension
      mlocate                                            # Provides: locate
      postgresql                                         # PostgreSQL DB
      pv                                                 # Pipe Viewer for monitoring progress
      unzip                                              # Archive extraction
      xorg-x11-apps                                      # A collection of common X Window System applications
      xrdp                                               # X Remote Desktop, works with Windows Remote Desktop
   )

   yum -y install "${(.)_Items[@]}"                      # Install items specified above

   #############################################################################################
   # Bug fix: gnome-terminal as root won't work                                                #
   # Fixes throw: Error constructing proxy for org.gnome.Terminal:/org/gnome/Terminal/Factory0 #
   # See: https://wiki.gnome.org/Apps/Terminal/FAQ#Exit_status_8                               #
   #############################################################################################
   localectl set-locale LANG=en_US.UTF-8

   systemctl set-default graphical.target
   systemctl start graphical.target

   :log: --pop
}
