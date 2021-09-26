#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :yum:is_installed --environment 'Server with GUI'; then
      :log: --push-section 'Installing Server with GUI and supporting packages' "$FUNCNAME $@"

      local -a (.)_Items=(                               # For @^ and @ shorthand, see yum -v grouplist and man 8 yum
         '@^graphical-server-environment'                # Server with GUI;                  @^ = environment group
         '@development'                                  # Development Tools;                @ =  group
         '@graphical-admin-tools'                        # Graphical Administration Tools;   @ =  group
         mlocate                                         # Provides: locate
         postgresql                                      # PostgreSQL DB
         unzip                                           # Archive extraction
         xorg-x11-apps                                   # A collection of common X Window System applications
         xrdp                                            # X Remote Desktop, works with Windows Remote Desktop
      )

      yum -y install "${(.)_Items[@]}"                   # Install items specified above

      systemctl set-default graphical.target
      systemctl start graphical.target

      :log: --pop
   fi
}
