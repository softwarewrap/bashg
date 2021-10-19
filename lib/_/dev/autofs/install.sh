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

   :log: 'Done.'
}
