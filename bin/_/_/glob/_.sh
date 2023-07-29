#!/bin/bash

:glob:%STARTUP-1()
{
   local -g __glob___GlobstarSave=                            # Empty is not saved
   local -g __glob___NullGlobSave=                            # Empty is not saved
}


:glob:set()
{
   __glob___GlobstarSave="$(shopt -p globstar || true)"       # Save for later restore
   __glob___NullGlobSave="$(shopt -p nullglob || true)"       # Save for later restore

   shopt -s globstar nullglob
}

:glob:reset()
{
   if [[ -n $__glob___GlobstarSave ]]; then
      $__glob___GlobstarSave                                  # Restore globstar state
   fi
   if [[ -n $__glob___NullGlobSave ]]; then
      $__glob___NullGlobSave                                  # Restore nullglob state
   fi
}

:glob:clear()
{
   __glob___GlobstarSave=                                     # Reset to not saved
   __glob___NullGlobSave=                                     # Reset to not saved
}
