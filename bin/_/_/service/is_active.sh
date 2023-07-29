#!/bin/bash

:service:is_active()
{
   :sudo || :reenter                                     # This function must run as root

   local __service__is_active__is_active___Service="${1/.service/}.service"            # Construct service name

   systemctl is-active --quiet "$__service__is_active__is_active___Service"
}
