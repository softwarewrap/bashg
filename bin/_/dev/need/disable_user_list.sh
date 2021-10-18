#!/bin/bash

.dev:need:disable_user_list:()
{
   :sudo || :reenter                                     # This function must run as root

   mkdir -p '/etc/dconf/db/gdm.d'

   local _dev__need__disable_user_list_____LoginConfFile="/etc/dconf/db/gdm.d/00-login-screen"
   cat > "$_dev__need__disable_user_list_____LoginConfFile" <<EOF
[org/gnome/login-screen]
disable-user-list=true

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/screensaver]
lock-enabled=false
EOF
}
