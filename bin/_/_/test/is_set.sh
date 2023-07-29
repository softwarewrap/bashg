#!/bin/bash

:test:is_set%HELP()
{
   local __test__is_set__is_setHELP___Synopsis='Determine whether a parameter is set'

   :help: --set "$__test__is_set__is_setHELP___Synopsis" --usage '<parameter>' <<EOF
OPTIONS:
   -v|--verbose               ^Emit to stdout

   --assert <return-code>     ^Assert the return code is as specified

DESCRIPTION:
   Check whether a parameter or indexed parameter is set

UNIT TEST:
   :test:is_set%TEST^ [-v|--verbose]

   With the --verbose option, the unit test emits diagnostic information to stdout.

RETURN STATUS:
   0  ^Success
   1  ^Not Set
   2  ^Variable syntax is not valid
   3  ^Missing the array index
   4  ^Invalid parameter syntax
   5  ^Non-numeric index to positional array provided

EXAMPLES:
   declare s='string'^
   declare -i i=37^
   declare -a array=(1 2)^
   declare -A map=([first]=1 [second]=)^

   :test:is_set  s           ^Returns 0
   :test:is_set  i           ^Returns 0
   :test:is_set  array       ^Returns 0
   :test:is_set  array[0]    ^Returns 0
   :test:is_set  array[2]    ^Returns 1 - index is not set
   :test:is_set  map         ^Returns 0
   :test:is_set  map[first]  ^Returns 0
   :test:is_set  map[third]  ^Returns 1 - index is not set
   :test:is_set  0abc        ^Returns 2 - parameters may not begin with a number
   :test:is_set  array[      ^Returns 2 - missing closing bracket
   :test:is_set  array[]     ^Returns 2 - missing index name
EOF
}

:test:is_set()
{
   local __test__is_set__is_set___Options
   __test__is_set__is_set___Options=$(getopt -o 'v0' -l 'verbose,true,assert:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__test__is_set__is_set___Options"

   local __test__is_set___Verbose=false                               # Emit the results of the test to stdout
   local __test__is_set___HonorReturnCode=true                        # Force a true (0) return code
   local __test__is_set___ExpectedReturnCode=0

   while true ; do
      case "$1" in
      -v|--verbose)     __test__is_set___Verbose=true; shift;;
      -0|--true)        __test__is_set___HonorReturnCode=false; shift;;

      --assert)         __test__is_set___ExpectedReturnCode="$2"; shift 2;;

      --)               shift; break;;
      *)                break;;
      esac
   done

   local __test__is_set___Test="$1"                                   # Keep the original parameter to test
   local __test__is_set__is_set___Var="$__test__is_set___Test"                             # The parameter to check, possibly indexed
   local __test__is_set__is_set___Index=                                      # If non-empty, is the index
   local __test__is_set__is_set___Type=other                                  # array, map, other: used to determine if

   local -i __test__is_set___ReturnCode=0                             # The return code
   local -a __test__is_set___ReturnCodes=(
      'Set'
      'Not Set'
      'An indexed variable must end with a square bracket'
      'Missing the index'
      'Invalid parameter syntax'
      'Non-numeric index to array provided'
   )

   if [[ $__test__is_set__is_set___Var =~ '[' ]]; then                        # If the var is an indexed parameter
      __test__is_set__is_set___Index="${__test__is_set__is_set___Var#*[}"

      if [[ $__test__is_set__is_set___Index != *']' ]]; then
         :test:is_set:Finalize 2                                  # An indexed variable must end with a square bracket
         return $__test__is_set___ReturnCode
      fi

      __test__is_set__is_set___Index="${__test__is_set__is_set___Index%]}"                         # Index: Strip of the trailing square bracket
      if [[ -z $__test__is_set__is_set___Index ]]; then
         :test:is_set:Finalize 3                                  # Missing the index
         return $__test__is_set___ReturnCode
      fi

      __test__is_set__is_set___Var="${__test__is_set__is_set___Var%%[*}"                           # Var: Strip of the index
   fi

   if [[ ! ${__test__is_set__is_set___Var%%[*} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
         :test:is_set:Finalize 4                                  # An invalid parameter syntax can never be set
         return $__test__is_set___ReturnCode
   fi

   if ! __test__is_set__is_set___Type="$(declare -p "$__test__is_set__is_set___Var" 2>/dev/null)"; then
         :test:is_set:Finalize 1                                  # An invalid parameter syntax can never be set
         return $__test__is_set___ReturnCode
   fi

   if [[ -n $__test__is_set__is_set___Index ]]; then
      if [[ $__test__is_set__is_set___Type =~ ^'declare -a' ]]; then
         if [[ ! $__test__is_set__is_set___Index =~ ^[0-9]+$ ]]; then
            :test:is_set:Finalize 5                               # An invalid parameter syntax can never be set
            return $__test__is_set___ReturnCode
         fi

         local __test__is_set__is_set___IndirectNotEmpty="$__test__is_set__is_set___Var[$__test__is_set__is_set___Index]"
         eval local __test__is_set__is_set___IndirectEmpty="$__test__is_set__is_set___Var[$__test__is_set__is_set___Index-IsEmpty]"

         [[ -n ${!__test__is_set__is_set___IndirectNotEmpty} || -z ${__test__is_set__is_set___IndirectEmpty} ]] || __test__is_set___ReturnCode=1

      elif [[ $__test__is_set__is_set___Type =~ ^'declare -A' ]]; then
         local __test__is_set__is_set___IndirectNotEmpty="$__test__is_set__is_set___Var[$__test__is_set__is_set___Index]"
         eval local __test__is_set__is_set___IndirectEmpty="$__test__is_set__is_set___Var[$__test__is_set__is_set___Index-IsEmpty]"

         [[ -n ${!__test__is_set__is_set___IndirectNotEmpty} || -z ${__test__is_set__is_set___IndirectEmpty} ]] || __test__is_set___ReturnCode=1
      fi

   else
      [[ -v $__test__is_set__is_set___Var ]]                                  # No index; just check if the parameter is set
   fi

   :test:is_set:Finalize
}

:test:is_set:Finalize()
{
   [[ -z $1 ]] || __test__is_set___ReturnCode="$1"

   if $__test__is_set___Verbose; then
      local __test__is_set__Finalize___State
      (( $__test__is_set___ExpectedReturnCode == $__test__is_set___ReturnCode )) && __test__is_set__Finalize___State='<G>PASS</G>' || __test__is_set__Finalize___State='<R>FAIL</R>'
      local __test__is_set__Finalize___Reason=
      (( $__test__is_set___ReturnCode == 0 )) || __test__is_set__Finalize___Reason=", <b>${__test__is_set___ReturnCodes[$__test__is_set___ReturnCode]}</b>"
      echo ":test:is_set: $__test__is_set__Finalize___State $__test__is_set___ReturnCode == $__test__is_set___ExpectedReturnCode: $__test__is_set___Test$__test__is_set__Finalize___Reason" | :highlight:
   fi

   (( $__test__is_set___ExpectedReturnCode == $__test__is_set___ReturnCode )) && __test__is_set___ReturnCode=0 || __test__is_set___ReturnCode=1

   $__test__is_set___HonorReturnCode || __test__is_set___ReturnCode=0

   return $__test__is_set___ReturnCode
}

:test:is_set%TEST()
{
   local __test__is_set__is_setTEST___Options
   __test__is_set__is_setTEST___Options=$(getopt -o 'v' -l 'verbose' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__test__is_set__is_setTEST___Options"

   local __test__is_set__is_setTEST___Verbose=false
   local -a __test__is_set__is_setTEST___Args=()
   while true ; do
      case "$1" in
      -v|--verbose)  __test__is_set__is_setTEST___Verbose=true; __test__is_set__is_setTEST___Args+=( --verbose ); shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local __test__is_set__is_setTEST___Setup='
   declare s='string'
   declare -i i=37
   declare -a array=(1 2)
   declare -A map=([first]=1 [second]=)'

   if $__test__is_set__is_setTEST___Verbose; then
      :highlight: <<<'<b>Unit Test: <B>:test:is_set</B></b>'

      echo -e "$__test__is_set__is_setTEST___Setup\n"
      :highlight: <<<'<b>Expected vs. Actual:</b>\n'
   fi

   eval "$__test__is_set__is_setTEST___Setup"

   local __test__is_set__is_setTEST___Pass=true
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 0 's'            || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 0 'i'            || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 1 'x'            || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 0 'array'        || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 0 'array[0]'     || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 1 'array[2]'     || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 5 'array[first]' || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 0 'map'          || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 0 'map[first]'   || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 1 'map[third]'   || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 4 '0abc'         || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 2 'array['       || __test__is_set__is_setTEST___Pass=false
   :test:is_set "${__test__is_set__is_setTEST___Args[@]}" --assert 3 'array[]'      || __test__is_set__is_setTEST___Pass=false

   if $__test__is_set__is_setTEST___Verbose; then
      echo
      :highlight: '<b>Unit Test: done.'

   else
      local __test__is_set__is_setTEST___State
      $__test__is_set__is_setTEST___Pass && __test__is_set__is_setTEST___State='<G>PASS</G>' || __test__is_set__is_setTEST___State='<R>FAIL</R>'
      :highlight: <<<"<b>Unit Test: $__test__is_set__is_setTEST___State <B>(+):is_set</B></b>"
   fi
}
