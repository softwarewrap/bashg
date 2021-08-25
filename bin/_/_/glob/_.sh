#!/bin/bash

:glob:%STARTUP-1()
{
   local -g ___glob___GlobstarSave=                            # Empty is not saved
   local -g ___glob___NullGlobSave=                            # Empty is not saved
}


:glob:set()
{
   ___glob___GlobstarSave="$(shopt -p globstar)"               # Save for later restore
   ___glob___NullGlobSave="$(shopt -p nullglob)"               # Save for later restore

   shopt -s globstar nullglob
}

:glob:reset()
{
   if [[ -n $___glob___GlobstarSave ]]; then
      $___glob___GlobstarSave                                  # Restore globstar state
   fi
   if [[ -n $___glob___NullGlobSave ]]; then
      $___glob___NullGlobSave                                  # Restore nullglob state
   fi
}

:glob:clear()
{
   ___glob___GlobstarSave=                                     # Reset to not saved
   ___glob___NullGlobSave=                                     # Reset to not saved
}
