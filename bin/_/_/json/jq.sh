#!/bin/bash

:json:jq%HELP()
{
   local __json__jq__jqHELP___Synopsis='Perform a jq filter with error checking'

   :help: --set "$__json__jq__jqHELP___Synopsis" --usage '<variable> <filter> [<file>]' <<EOF
OPTIONS:
   --null-allowed    ^Save null results as null
   --no-save-empty   ^Do not save empty results

DESCRIPTION:
   Perform jq a filter with error checking and post actions, saving or emitting results

   If <variable> is <b>-</b>, then emit results to stdout; otherwise, save results to the variable.
   The <filter> can be any <b>jq</b> filter.
   This command reads from <b>stdin</b> unless a <file> is specified.

   By default, <b>null</b> results are converted to the empty string.
   If --null-allowed is specified, then the <b>null</b> result is left intact.

   By default, empty results will be saved to the specified variable.
   If --no-save-empty is specified, then do not write to the variable or emit results to stdout
   when the result is either the empty string or the literal <B>null</B>.

EXAMPLES:
   :json:jq Var .x <<<'{"x":7}'                    ^Result: ^>G7
   :json:jq Var .abc <<<'{"x":7}'                  ^Result: <empty-string>
   :json:jq --null-allowed Var .abc <<<'{"x":7}'   ^Result: ^>Gnull
   :json:jq --no-save-empty Var .abc <<<'{"x":7}'  ^Result: <variable-unchanged>
EOF
}

:json:jq()
{
   :getopts: begin -l 'null-allowed,no-save-empty' -- "$@"

   local __json__jq__jq___Option                                      # Iterate over options
   local __json__jq__jq___Value                                       # For options that take args, store in this variable

   local __json__jq__jq___NullToEmpty=true                            # By default, convert 'null' to ''
   local __json__jq__jq___SaveEmpty=true                              # By default, save to variable even if 'null' or ''

   local -ag __json__jq__jq___Args=()

   while :getopts: next __json__jq__jq___Option __json__jq__jq___Value; do
      case "$__json__jq__jq___Option" in
      --null-allowed)   __json__jq__jq___NullToEmpty=false;;          # Save 'null' as 'null' (default: save as '')
      --no-save-empty)  __json__jq__jq___SaveEmpty=false;;            # Do not save if result is empty; implies --null-to-empty
      *)                break;;
      esac
   done

   :getopts: end --save __json__jq__jq___Args                         # Save unused args
   set -- "${__json__jq__jq___Args[@]}"

   local __json__jq__jq___Var="${1:--}"                               # Place the result in this variable
   shift

   if [[ $__json__jq__jq___Var = - ]]; then                           # - indicates: emit to stdout
      __json__jq__jq___Var='__json__jq__jq___UnspecifiedVar'                       # Use this as the variable to store the result
      local "$__json__jq__jq___Var="                                  # and declare and initialize it to the empty string
   fi

   local __json__jq__jq___Result                                      # The result
   local -i __json__jq__jq___Return=0                                 # The return code, assumed to be successful
   local __json__jq__jq___ErrorFile                                   # Any error message

   __json__jq__jq___ErrorFile="$(mktemp)"

   __json__jq__jq___Result="$(jq -e "$@" 2>"$__json__jq__jq___ErrorFile")" || __json__jq__jq___Return=$?
                                                         # Get the result and safely get the return code

   if (( $__json__jq__jq___Return == 0 || $__json__jq__jq___Return == 1 )); then   # 0: success, 1: valid value (null or false)
      if [[ ! -v $__json__jq__jq___Var ]]; then                       # If the variable isn't initialized, then try to declare it
         local -g "$__json__jq__jq___Var"                             # Yes, declare it
      fi

      if $__json__jq__jq___NullToEmpty && [[ $__json__jq__jq___Result = null ]]; then
         __json__jq__jq___Result=                                     # Convert 'null' to '' if requested
      fi

      if $__json__jq__jq___SaveEmpty || [[ -n $__json__jq__jq___Result ]]; then    # Save if allowing to save empty or if the result is non-empty
         if [[ $__json__jq__jq___Var = __json__jq__jq___UnspecifiedVar ]]; then
            printf '%s' "$__json__jq__jq___Result"                    # Emit the result to stdout
         else
            printf -v "$__json__jq__jq___Var" '%s' "$__json__jq__jq___Result"      # Then save the result in the indicated variable
         fi
      fi

      __json__jq__jq___Return=0                                       # Return success: A return of 1 is actually a valid response

   else
      :log: "The jq expression failed [$__json__jq__jq___Return]: $*" # Emit jq arguments associated with the failure

      if [[ -s $__json__jq__jq___ErrorFile ]]; then
         cat "$__json__jq__jq___ErrorFile"                            # Emit jq failure message
      fi
   fi

   rm -f "$__json__jq__jq___ErrorFile"

   return $__json__jq__jq___Return
}

:json:jq%TEST()
{
   local __json__jq__jqTEST___Var=

   :highlight: <<<'<h1>Unit Test</h1>\n\nSTDIN:  {"x": 7}\nBEFORE EACH TEST: Var=initial\n'

   {
      __json__jq__jqTEST___Var='initial'
      :json:jq __json__jq__jqTEST___Var .x <<<'{"x": 7}'
      [[ $__json__jq__jqTEST___Var = '7' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq Var .x|Expect '7',       got '$__json__jq__jqTEST___Var'"

      __json__jq__jqTEST___Var='initial'
      :json:jq __json__jq__jqTEST___Var .abc <<<'{"x": 7}'
      [[ $__json__jq__jqTEST___Var = '' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq Var .abc|Expect '',        got: '$__json__jq__jqTEST___Var'"

      __json__jq__jqTEST___Var='initial'
      :json:jq --null-allowed __json__jq__jqTEST___Var .abc <<<'{"x": 7}'
      [[ $__json__jq__jqTEST___Var = 'null' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq --null-allowed Var .abc|Expect 'null',    got '$__json__jq__jqTEST___Var'"

      __json__jq__jqTEST___Var='initial'
      :json:jq --no-save-empty __json__jq__jqTEST___Var .abc <<<'{"x": 7}'
      [[ $__json__jq__jqTEST___Var = 'initial' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq --no-save-empty Var .abc|Expect 'initial', got '$__json__jq__jqTEST___Var'"
   } | :text:align | :highlight:
}
