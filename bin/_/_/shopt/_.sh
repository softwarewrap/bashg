#!/bin/bash

:shopt:%STARTUP-1()
{
   local -ga __shopt___ShoptSave=()                            # The options at the ShoptSaveIndex level
   local -gi __shopt___ShoptSaveIndex=-1                       # The stack level: -1 is the initial (unused) state
}

:shopt:save()
{
   __shopt___ShoptSaveIndex=$(( __shopt___ShoptSaveIndex + 1 ))      # Advance the stack level
   __shopt___ShoptSave[__shopt___ShoptSaveIndex]="$(shopt -p)"       # Push the shopt options

   if (( $# > 0 )); then
      shopt "$@"                                         # Apply any changes
   fi
}

:shopt:restore()
{
   if (( $__shopt___ShoptSaveIndex >= 0 )) ; then              # Do not pop below the stack
      eval "${__shopt___ShoptSave[$__shopt___ShoptSaveIndex]}"       # Pop: restore the set options
      __shopt___ShoptSaveIndex=$(( __shopt___ShoptSaveIndex - 1 ))   # Reduce the stack level to at most -1 (unused)
   fi
}
