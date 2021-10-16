#!/bin/bash

.dev:need:%STARTUP-1()
{
   __launcher___Config[SearchPath]+=' .dev:need:'        # Space separated list of function search paths
   # Note: The __launcher___Config is defined in :launcher:PreStartup
   # that is executed before :launcher:Startup that runs %STARTUP functions.
   # Because of this, it is safe to modify the __launcher___Config at this time.
}
