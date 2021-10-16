#!/bin/bash

- %STARTUP-0()
{
   local -Ag (@)_Indirect=
}

-()
{
   local (.)_Search="$1"

   if [[ -n ${(@)_Indirect[$(.)_Search]} ]]; then
      shift                                              # Remove the search from the argument list

      "${(@)_Indirect[$(.)_Search]}" "$@"                # Call the command or function indirectly referenced

   else
      :error: 1 "Could not perform indirection on '$(.)_Search'"
      return 1
   fi
}
