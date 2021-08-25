#!/bin/bash

:need:disable_selinux:()
{
   :sudo || :reenter                                     # This function must run as root

   if [[ $(getenforce) != Disabled ]]; then
      sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
      setenforce 0 || true
      touch /.autorelabel
   fi
}
