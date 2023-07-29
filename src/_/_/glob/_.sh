#!/bin/bash

+ %STARTUP-1()
{
   local -g (+)_GlobstarSave=                            # Empty is not saved
   local -g (+)_NullGlobSave=                            # Empty is not saved
}


+ set()
{
   (+)_GlobstarSave="$(shopt -p globstar || true)"       # Save for later restore
   (+)_NullGlobSave="$(shopt -p nullglob || true)"       # Save for later restore

   shopt -s globstar nullglob
}

+ reset()
{
   if [[ -n $(+)_GlobstarSave ]]; then
      $(+)_GlobstarSave                                  # Restore globstar state
   fi
   if [[ -n $(+)_NullGlobSave ]]; then
      $(+)_NullGlobSave                                  # Restore nullglob state
   fi
}

+ clear()
{
   (+)_GlobstarSave=                                     # Reset to not saved
   (+)_NullGlobSave=                                     # Reset to not saved
}
