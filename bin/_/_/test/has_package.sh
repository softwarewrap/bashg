#!/bin/bash

:test:has_package()
{
   local ___test__has_package__has_package___Package="$1"

   [[ -n $___test__has_package__has_package___Package ]] || return 1

   rpm --quiet -q "$___test__has_package__has_package___Package"
}
