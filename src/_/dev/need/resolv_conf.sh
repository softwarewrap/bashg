#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

- linux-8()
{
   :sudo || :reenter                                     # This function must run as root

   if [[ ! -f /etc/resolv-static.conf && -f /etc/resolv.conf ]]; then
      mv /etc/resolv.conf /etc/resolv-static.conf
      ln -sr /etc/resolv-static.conf /etc/resolv.conf

      :log: 'Moved /etc/resolv.conf to /etc/resolv-static.conf and linked back to /etc/resolv.conf'
   fi
}
