#!/bin/bash

_dev:need:iptables:linux-7()
{
   if ! :test:has_package iptables-services; then
      :log: --push-section 'Flushing iptables' "$FUNCNAME $@"

      yum -y install iptables-services
      systemctl enable iptables
      systemctl start iptables

      iptables --flush

      systemctl stop iptables
      iptables-save > /etc/sysconfig/iptables
      systemctl mask iptables

      :log: --pop
   fi
}
