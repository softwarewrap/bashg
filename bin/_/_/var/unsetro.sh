#!/bin/bash

:var:unsetro()
{
   local __var__unsetro__unsetro___Variable="$1"

   [[ -v $__var__unsetro__unsetro___Variable ]] || return 0                    # If the parameter is not set, then there's nothing to do

   if ! gdb -ex "call unbind_variable(\"$__var__unsetro__unsetro___Variable\")" --pid=$$ --batch &>/dev/null; then
                                                         # If the gdb unset fails, then try it again using sudo
      if ! sudo -n true; then                            # If sudo is not available, then throw an error
         :error: --stacktrace 1 'This function requires sudo access'
         return 1
      fi

      sudo gdb -ex "call unbind_variable(\"$__var__unsetro__unsetro___Variable\")" --pid=$$ --batch &>/dev/null
                                                         # Try the command using sudo
                                                         # If the command fails it will be caught
   fi
}
