#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

- ()
{
   if ! :test:has_package xorg-x11-server-Xvfb; then
      :log: --push 'Installing xorg-x11-server-Xvfb'

      yum -y install xorg-x11-server-Xvfb

      :log: --pop
   fi
}
