#!/bin/bash

:set:%STARTUP-1()
{
   local -ga __set___SetSave=()                              # The options at the SetSaveIndex level
   local -gi __set___SetSaveIndex=-1                         # The stack level: -1 is the initial (unused) state
}

:set:save()
{
   __set___SetSaveIndex=$(( __set___SetSaveIndex + 1 ))          # Advance the stack level
   __set___SetSave[__set___SetSaveIndex]="$(set +o)"             # Push the set options

   if (( $# > 0 )); then
      set "$@"                                           # Apply any changes
   fi
}

:set:restore()
{
   if (( $__set___SetSaveIndex >= 0 )) ; then                # Do not pop below the stack
      eval "${__set___SetSave[$__set___SetSaveIndex]}"           # Pop: restore the set options
      __set___SetSaveIndex=$(( __set___SetSaveIndex - 1 ))       # Reduce the stack level to at most -1 (unused)
   fi
}
