#!/bin/bash

+ restart()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Service
   for (.)_Service in rpcbind nfs-server autofs; do
      systemctl restart "$(.)_Service"
   done
}
