#!/bin/bash

:test:has_func()
{
   local __test__has_func__has_func___type
   __test__has_func__has_func___type="$(type -t "$1" || true)"                    # Get the type of the presented identifier

   [[ $__test__has_func__has_func___type = function ]]                            # Check whether this is a function
}
