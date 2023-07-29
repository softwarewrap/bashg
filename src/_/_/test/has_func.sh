#!/bin/bash

+ has_func()
{
   local (.)_type
   (.)_type="$(type -t -- "$1" || true)"                 # Get the type of the presented identifier

   [[ $(.)_type = function ]]                            # Check whether this is a function
}
