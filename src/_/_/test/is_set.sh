#!/bin/bash

+ is_set%HELP()
{
   local (.)_Synopsis='Determine whether a parameter is set'

   :help: --set "$(.)_Synopsis" --usage '<parameter>' <<EOF
OPTIONS:
   -v|--verbose               ^Emit to stdout

   --assert <return-code>     ^Assert the return code is as specified

DESCRIPTION:
   Check whether a parameter or indexed parameter is set

UNIT TEST:
   (+):is_set%TEST^ [-v|--verbose]

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

   (+):is_set  s           ^Returns 0
   (+):is_set  i           ^Returns 0
   (+):is_set  array       ^Returns 0
   (+):is_set  array[0]    ^Returns 0
   (+):is_set  array[2]    ^Returns 1 - index is not set
   (+):is_set  map         ^Returns 0
   (+):is_set  map[first]  ^Returns 0
   (+):is_set  map[third]  ^Returns 1 - index is not set
   (+):is_set  0abc        ^Returns 2 - parameters may not begin with a number
   (+):is_set  array[      ^Returns 2 - missing closing bracket
   (+):is_set  array[]     ^Returns 2 - missing index name
EOF
}

+ is_set()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'v0' -l 'verbose,true,assert:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (-)_Verbose=false                               # Emit the results of the test to stdout
   local (-)_HonorReturnCode=true                        # Force a true (0) return code
   local (-)_ExpectedReturnCode=0

   while true ; do
      case "$1" in
      -v|--verbose)     (-)_Verbose=true; shift;;
      -0|--true)        (-)_HonorReturnCode=false; shift;;

      --assert)         (-)_ExpectedReturnCode="$2"; shift 2;;

      --)               shift; break;;
      *)                break;;
      esac
   done

   local (-)_Test="$1"                                   # Keep the original parameter to test
   local (.)_Var="$(-)_Test"                             # The parameter to check, possibly indexed
   local (.)_Index=                                      # If non-empty, is the index
   local (.)_Type=other                                  # array, map, other: used to determine if

   local -i (-)_ReturnCode=0                             # The return code
   local -a (-)_ReturnCodes=(
      'Set'
      'Not Set'
      'An indexed variable must end with a square bracket'
      'Missing the index'
      'Invalid parameter syntax'
      'Non-numeric index to array provided'
   )

   if [[ $(.)_Var =~ '[' ]]; then                        # If the var is an indexed parameter
      (.)_Index="${(.)_Var#*[}"

      if [[ $(.)_Index != *']' ]]; then
         (-):Finalize 2                                  # An indexed variable must end with a square bracket
         return $(-)_ReturnCode
      fi

      (.)_Index="${(.)_Index%]}"                         # Index: Strip of the trailing square bracket
      if [[ -z $(.)_Index ]]; then
         (-):Finalize 3                                  # Missing the index
         return $(-)_ReturnCode
      fi

      (.)_Var="${(.)_Var%%[*}"                           # Var: Strip of the index
   fi

   if [[ ! ${(.)_Var%%[*} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
         (-):Finalize 4                                  # An invalid parameter syntax can never be set
         return $(-)_ReturnCode
   fi

   if ! (.)_Type="$(declare -p "$(.)_Var" 2>/dev/null)"; then
         (-):Finalize 1                                  # An invalid parameter syntax can never be set
         return $(-)_ReturnCode
   fi

   if [[ -n $(.)_Index ]]; then
      if [[ $(.)_Type =~ ^'declare -a' ]]; then
         if [[ ! $(.)_Index =~ ^[0-9]+$ ]]; then
            (-):Finalize 5                               # An invalid parameter syntax can never be set
            return $(-)_ReturnCode
         fi

         local (.)_IndirectNotEmpty="$(.)_Var[$(.)_Index]"
         eval local (.)_IndirectEmpty="$(.)_Var[$(.)_Index-IsEmpty]"

         [[ -n ${!(.)_IndirectNotEmpty} || -z ${(.)_IndirectEmpty} ]] || (-)_ReturnCode=1

      elif [[ $(.)_Type =~ ^'declare -A' ]]; then
         local (.)_IndirectNotEmpty="$(.)_Var[$(.)_Index]"
         eval local (.)_IndirectEmpty="$(.)_Var[$(.)_Index-IsEmpty]"

         [[ -n ${!(.)_IndirectNotEmpty} || -z ${(.)_IndirectEmpty} ]] || (-)_ReturnCode=1
      fi

   else
      [[ -v $(.)_Var ]]                                  # No index; just check if the parameter is set
   fi

   (-):Finalize
}

- Finalize()
{
   [[ -z $1 ]] || (-)_ReturnCode="$1"

   if $(-)_Verbose; then
      local (.)_State
      (( $(-)_ExpectedReturnCode == $(-)_ReturnCode )) && (.)_State='<G>PASS</G>' || (.)_State='<R>FAIL</R>'
      local (.)_Reason=
      (( $(-)_ReturnCode == 0 )) || (.)_Reason=", <b>${(-)_ReturnCodes[$(-)_ReturnCode]}</b>"
      echo "(+):is_set: $(.)_State $(-)_ReturnCode == $(-)_ExpectedReturnCode: $(-)_Test$(.)_Reason" | :highlight:
   fi

   (( $(-)_ExpectedReturnCode == $(-)_ReturnCode )) && (-)_ReturnCode=0 || (-)_ReturnCode=1

   $(-)_HonorReturnCode || (-)_ReturnCode=0

   return $(-)_ReturnCode
}

+ is_set%TEST()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'v' -l 'verbose' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Verbose=false
   local -a (.)_Args=()
   while true ; do
      case "$1" in
      -v|--verbose)  (.)_Verbose=true; (.)_Args+=( --verbose ); shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local (.)_Setup='
   declare s='string'
   declare -i i=37
   declare -a array=(1 2)
   declare -A map=([first]=1 [second]=)'

   if $(.)_Verbose; then
      :highlight: <<<'<b>Unit Test: <B>(+):is_set</B></b>'

      echo -e "$(.)_Setup\n"
      :highlight: <<<'<b>Expected vs. Actual:</b>\n'
   fi

   eval "$(.)_Setup"

   local (.)_Pass=true
   (+):is_set "${(.)_Args[@]}" --assert 0 's'            || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 0 'i'            || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 1 'x'            || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 0 'array'        || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 0 'array[0]'     || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 1 'array[2]'     || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 5 'array[first]' || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 0 'map'          || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 0 'map[first]'   || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 1 'map[third]'   || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 4 '0abc'         || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 2 'array['       || (.)_Pass=false
   (+):is_set "${(.)_Args[@]}" --assert 3 'array[]'      || (.)_Pass=false

   if $(.)_Verbose; then
      echo
      :highlight: '<b>Unit Test: done.'

   else
      local (.)_State
      $(.)_Pass && (.)_State='<G>PASS</G>' || (.)_State='<R>FAIL</R>'
      :highlight: <<<"<b>Unit Test: $(.)_State <B>\(+):is_set</B></b>"
   fi
}
