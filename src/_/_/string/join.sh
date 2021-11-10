#!/bin/bash

+ join()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'a:d:p:s:v:' -l 'arrayname:,delimiter:,prefix:,suffix:,variable:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_ArrayVar=                                   # Input is taken from this array name
   local (.)_Delimiter=','                               # The default delimiter
   local (.)_Prefix=                                     # Prefix the result with this
   local (.)_Suffix=                                     # Suffix the result with this
   local (.)_Var='(.)_UnspecifiedVar'                    # The variable to store results in
   local (.)_UnspecifiedVar=                             # Ensure there is a default place to store results in

   while true ; do
      case "$1" in
      -a|--array)       (.)_ArrayVar="$2"; shift 2;;
      -d|--delimiter)   (.)_Delimiter="$2"; shift 2;;
      -p|--prefix)      (.)_Prefix="$2"; shift 2;;
      -s|--suffix)      (.)_Suffix="$2"; shift 2;;
      -v|--var)         (.)_Var="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   if [[ -n $(.)_ArrayVar ]] ; then
      if [[ -v $(.)_ArrayVar ]]; then
         (.)_ArrayVar+='[@]'                               # Build indirect reference

         set -- "${!(.)_ArrayVar}"

      else
         set --
      fi
   fi

   local (.)_First="$1"
   (( $# == 0 )) || shift

   printf -v "$(.)_Var" '%s' "$(.)_First${@/#/$(.)_Delimiter}"

   if [[ $(.)_Var = (.)_UnspecifiedVar ]]; then
      echo "$(.)_UnspecifiedVar"
   fi
}

+ join%TEST()
{
   local -a (.)_Test1=()
   local -a (.)_Test2=('a a')
   local -a (.)_Test3=('a a' 'b b' 'c c')

   local -g (.)_Out

   :help: --set 'Test joining of array elements' --usage '' <<EOF
LEGEND:

   <args:   ^Input is given via function call with positional parameters
   <array:  ^Input is given via an array name

   #:       ^Array length is either 0, 1, or 3
               0: ()
               1: ('a a')
               3: ('a a' 'b b' 'c c')

   >stdout: ^Output is to stdout
   >var:    ^Output is to a variable\n
EOF

   # SET 1: Emit to stdout
   :assert '<args,  0, >stdout'  '[[ -z $(+:assert)_Out ]]'                (+):join "${(.)_Test1[@]}"
   :assert '<array, 0, >stdout'  '[[ -z $(+:assert)_Out ]]'                (+):join -a (.)_Test1

   :assert '<args,  1, >stdout'  '[[ $(+:assert)_Out = "a a" ]]'           (+):join "${(.)_Test2[@]}"
   :assert '<array, 1, >stdout'  '[[ $(+:assert)_Out = "a a" ]]'           (+):join -a (.)_Test2

   :assert '<args,  3, >stdout'  '[[ $(+:assert)_Out = "a a,b b,c c" ]]'   (+):join "${(.)_Test3[@]}"
   :assert '<array, 3, >stdout'  '[[ $(+:assert)_Out = "a a,b b,c c" ]]'   (+):join -a (.)_Test3

   # SET 2: Store to variable
   :assert '<args,  0, >var'     '[[ -z $(.)_Out ]]'                       (+):join -v (.)_Out "${(.)_Test1[@]}"
   :assert '<array, 0, >var'     '[[ -z $(.)_Out ]]'                       (+):join -a (.)_Test1 -v (.)_Out

   :assert '<args,  1, >var'     '[[ $(.)_Out = "a a" ]]'                  (+):join -v (.)_Out "${(.)_Test2[@]}"
   :assert '<array, 1, >var'     '[[ $(.)_Out = "a a" ]]'                  (+):join -a (.)_Test2 -v (.)_Out

   :assert '<args,  3, >var'     '[[ $(.)_Out = "a a,b b,c c" ]]'          (+):join -v (.)_Out "${(.)_Test3[@]}"
   :assert '<array, 3, >var'     '[[ $(.)_Out = "a a,b b,c c" ]]'          (+):join -a (.)_Test3 -v (.)_Out
}
