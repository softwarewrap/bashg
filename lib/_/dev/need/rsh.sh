#!/bin/bash

- linux-8()
{
   if ! :test:has_package rsh || ! :test:has_package rsh-server; then
      :log: --push-section 'Installing' 'rsh' "$FUNCNAME $@"

      # rsh must be installed and passwordless access allowed
      # Allow access from any host
      echo "+ +" >/etc/hosts.equiv
      chmod 600 /etc/hosts.equiv
      cp -p /etc/hosts.equiv /root/.rhosts

      # Install rsh
      yum -y install rsh rsh-server

      systemctl enable rsh.socket
      systemctl start rsh.socket

      :log: --pop
   fi
}

- linux-7()
{
   if ! :test:has_package rsh || ! :test:has_package rsh-server; then
      :log: --push-section 'Installing' 'rsh' "$FUNCNAME $@"

      # rsh must be installed and passwordless access allowed
      # Allow access from any host
      echo "+ +" >/etc/hosts.equiv
      chmod 600 /etc/hosts.equiv
      cp -p /etc/hosts.equiv /root/.rhosts

      # Install rsh
      yum -y install rsh rsh-server

      systemctl enable rsh.socket
      systemctl start rsh.socket

      sed -i '$a\' /etc/securetty
      for Command in rsh rlogin rexec; do
         sed -i "/^$Command\s*$/d" /etc/securetty
         echo "$Command" >>/etc/securetty
      done

      :log: --pop
   fi
}
