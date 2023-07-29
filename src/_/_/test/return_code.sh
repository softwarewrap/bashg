#!/bin/bash

+ return_code%TEST()
{
   if [[ $- = *e* ]]; then
      echo $'\nThe --mask-errors (ignore errors) flag was not used.'
      echo $'Of 5 tests, expect to see 2 and 3, never 1 or 4'
      echo $'Expect to NOT see 5, because the interrupt at 4 is caught\n'

      true (||) echo 'TEST 1: No message is expected'
      true (&&) echo 'TEST 2: This message is expected'
      true (&&) echo 'TEST 3: A true message is expected' (||) echo 'TEST 3: A false message is not expected'

      false (||) echo 'TEST 4: Failure is expected; this message is NOT expected [error is masked]'
      false (&&) echo 'TEST 5: No message is expected because an interrupt at 4 should happen'

      echo "Finished without interruption (unexpected)"

   else
      echo $'\nThe --mask-errors (ignore errors) flag was used.'
      echo $'Of 5 tests, expect to see 2 and 3, never 1 or 4'
      echo $'Expect to see 5, because the interrupt at 4 is masked\n'

      true (||) echo 'TEST 1: No message is expected'
      true (&&) echo 'TEST 2: This message is expected'

      false (||) echo 'TEST 3: This message is expected [error is masked]'
      false (&&) echo 'TEST 4: No message is expected'
      false (&&) echo 'TEST 5: No TRUE message is expected' (||) echo 'TEST 5: A FALSE message is expected'

      echo "Finished without interruption (expected)"
   fi
}
