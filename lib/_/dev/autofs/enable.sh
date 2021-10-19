#!/bin/bash

+ enable()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Service
   for (.)_Service in rpcbind nfs-server autofs; do
      systemctl enable "$(.)_Service"
   done
}
