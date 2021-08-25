#!/bin/bash

_dev:need:rsh:linux-7()
{
   if ! :test:has_package rsh || ! :test:has_package rsh-server; then
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

      iptables --flush
      iptables-save > /etc/sysconfig/iptables
   fi
}

_dev:need:rsh:linux-6()
{
   if ! :test:has_package rsh || ! :test:has_package rsh-server; then
      # rsh must be installed and passwordless access allowed
      # Allow access from any host
      echo "+ +" >/etc/hosts.equiv
      chmod 600 /etc/hosts.equiv
      cp -p /etc/hosts.equiv /root/.rhosts

      # Install rsh
      yum -y install rsh rsh-server

      chkconfig --level 345 rsh on
      chkconfig --level 345 rlogin on

      sed -i '$a\' /etc/securetty
      for Command in rsh rlogin rexec; do
         sed -i "/^$Command\s*$/d" /etc/securetty
         echo "$Command" >>/etc/securetty
      done

      iptables --flush
      iptables-save > /etc/sysconfig/iptables
   fi
}
