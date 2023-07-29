#!/bin/bash

:try%STARTUP-0()
{
   local -ig __TryLevel=-1                               # Start outside of any try level
   local -ag __TryLocals=()                              # Used for storing local variables needing to be persisted
   local -ag __TryPersist=()                             # Used for explicit persisting of variables
   local -g _try_status=0                                # Status after try
   local -g _try_error_line=                             # Error info after try
}

:try.persist()
{
   # Ensure that this function may be called only within a :try block
   (( __TryLevel >= 0 )) ||
      { echo ":try.persist may be used only withina :try block"; return 1; }

   # Add the declared variables to the persistence list for the current level
   # Duplicates are allowed: they will be removed later
   __TryPersist[$__TryLevel]+=" $@"
}

:try.CleanExit()
{
   # The :try.CleanExit function is called in 2 possible ways:
   #
   #     - at the end of a :try subprocess with no errors
   #     - when an error occurs inside the :try subprocess
   #
   # This function can be called multiple times for a single caught trap, depending on the
   # amount of nesting involved (:try within :try).
   _try_status=$?
   _try_error_line="$1"
   local ExceptionLine="$1"
   local -i NestingLevelBeingEvaluated="$2"
   shift 2

   # The __TryLevel value is the same, regardless of the nesting level, when an error is caught.
   # The NestingLevelBeingEvaluated is the nesting level currently being evaluated.

   # Persist data from the subprocess only if NestingLevelBeingEvaluated == __TryLevel
   # or if this function is being called at the end of a :try subprocess with no errors.
   if (( NestingLevelBeingEvaluated == __TryLevel )) || (( $_try_status == 0 )); then
      # Separate the persistence file and the persistence variables for the current level
      local -a TryInfo=()
      IFS=' ' read -r -a TryInfo <<<"${__TryPersist[$__TryLevel]}"

      local TryPersistFile="${TryInfo[0]}"
      local -a TryPersistVars=()

      # Persist variables that exist from the current level
      local Var
      for Var in $(tr ' ' '\n' <<<"${TryInfo[@]:1} _try_status _try_error_line" | sort -u); do
         TryPersistVars+=( $Var )

         if [[ -v $Var ]] ; then
            # Determine if the variable is local to the :try block or relatively global
            if [[ " ${__TryLocals[$__TryLevel]} " =~ " $Var " ]] ; then
               declare -p "$Var" | LC_ALL=C sed 's|^declare|local|'
            else
               declare -p "$Var" | LC_ALL=C sed 's|^declare|local -g|'
            fi
         fi
      done >> "$TryPersistFile"

      # Merge persisted variables from the current level into the one level up
      # Is this a nested level (:try within :try)?
      if (( $__TryLevel > 0 )); then
         # Yes. Are there any variables to persist?
         if grep ' ' &>/dev/null <<<"${__TryPersist[$__TryLevel]}" ; then
            # Yes.  Combine the persistence variables from one level above and the current level.
            local PersistenceInfo="$(LC_ALL=C sed 's|^[^ ]* ||' <<<${__TryPersist[__TryLevel - 1]}) ${TryPersistVars[@]}"

            # Now, remove any duplicate variable names
            PersistenceInfo="$(tr ' ' '\n' <<<"$PersistenceInfo" | sort -u | tr '\n' ' ')"

            # Next, place the persistence file from the level one above at the beginning of the string
            PersistenceInfo="$(LC_ALL=C sed 's| .*||' <<<${__TryPersist[__TryLevel - 1]}) $PersistenceInfo"

            # Finally, emit to the persistence file to update the info for one level up
            echo "__TryPersist[$((__TryLevel - 1))]='$PersistenceInfo'" >> "$TryPersistFile"
         fi
      fi
   fi
   return 0
}

:try%TEST()
{
   echo 'Before try/catch'

   :try
   {
      echo 'Inside :try in :try%TEST, before calling function that throws an error'
      :::TestNest1
      echo 'Inside :try in  :try%TEST, after calling function that throws an error (uncaught and unexpected)'
   }
   :catch
   {
      echo "Caught $_try_status in :try%TEST"
      :throw
   }

   echo 'After try/catch (uncaught and unexpected)'
}

:::TestNest1()
{
   :try
   {
      echo 'Inside :try in :::TestNest1, before calling function that throws an error'
      :::TestNest2
      echo 'Inside :try in  :::TestNest1, after calling function that throws an error (uncaught and unexpected)'
   }
   :catch
   {
      echo "Caught $_try_status in :::TestNest1"
      :throw
   }
}

:::TestNest2()
{
   :try
   {
      echo 'Inside :try in :::TestNest2, before throwing an error code 37'
      (exit 37)
      echo 'Inside :try in  :::TestNest2, after throwing an error code 37 (uncaught and unexpected)'
   }
   :catch
   {
      echo "Caught $_try_status in :::TestNest2"
      :throw
   }
}
