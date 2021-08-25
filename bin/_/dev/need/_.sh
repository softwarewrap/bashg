#!/bin/bash

_dev:need:%STARTUP-1()
{
   ___launcher___Config[SearchPath]+=' _dev:need:'        # Space separated list of function search paths
   # Note: The ___launcher___Config is defined in :launcher:PreStartup
   # that is executed before :launcher:Startup that runs %STARTUP functions.
   # Because of this, it is safe to modify the ___launcher___Config at this time.
}
