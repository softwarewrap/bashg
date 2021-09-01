#!/bin/bash

+ sort()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'v:u' -l 'var:,unique,locale:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Locale='C'
   local (.)_Var='(.)_UnspecifiedVar'
   local -a (.)_SortOptions=()

   while true ; do
      case "$1" in
      -v|--var)      (.)_Var="$2"; shift 2;;
      -u|--unique)   (.)_SortOptions+=( -u ); shift 2;;

      --locale)      (.)_Locale="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   if [[ -z $(.)_Var ]]; then                            # The Var is a required option
      :error: 1 'No variable name was specified'
      return 1
   fi

   local (.)_Indirect="$(.)_Var[@]"                      # Build an indirect reference to the Var array
   local -a (.)_Copy=( "${!(.)_Indirect}" )

   (( ${#(.)_Copy[@]} > 1 )) || return 0                 # Sort not need if the array has 0 elements or 1 element
                                                         # Copy the Var array

   local -a (.)_Esc                                      # Escape array elements: handle multi-line elements
   (.)_Esc=( $(
      printf '%q\n' "${(.)_Copy[@]}" |                   # %q for quoting allows for the safe use of eval
      LC_ALL="$(.)_Locale" sort "${(.)_SortOptions[@]}"
                                                         # Sort according to locale with possible other options
      )
   )

   eval "$(.)_Var"=\( "${(.)_Esc[@]}" \)
                                                         # Write to the caller's variable the unescaped array
}

+ sort%TEST()
{
   # Multi-line test case, kept intact for comparision
   local -a test=(
      $'X\nB\n0'                                         # Index 0, on separate lines: X B 0
      $'X\nA\n2'                                         # Index 1, on separate lines: X A 2
      $'X\nC\n1'                                         # Index 2, on separate lines: X C 1
      $'X\nA\n1'                                         # Index 3, on separate lines: X A 1
      $'X\nC\n1'                                         # Index 4, on separate lines: X C 1
      $'X\nB\n0'                                         # Index 5, on separate lines: X B 0
   )

   :highlight: <<<'<h1>Test array with multi-line elements</h1>\n\n<b>test, test1, and test2 initial state:</b>\n'
   local -i I
   for (( I=0; I<${#test[@]}; I++ )); do
      printf '   %2d\t%q\n' "$I" "${test[I]}"
   done
   echo

   # Duplicate array for two tests
   local -a test1=( "${test[@]}" )
   local -a test2=( "${test[@]}" )

   :highlight: <<<'<hr>\n<h2>Allow duplicate elements</h2>\n'
   :highlight: <<<'<b>(+):sort -var test1</b>\n'
   (+):sort --var test1
   for (( I=0; I<${#test1[@]}; I++ )); do
      printf '   %2d\t%q\n' "$I" "${test1[I]}"
   done

   :highlight: <<<'\n<b>Validation Testing:</b>\n'
   (-):assert '(( ${#test1[@]} == 6 ))'
   echo

   (-):assert '[[ ${test1[0]} = ${test[3]} ]]'   # X A 1
   (-):assert '[[ ${test1[1]} = ${test[1]} ]]'   # X A 2
   (-):assert '[[ ${test1[2]} = ${test[0]} ]]'   # X B 0
   (-):assert '[[ ${test1[3]} = ${test[5]} ]]'   # X B 0
   (-):assert '[[ ${test1[4]} = ${test[2]} ]]'   # X C 1
   (-):assert '[[ ${test1[5]} = ${test[4]} ]]'   # X C 1
   echo

   :highlight: <<<'<hr>\n<h2>Remove duplicate elements</h2>\n'
   :highlight: <<<'<b>(+):sort -var test2 --unique</b>\n'
   (+):sort --var test2 --unique
   for (( I=0; I<${#test2[@]}; I++ )); do
      printf '   %2d\t%q\n' "$I" "${test2[I]}"
   done

   :highlight: <<<'\n<b>Validation Testing:</b>\n'
   (-):assert '(( ${#test2[@]} == 4 ))'
   echo

   (-):assert '[[ "${test2[0]}" = "${test[3]}" ]]'  # X A 1
   (-):assert '[[ "${test2[1]}" = "${test[1]}" ]]'  # X A 2
   (-):assert '[[ "${test2[2]}" = "${test[0]}" ]]'  # X B 0
   (-):assert '[[ "${test2[3]}" = "${test[2]}" ]]'  # X C 1
}

- assert()
{
   local (.)_Test="$1"                                   # A test that can be eval'd
   local (.)_Status=0                                    # The return status of the test, presumed to be a success

   eval "$(.)_Test" >/dev/null 2>&1 || (.)_Status=$?
                                                         # Run the assertion and if an error, update the Status
   if (( $(.)_Status == 0 )); then
      :highlight: <<<"<G>PASS:</G> <b>$(.)_Test</b>"

   else
      :highlight: <<<"<R>FAIL:</R> <b>$(.)_Test</b>"
   fi
}
