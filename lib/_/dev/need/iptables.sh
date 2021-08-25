#!/bin/bash

- linux-7()
{
   if ! :test:has_package iptables-services; then
      yum -y install iptables-services
      systemctl enable iptables
      systemctl start iptables

      iptables --flush

      systemctl stop iptables
      iptables-save > /etc/sysconfig/iptables
      systemctl mask iptables
   fi
}
