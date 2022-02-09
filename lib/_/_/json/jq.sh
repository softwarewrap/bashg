#!/bin/bash

+ jq%HELP()
{
   local (.)_Synopsis='Perform a jq filter with error checking'

   :help: --set "$(.)_Synopsis" --usage '<variable> <filter> [<file>]' <<EOF
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

+ jq()
{
   :getopts: begin -l 'null-allowed,no-save-empty' -- "$@"

   local (.)_Option                                      # Iterate over options
   local (.)_Value                                       # For options that take args, store in this variable

   local (.)_NullToEmpty=true                            # By default, convert 'null' to ''
   local (.)_SaveEmpty=true                              # By default, save to variable even if 'null' or ''

   local -ag (.)_Args=()

   while :getopts: next (.)_Option (.)_Value; do
      case "$(.)_Option" in
      --null-allowed)   (.)_NullToEmpty=false;;          # Save 'null' as 'null' (default: save as '')
      --no-save-empty)  (.)_SaveEmpty=false;;            # Do not save if result is empty; implies --null-to-empty
      *)                break;;
      esac
   done

   :getopts: end --save (.)_Args                         # Save unused args
   set -- "${(.)_Args[@]}"

   local (.)_Var="${1:--}"                               # Place the result in this variable
   shift

   if [[ $(.)_Var = - ]]; then                           # - indicates: emit to stdout
      (.)_Var='(.)_UnspecifiedVar'                       # Use this as the variable to store the result
      local "$(.)_Var="                                  # and declare and initialize it to the empty string
   fi

   local (.)_Result                                      # The result
   local -i (.)_Return=0                                 # The return code, assumed to be successful
   local (.)_ErrorFile                                   # Any error message

   (.)_ErrorFile="$(mktemp)"

   (.)_Result="$(jq -e "$@" 2>"$(.)_ErrorFile")" || (.)_Return=$?
                                                         # Get the result and safely get the return code

   if (( $(.)_Return == 0 || $(.)_Return == 1 )); then   # 0: success, 1: valid value (null or false)
      if [[ ! -v $(.)_Var ]]; then                       # If the variable isn't initialized, then try to declare it
         local -g "$(.)_Var"                             # Yes, declare it
      fi

      if $(.)_NullToEmpty && [[ $(.)_Result = null ]]; then
         (.)_Result=                                     # Convert 'null' to '' if requested
      fi

      if $(.)_SaveEmpty || [[ -n $(.)_Result ]]; then    # Save if allowing to save empty or if the result is non-empty
         if [[ $(.)_Var = (.)_UnspecifiedVar ]]; then
            printf '%s' "$(.)_Result"                    # Emit the result to stdout
         else
            printf -v "$(.)_Var" '%s' "$(.)_Result"      # Then save the result in the indicated variable
         fi
      fi

      (.)_Return=0                                       # Return success: A return of 1 is actually a valid response

   else
      :log: "The jq expression failed [$(.)_Return]: $*" # Emit jq arguments associated with the failure

      if [[ -s $(.)_ErrorFile ]]; then
         cat "$(.)_ErrorFile"                            # Emit jq failure message
      fi
   fi

   rm -f "$(.)_ErrorFile"

   return $(.)_Return
}

+ jq%TEST()
{
   local (.)_Var=

   :highlight: <<<'<h1>Unit Test</h1>\n\nSTDIN:  {"x": 7}\nBEFORE EACH TEST: Var=initial\n'

   {
      (.)_Var='initial'
      :json:jq (.)_Var .x <<<'{"x": 7}'
      [[ $(.)_Var = '7' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq Var .x|Expect '7',       got '$(.)_Var'"

      (.)_Var='initial'
      :json:jq (.)_Var .abc <<<'{"x": 7}'
      [[ $(.)_Var = '' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq Var .abc|Expect '',        got: '$(.)_Var'"

      (.)_Var='initial'
      :json:jq --null-allowed (.)_Var .abc <<<'{"x": 7}'
      [[ $(.)_Var = 'null' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq --null-allowed Var .abc|Expect 'null',    got '$(.)_Var'"

      (.)_Var='initial'
      :json:jq --no-save-empty (.)_Var .abc <<<'{"x": 7}'
      [[ $(.)_Var = 'initial' ]] && echo -n '<G>PASS</G> ' || echo -n '<R>FAIL</R> '
      echo ":json:jq --no-save-empty Var .abc|Expect 'initial', got '$(.)_Var'"
   } | :text:align | :highlight:
}
