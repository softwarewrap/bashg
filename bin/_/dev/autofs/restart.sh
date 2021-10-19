#!/bin/bash

.dev:autofs:restart()
{
   :sudo || :reenter                                     # This function must run as root

   local _dev__autofs__restart__restart___Service
   for _dev__autofs__restart__restart___Service in rpcbind nfs-server autofs; do
      systemctl restart "$_dev__autofs__restart__restart___Service"
   done
}
