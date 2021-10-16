#!/bin/bash

+ copy_associative()
{
   local (.)_Source="$1"
   local (.)_Destination="$2"

   declare -Ag "$(.)_Destination"=
   eval "$(.)_Destination"=$(declare -p "$(.)_Source" | LC_ALL=C sed -e 's|^[^=]*=||' -e "s|^'||" -e "s|'$||")
}

+ copy_associative%TEST()
{
   local -A (.)_Source
   (.)_Source=(
      [first]=1
      [second]=2
      [third]=3
   )

   :array:copy_associative (.)_Source (.)_Dest

   :array:dump_associative (.)_Source '<h1>Source</h1>'
   :array:dump_associative (.)_Dest '<h1>Dest</h1>'
}
