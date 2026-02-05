#!/bin/bash

:array:copy_associative()
{
   local __array__copy_associative__copy_associative___Source="$1"
   local __array__copy_associative__copy_associative___Destination="$2"

   declare -Ag "$__array__copy_associative__copy_associative___Destination"=
   eval "$__array__copy_associative__copy_associative___Destination"=$(declare -p "$__array__copy_associative__copy_associative___Source" | LC_ALL=C sed -e 's|^[^=]*=||' -e "s|^'||" -e "s|'$||")
}

:array:copy_associative%TEST()
{
   local -A __array__copy_associative__copy_associativeTEST___Source
   __array__copy_associative__copy_associativeTEST___Source=(
      [first]=1
      [second]=2
      [third]=3
   )

   :array:copy_associative __array__copy_associative__copy_associativeTEST___Source __array__copy_associative__copy_associativeTEST___Dest

   :array:dump_associative __array__copy_associative__copy_associativeTEST___Source '<h1>Source</h1>'
   :array:dump_associative __array__copy_associative__copy_associativeTEST___Dest '<h1>Dest</h1>'
}
