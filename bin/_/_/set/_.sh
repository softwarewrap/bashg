#!/bin/bash

:set:%STARTUP-1()
{
   local -ga ___set___SetSave=()                              # The options at the SetSaveIndex level
   local -gi ___set___SetSaveIndex=-1                         # The stack level: -1 is the initial (unused) state
}

:set:save()
{
   ___set___SetSaveIndex=$(( ___set___SetSaveIndex + 1 ))          # Advance the stack level
   ___set___SetSave[___set___SetSaveIndex]="$(set +o)"             # Push the set options

   if (( $# > 0 )); then
      set "$@"                                           # Apply any changes
   fi
}

:set:restore()
{
   if (( $___set___SetSaveIndex >= 0 )) ; then                # Do not pop below the stack
      eval "${___set___SetSave[$___set___SetSaveIndex]}"           # Pop: restore the set options
      ___set___SetSaveIndex=$(( ___set___SetSaveIndex - 1 ))       # Reduce the stack level to at most -1 (unused)
   fi
}
