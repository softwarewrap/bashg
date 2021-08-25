#!/bin/bash

+ assert()
{
   local (.)_Test="$1"                                   # A test that can be eval'd
   local (.)_Emit="${2:-$1}"
   local (.)_Status=0                                    # The return status of the test, presumed to be a success

   eval "$(.)_Test" &>/dev/null || (.)_Status=$?
                                                         # Run the assertion and if an error, update the Status

   if (( $(.)_Status == 0 )); then
      :highlight: <<<"<G>PASS:</G> <b>$(.)_Emit</b>"

   else
      :highlight: <<<"<R>FAIL:</R> <b>$(.)_Emit</b>"     # Emit the failure message

      {                                                  # Show how the test failed
         BASH_XTRACEFD=1                                 # For set -x, set output to stdout
         set -x
         eval "$(.)_Test"                                # eval the test again, this time emitting output (set -x)
         set +x
         BASH_XTRACEFD=                                  # No longer redirect set -x output to stdout (now stderr)
      } |
      tail -n +2 |                                       # The first line is a restatement of the eval: discard
      head -1 |                                          # The next line is the actual test result: keep only that
      sed 's|++ \(.*\)|      <R>\1</R>|' |               # Remove set -x artifacts and format for highlighting
      :highlight:                                        # Highlight
   fi
}
