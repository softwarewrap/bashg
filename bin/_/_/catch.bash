#!/bin/bash

alias :catch=$'
   :try.CleanExit \${LINENO} ${__TryLevel}
   )
   source "${__TryPersist[$__TryLevel]%% *}"
   rm -f "${__TryPersist[$__TryLevel]%% *}"
   unset __TryPersist[$__TryLevel]
   unset __TryLocals[$__TryLevel]
   if ((__TryLevel-- >= 0)); then
      set -e
   fi
   (( $_try_status == 0 )) ||
   '
