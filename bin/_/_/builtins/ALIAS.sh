#!/bin/bash

:builtins:ALIAS:=%STARTUP-0()
{
   local -Ag ___Alias=
}

=()
{
   local ___Search="$1"

   if [[ -n ${___Alias[$___Search]} ]]; then
      shift                                              # Remove the search from the argument list

      "${___Alias[$___Search]}" "$@"                   # Call the command or function indirectly referenced

   else
      :error: 1 "Could not find alias for '$___Search'"
      return 1
   fi
}
