#!/bin/bash

+ copy_associative()
{
   local (.)_Source="$1"
   local (.)_Destination="$2"

   local (.)_Copy
   (.)_Copy="$( declare -p "$(.)_Source" )"
   eval declare -Ag "$(.)_Destination=${(.)_Copy#*=}"
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
