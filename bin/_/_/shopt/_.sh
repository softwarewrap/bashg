#!/bin/bash

:shopt:%STARTUP-1()
{
   local -ga ___shopt___ShoptSave=()                            # The options at the ShoptSaveIndex level
   local -gi ___shopt___ShoptSaveIndex=-1                       # The stack level: -1 is the initial (unused) state
}

:shopt:save()
{
   ___shopt___ShoptSaveIndex=$(( ___shopt___ShoptSaveIndex + 1 ))      # Advance the stack level
   ___shopt___ShoptSave[___shopt___ShoptSaveIndex]="$(shopt -p)"       # Push the shopt options

   if (( $# > 0 )); then
      shopt "$@"                                         # Apply any changes
   fi
}

:shopt:restore()
{
   if (( $___shopt___ShoptSaveIndex >= 0 )) ; then              # Do not pop below the stack
      eval "${___shopt___ShoptSave[$___shopt___ShoptSaveIndex]}"       # Pop: restore the set options
      ___shopt___ShoptSaveIndex=$(( ___shopt___ShoptSaveIndex - 1 ))   # Reduce the stack level to at most -1 (unused)
   fi
}
