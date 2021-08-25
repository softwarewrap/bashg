#!/bin/bash

:array:copy_associative()
{
   local ___array__copy_associative__copy_associative___Source="$1"
   local ___array__copy_associative__copy_associative___Destination="$2"

   local ___array__copy_associative__copy_associative___Copy
   ___array__copy_associative__copy_associative___Copy="$( declare -p "$___array__copy_associative__copy_associative___Source" )"
   eval declare -Ag "$___array__copy_associative__copy_associative___Destination=${___array__copy_associative__copy_associative___Copy#*=}"
}

:array:copy_associative%TEST()
{
   local -A ___array__copy_associative__copy_associativeTEST___Source
   ___array__copy_associative__copy_associativeTEST___Source=(
      [first]=1
      [second]=2
      [third]=3
   )

   :array:copy_associative ___array__copy_associative__copy_associativeTEST___Source ___array__copy_associative__copy_associativeTEST___Dest

   :array:dump_associative ___array__copy_associative__copy_associativeTEST___Source '<h1>Source</h1>'
   :array:dump_associative ___array__copy_associative__copy_associativeTEST___Dest '<h1>Dest</h1>'
}
