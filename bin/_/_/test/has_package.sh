#!/bin/bash

:test:has_package()
{
   local __test__has_package__has_package___Package="$1"

   [[ -n $__test__has_package__has_package___Package ]] || return 1

   rpm --quiet -q "$__test__has_package__has_package___Package"
}
