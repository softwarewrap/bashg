#!/bin/bash

.dev:autofs:enable()
{
   :sudo || :reenter                                     # This function must run as root

   local _dev__autofs__enable__enable___Service
   for _dev__autofs__enable__enable___Service in rpcbind nfs-server autofs; do
      systemctl enable "$_dev__autofs__enable__enable___Service"
   done
}
