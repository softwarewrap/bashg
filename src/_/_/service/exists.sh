#!/bin/bash

+ exists()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Service="${1/.service/}.service"            # Construct service name

   systemctl list-units --all -t service --full --no-legend "$(.)_Service" |
   sed 's/^\s*//g' |
   awk '{print $1}'
}
