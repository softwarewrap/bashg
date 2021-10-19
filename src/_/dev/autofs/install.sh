#!/bin/bash

+ install()
{
   :sudo || :reenter                                     # This function must run as root

   :log: 'Installing autofs'

   yum -y install autofs rpcbind nfs-utils

   if [[ ! -f /etc/auto.r && -f /etc/auto.net ]]; then
      cp -p /etc/auto.net /etc/auto.r
      sed -i 's/^opts=.*/opts="-fstype=nfs,rw,hard,intr,rsize=32768,wsize=32768,noatime,nodiratime,nodev,grpid,suid"/' /etc/auto.r
      chmod 755 /etc/auto.r

      cat >/etc/auto.master <<EOF
/misc /etc/auto.misc
/r /etc/auto.r
EOF
   fi

   if [[ -f /etc/auto.r && $(stat -c '%a' /etc/auto.r) != 755 ]]; then
      chmod 755 /etc/auto.r
   fi

   if [[ -f /etc/auto.misc && $(stat -c '%a' /etc/auto.misc) != 755 ]]; then
      chmod 755 /etc/auto.misc
   fi

   # Copy configuration files
   (
      cd (+)/@files
      tar cpf - .
   ) |
   (
      cd /
      tar xpf -
   )

   # Ensure nfs is running
   local (.)_Service
   for (.)_Service in rpcbind nfs-server autofs; do
      local (.)_State
      (.)_State="$( systemctl is-enabled "$(.)_Service" )"
      if [[ $(.)_State = masked ]]; then
         systemctl unmask "$(.)_Service"
      fi
      if [[ $(.)_State = disabled ]]; then
         systemctl enable "$(.)_Service"
      fi
      if ! systemctl is-active "$(.)_Service" --quiet; then
         systemctl start "$(.)_Service"
      fi
   done

   :log: 'Done.'
}
