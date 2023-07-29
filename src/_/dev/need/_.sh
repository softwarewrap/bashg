#!/bin/bash

+ %STARTUP-1()
{
   (++:launcher)_Config[SearchPath]+=' (+:need):'        # Space separated list of function search paths
   # Note: The (++:launcher)_Config is defined in (++:launcher):PreStartup
   # that is executed before (++:launcher):Startup that runs %STARTUP functions.
   # Because of this, it is safe to modify the (++:launcher)_Config at this time.
}
