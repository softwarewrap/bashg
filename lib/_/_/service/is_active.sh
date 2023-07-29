#!/bin/bash

+ is_active()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Service="${1/.service/}.service"            # Construct service name

   systemctl is-active --quiet "$(.)_Service"
}
