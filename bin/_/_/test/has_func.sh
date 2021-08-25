#!/bin/bash

:test:has_func()
{
   local ___test__has_func__has_func___type
   ___test__has_func__has_func___type="$(type -t "$1" || true)"                    # Get the type of the presented identifier

   [[ $___test__has_func__has_func___type = function ]]                            # Check whether this is a function
}
