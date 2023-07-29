#!/bin/bash

:builtins:PYTHON:%STARTUP-1()
{
   if [[ -f /usr/bin/python3 ]]; then
      ___Alias[python]='/usr/bin/python3'
   elif [[ -f /usr/bin/python2 ]]; then
      ___Alias[python]='/usr/bin/python2'
   elif [[ -f /usr/bin/python ]]; then
      ___Alias[python]='/usr/bin/python'
   else
      :error: 1 'The command "python" is not available'
      return 1
   fi
}
