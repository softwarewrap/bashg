#!/bin/bash

+ unsetro()
{
   local (.)_Variable="$1"

   [[ -v $(.)_Variable ]] || return 0                    # If the parameter is not set, then there's nothing to do

   if ! gdb -ex "call unbind_variable(\"$(.)_Variable\")" --pid=$$ --batch &>/dev/null; then
                                                         # If the gdb unset fails, then try it again using sudo
      if ! sudo -n true; then                            # If sudo is not available, then throw an error
         :error: --stacktrace 1 'This function requires sudo access'
         return 1
      fi

      sudo gdb -ex "call unbind_variable(\"$(.)_Variable\")" --pid=$$ --batch &>/dev/null
                                                         # Try the command using sudo
                                                         # If the command fails it will be caught
   fi
}
