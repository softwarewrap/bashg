#!/bin/bash

# :try/:catch - see implementation of :try.persist and :try.CleanExit
alias :try=$'
   set +e
   ((__TryLevel++))
   __TryLocals[$__TryLevel]="$(local | LC_ALL=C sed "s/=.*//" | tr "\n" " ")"
   __TryPersist[$__TryLevel]="$(mktemp)"
   if (( $__TryLevel > 0 )) && grep " " &>/dev/null <<<"${__TryPersist[$(($__TryLevel - 1))]}"; then
      __TryPersist[$__TryLevel]+=" $(LC_ALL=C sed "s|^[^ ]* ||" <<<"${__TryPersist[$(($__TryLevel - 1))]}")"
   fi
   (
   set -e
   trap ":try.CleanExit \${LINENO} ${__TryLevel}; " ERR
   '
