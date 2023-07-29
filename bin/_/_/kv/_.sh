#!/bin/bash

:kv:%STARTUP()
{
   local -g __kv______Var='__kv______UnspecifiedVar'                 # Ensure this variable exists and is set
}

:kv:%HELP()
{
   local __kv_____HELP___Synopsis=''
   :help: "$__kv_____HELP___Synopsis" --usage '[<options>] [<spec>]...' <<EOF
OPTIONS:
   -v|--var <var>    ^Explicitly specify the associative array parameter name
   -u|--unset        ^Unset the associative array before assigning key/value pairs
   -c|--clear        ^Clear the saved associative parameter name

DESCRIPTION:
   Set key/value pairs into an associative array

   <G>OPTIONS</G>

   Options are processed in the order in which they are presented and must preceed <spec> entries.

   If --var is explicitly specified, then <var> is used to specify the associative parameter name.
   If --var not specified or cleared, then the default of an anonymous array name is used.

   Notes:
      The <var> is saved between invocations of <b>:kv:</b> commands.
      If <var> is not declared, then it is declared with global scope

   If --unset is specified, then the associative array is unset.
   Unsetting does not clear any saved <var> name.

   If --clear is specified, then the saved name is reset to the default anonymous array name.

   Zero or more <spec> entries can be used to set key/value pairs into the <var> that is being used.
   The <var> is retained between invocations, so the specification of the <var> does not need to be
   done at the same time as issuing <spec> entries.

   <G>KEY VALUE SPECIFICATION</G>

   The <spec> entries take any of the following forms:

      <key> <value>     ^Simple assignment (use quoting as needed)
      @<file>           ^Source a <file> that consist of <b>:kv:</b> commands
      <key> -           ^The value is delivered via stdin (no additional parameters are allowed)
      <key> <<EOF       ^The value is delivered via the heredoc (no additional parameters are allowed)
      <value>           ^     The heredoc marker does not need to be EOF.
      EOF               ^     The newline before and after the heredoc marker is not part of the <value>.

   Note:
      If the <value> is missing, the empty string is used. This is not considered to be an error.

RETURN STATUS:
   0  ^Success
   1  ^The <var> contains invalid characters

EXAMPLES:
   :kv: --var A                  ^Store key/value pairs in the associative parameter A

   :kv: x 3 y 7 info <<KV        ^A[x]=3 A[y]=7 A[info]='line1\\\\nline2'
   line 1                        ^
   line 2                        ^
   KV                            ^

   cat >/etc/config.cfg <<END    ^Store :kv: commands in a file that will be sourced by the :kv: command
   :kv: p <<KV                   ^
   p line 1                      ^
   p line 2                      ^
   KV                            ^
   :kv: q <<KV                   ^
   q line 1                      ^
   q line 2                      ^
   KV                            ^
   :kv: r 'abc' s 'xyz' t        ^
   END                           ^

   :kv: @/etc/config.cfg         ^Source /etc/config.cfg to read in the above additional values
                                 ^A[p]='p line 1\\\\np line 2' A[q]='q line 1\\\\nq line 2' A[r]='abc' A[s]='xyz' A[t]=''

   echo -e '123\\\\n987' | :kv: last - ^
                                 ^A[last]='123\\\\n987'
EOF
}

:kv:()
{
   ### SAFELY PROCESS OPTIONS (NO REARRANGEMENT)
   :getopts: begin \
      -o 'v:uc' \
      -l 'var:,unset,clear' \
      -- "$@"

   local __kv________Unset=false                                 # Unset the associative array before processing <spec> items
   local __kv________Clear=false                                 # Clear the stored associative array

   while :getopts: next __kv________Option __kv________Value; do
      case "$__kv________Option" in
      -v|--var)         :kv:_:.var "$__kv________Value";;           # No need to shift; __kv________Value is populated only for k: key: options
      -u|--unset)       :kv:_:.unset;;
      -c|--clear)       :kv:_:.clear;;

      *)                break;;
      esac
   done

   local -a __kv________Args
   :getopts: end --save __kv________Args                         # Save any unused args

   set -- "${__kv________Args[@]}"
   while (( $# > 0 )); do

      if [[ $1 = @* ]]; then
         local __kv________File="${1#@}"
         if [[ ! -f $__kv________File ]]; then
            :log: "No such file: $__kv________File"
            return 2
         fi
         source "$__kv________File"
         shift

      elif (( $# > 1 )); then
         printf -v "$__kv______Var[$1]" '%s' "$2"              # Store the key/value pair
         shift 2

      elif :test:has_stdin; then
         printf -v "$__kv______Var[$1]" '%s' "$(cat)"          # Store the key with data from stdin
         shift

      else
         printf -v "$__kv______Var[$1]" '%s' ''                # Store the key with the empty string
         shift
      fi
   done
}

:kv:_:.var()
{
   local __kv________Var="$1"

   if [[ -n $__kv________Var && ! $__kv________Var =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      :log: "Invalid variable: $__kv________Var"                 # An invalid variable name was specified
      return 1
   fi

   if [[ -z $__kv________Var ]]; then
      __kv________Var='__kv______UnspecifiedVar'                       # Use the default variable
   fi

   __kv______Var="$__kv________Var"                                    # Store the new variable name

   if [[ ! -v  $__kv______Var ]]; then                         # If the <var> has not yet been declared,
      local -Ag "$__kv______Var"                               # ... then declare it with global scope
   fi
}

:kv:_:.unset()
{
   [[ -n $__kv______Var ]] || return 0                         # If the variable is empty, there's nothing to do

   if [[ $(declare -p $__kv______Var 2>/dev/null) = 'declare -A'* ]]; then
      unset "$__kv______Var"                                   # If the variable is an associative array, then unset it
      local -Ag "$__kv______Var"                               # Redeclare it
   fi
}

:kv:_:.clear()
{
   __kv______Var='__kv______UnspecifiedVar'                          # Set the variable back to the default
}

:kv:%TEST()
{
   local -A __kv_____TEST___Array=([test]=me)

   :kv: --var __kv_____TEST___Array

   :kv: x 3 y 7 info <<KV
line 1
line 2
KV

   local __kv_____TEST___TmpFile="$(mktemp)"
   cat > "$__kv_____TEST___TmpFile" <<EOF
:kv: p <<KV
p line 1
p line 2
KV

:kv: q <<KV
q line 1
q line 2
KV

:kv: r 'abc' s 'xyz' t
EOF

   :kv: @"$__kv_____TEST___TmpFile"

   rm -f "$__kv_____TEST___TmpFile"

   :array:dump_associative __kv_____TEST___Array '<h1>Associative Array</h1>'
}
