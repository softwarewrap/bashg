#!/bin/bash

- =%STARTUP-0()
{
   local -Ag (@)_Alias=
}

=()
{
   local (.)_Search="$1"

   if [[ -n ${(@)_Alias[$(.)_Search]} ]]; then
      shift                                              # Remove the search from the argument list

      "${(@)_Alias[$(.)_Search]}" "$@"                   # Call the command or function indirectly referenced

   else
      :error: 1 "Could not find alias for '$(.)_Search'"
      return 1
   fi
}
