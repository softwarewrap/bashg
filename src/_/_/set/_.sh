#!/bin/bash

+ %STARTUP-1()
{
   local -ga (+)_SetSave=()                              # The options at the SetSaveIndex level
   local -gi (+)_SetSaveIndex=-1                         # The stack level: -1 is the initial (unused) state
}

+ save()
{
   (+)_SetSaveIndex=$(( (+)_SetSaveIndex + 1 ))          # Advance the stack level
   (+)_SetSave[(+)_SetSaveIndex]="$(set +o)"             # Push the set options

   if (( $# > 0 )); then
      set "$@"                                           # Apply any changes
   fi
}

+ restore()
{
   if (( $(+)_SetSaveIndex >= 0 )) ; then                # Do not pop below the stack
      eval "${(+)_SetSave[$(+)_SetSaveIndex]}"           # Pop: restore the set options
      (+)_SetSaveIndex=$(( (+)_SetSaveIndex - 1 ))       # Reduce the stack level to at most -1 (unused)
   fi
}
