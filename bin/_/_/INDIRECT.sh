#!/bin/bash

:::%STARTUP-0()
{
   local -Ag ___Indirect=
}

-()
{
   local ___Search="$1"

   if [[ -n ${___Indirect[$___Search]} ]]; then
      shift                                              # Remove the search from the argument list

      "${___Indirect[$___Search]}" "$@"                # Call the command or function indirectly referenced

   else
      :error: 1 "Could not perform indirection on '$___Search'"
      return 1
   fi
}
