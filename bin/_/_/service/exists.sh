#!/bin/bash

:service:exists()
{
   :sudo || :reenter                                     # This function must run as root

   local __service__exists__exists___Service="${1/.service/}.service"            # Construct service name

   systemctl list-units --all -t service --full --no-legend "$__service__exists__exists___Service" |
   sed 's/^\s*//g' |
   awk '{print $1}'
}
