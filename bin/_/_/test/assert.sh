#!/bin/bash

:test:assert()
{
   local __test__assert__assert___Test="$1"                                   # A test that can be eval'd
   local __test__assert__assert___Emit="${2:-$1}"
   local __test__assert__assert___Status=0                                    # The return status of the test, presumed to be a success

   eval "$__test__assert__assert___Test" &>/dev/null || __test__assert__assert___Status=$?
                                                         # Run the assertion and if an error, update the Status

   if (( $__test__assert__assert___Status == 0 )); then
      :highlight: <<<"<G>PASS:</G> <b>$__test__assert__assert___Emit</b>"

   else
      :highlight: <<<"<R>FAIL:</R> <b>$__test__assert__assert___Emit</b>"     # Emit the failure message

      {                                                  # Show how the test failed
         BASH_XTRACEFD=1                                 # For set -x, set output to stdout
         set -x
         eval "$__test__assert__assert___Test"                                # eval the test again, this time emitting output (set -x)
         set +x
         BASH_XTRACEFD=                                  # No longer redirect set -x output to stdout (now stderr)
      } |
      tail -n +2 |                                       # The first line is a restatement of the eval: discard
      head -1 |                                          # The next line is the actual test result: keep only that
      sed -e '
         s|++\s*\(\[\[\s*\)\(.*\)|      \2|              # Remove set -x artifacts and leading [[
         s|\s*\]\]\s*$||                                 # Remove trailing ]]
         s|.*|<R>&</R>|                                  # Add red markup
      ' |
      :sed:escape |
      :highlight:                                        # Highlight
   fi
}
