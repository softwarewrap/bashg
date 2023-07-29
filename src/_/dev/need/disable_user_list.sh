#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   mkdir -p '/etc/dconf/db/gdm.d'

   local (.)_LoginConfFile="/etc/dconf/db/gdm.d/00-login-screen"
   cat > "$(.)_LoginConfFile" <<EOF
[org/gnome/login-screen]
disable-user-list=true

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/screensaver]
lock-enabled=false
EOF
}
