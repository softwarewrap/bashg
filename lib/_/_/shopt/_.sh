#!/bin/bash

+ %STARTUP-1()
{
   local -ga (+)_ShoptSave=()                            # The options at the ShoptSaveIndex level
   local -gi (+)_ShoptSaveIndex=-1                       # The stack level: -1 is the initial (unused) state
}

+ save()
{
   (+)_ShoptSaveIndex=$(( (+)_ShoptSaveIndex + 1 ))      # Advance the stack level
   (+)_ShoptSave[(+)_ShoptSaveIndex]="$(shopt -p)"       # Push the shopt options

   if (( $# > 0 )); then
      shopt "$@"                                         # Apply any changes
   fi
}

+ restore()
{
   if (( $(+)_ShoptSaveIndex >= 0 )) ; then              # Do not pop below the stack
      eval "${(+)_ShoptSave[$(+)_ShoptSaveIndex]}"       # Pop: restore the set options
      (+)_ShoptSaveIndex=$(( (+)_ShoptSaveIndex - 1 ))   # Reduce the stack level to at most -1 (unused)
   fi
}
