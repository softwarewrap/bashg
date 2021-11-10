#!/bin/bash

:string:join()
{
   local __string__join__join___Options
   __string__join__join___Options=$(getopt -o 'a:d:p:s:v:' -l 'arrayname:,delimiter:,prefix:,suffix:,variable:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__string__join__join___Options"

   local __string__join__join___ArrayVar=                                   # Input is taken from this array name
   local __string__join__join___Delimiter=','                               # The default delimiter
   local __string__join__join___Prefix=                                     # Prefix the result with this
   local __string__join__join___Suffix=                                     # Suffix the result with this
   local __string__join__join___Var='__string__join__join___UnspecifiedVar'                    # The variable to store results in
   local __string__join__join___UnspecifiedVar=                             # Ensure there is a default place to store results in

   while true ; do
      case "$1" in
      -a|--array)       __string__join__join___ArrayVar="$2"; shift 2;;
      -d|--delimiter)   __string__join__join___Delimiter="$2"; shift 2;;
      -p|--prefix)      __string__join__join___Prefix="$2"; shift 2;;
      -s|--suffix)      __string__join__join___Suffix="$2"; shift 2;;
      -v|--var)         __string__join__join___Var="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   if [[ -n $__string__join__join___ArrayVar ]] ; then
      if [[ -v $__string__join__join___ArrayVar ]]; then
         __string__join__join___ArrayVar+='[@]'                               # Build indirect reference

         set -- "${!__string__join__join___ArrayVar}"

      else
         set --
      fi
   fi

   local __string__join__join___First="$1"
   (( $# == 0 )) || shift

   printf -v "$__string__join__join___Var" '%s' "$__string__join__join___First${@/#/$__string__join__join___Delimiter}"

   if [[ $__string__join__join___Var = __string__join__join___UnspecifiedVar ]]; then
      echo "$__string__join__join___UnspecifiedVar"
   fi
}

:string:join%TEST()
{
   local -a __string__join__joinTEST___Test1=()
   local -a __string__join__joinTEST___Test2=('a a')
   local -a __string__join__joinTEST___Test3=('a a' 'b b' 'c c')

   local -g __string__join__joinTEST___Out

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
   :assert '<args,  0, >stdout'  '[[ -z $__assert___Out ]]'                :string:join "${__string__join__joinTEST___Test1[@]}"
   :assert '<array, 0, >stdout'  '[[ -z $__assert___Out ]]'                :string:join -a __string__join__joinTEST___Test1

   :assert '<args,  1, >stdout'  '[[ $__assert___Out = "a a" ]]'           :string:join "${__string__join__joinTEST___Test2[@]}"
   :assert '<array, 1, >stdout'  '[[ $__assert___Out = "a a" ]]'           :string:join -a __string__join__joinTEST___Test2

   :assert '<args,  3, >stdout'  '[[ $__assert___Out = "a a,b b,c c" ]]'   :string:join "${__string__join__joinTEST___Test3[@]}"
   :assert '<array, 3, >stdout'  '[[ $__assert___Out = "a a,b b,c c" ]]'   :string:join -a __string__join__joinTEST___Test3

   # SET 2: Store to variable
   :assert '<args,  0, >var'     '[[ -z $__string__join__joinTEST___Out ]]'                       :string:join -v __string__join__joinTEST___Out "${__string__join__joinTEST___Test1[@]}"
   :assert '<array, 0, >var'     '[[ -z $__string__join__joinTEST___Out ]]'                       :string:join -a __string__join__joinTEST___Test1 -v __string__join__joinTEST___Out

   :assert '<args,  1, >var'     '[[ $__string__join__joinTEST___Out = "a a" ]]'                  :string:join -v __string__join__joinTEST___Out "${__string__join__joinTEST___Test2[@]}"
   :assert '<array, 1, >var'     '[[ $__string__join__joinTEST___Out = "a a" ]]'                  :string:join -a __string__join__joinTEST___Test2 -v __string__join__joinTEST___Out

   :assert '<args,  3, >var'     '[[ $__string__join__joinTEST___Out = "a a,b b,c c" ]]'          :string:join -v __string__join__joinTEST___Out "${__string__join__joinTEST___Test3[@]}"
   :assert '<array, 3, >var'     '[[ $__string__join__joinTEST___Out = "a a,b b,c c" ]]'          :string:join -a __string__join__joinTEST___Test3 -v __string__join__joinTEST___Out
}
