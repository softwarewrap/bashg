#!/bin/bash

+ has_package()
{
   local (.)_Package="$1"

   [[ -n $(.)_Package ]] || return 1

   rpm --quiet -q "$(.)_Package"
}
