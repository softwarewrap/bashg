#!/bin/bash

:getopts:%HELP()
{
   local __getopts_____HELP___Synopsis='Process options with no rearrangement and partial handling'

   :help: --set "$__getopts_____HELP___Synopsis" --usage '<directive> [<directive-options>]' <<'EOF'
DESCRIPTION:
   Perform option parsing until the first unrecognized option or non-option argument is scanned.

   The first argument to :getopts: is the <directive> to be performed. The following directives are defined:

      begin    ^Begin :getopts: processing
      next     ^Process next available option
      end      ^End :getopts: processing

   Each <directive> can have its own <directive-options>.

   Use :getopts: instead of the built-in getopts when option parsing might be needed in multiple steps.
   This is useful when an early option determines the parsing of later options.

   <G>No rearrangement</G> of options is performed as this API is layered on top of the getopts built-in command.
   This API supports short options, long options, and nesting.

DIRECTIVE: begin <directive-options> -- <parameters>^<R
   -o|--short <short-options>    ^A string containing the single-character options similar to getopt(1)
   -l|--long <long-options>      ^A string containing the multiple-character options similar to getopt(1)

   This directive starts a new parsing context. Nesting is permitted, but operates with its own data.
   <short-options> are of the form <b><char></b> or <b><char>:</b> where <char> is a single character allowed by Bash getopts.
   <long-options> are of the form <b><word></b> or <b><word>:</b> where <word> is a long option word similar to that of getopt(1).
   The -- argument is required and must precede the <parameters> requiring scanning, typically <b>"$@"</b>, but
   can be any array or list of arguments.

DIRECTIVE: next <option-var> <value-var> [<stop-var>]^<R

   This directive is used to fetch the next option-value pair.

   The variable <option-var> is loaded with the next scanned option.
   The variable <value-var> is loaded with the next scanned value for options taking an argument.
   The variable <stop-var>, if present, is set to <b>true</b> if <B>--</B> is encountered and <b>false</b> otherwise.

   Note: it is not necessary to shift parameters during processing as is done with getopt(1).

   A return value of 0 indicates additional values are available for parsing.
   A return value of 1 indicates that no additional values are available for parsing.

DIRECTIVE: end <directive-options>^<R
   --save <array-var>            ^Save any unprocessed parmeters
   --append                      ^Append to the <array-var> instead of overwriting

   This directive ends an existing parsing context and is required.

   The --save option allows unprocessed arguments to be stored in the specified <array-var>.
   If the <array-var> is not previously declared, it will be declared automatically with global scope.
   If the --append option is given, the <array-var> is appended to instead of being overwritten.

EXAMPLE:
   local Flag=false                          ^# Short flag option default value
   local Arg=                                ^# Short arg option default value
   local LongFlag=false                      ^# Long flag option default value
   local LongArg=                            ^# Long arg option default value

   local Option                              ^# Iterator: Option to process
   local Value                               ^# Iterator: Value to process

   :getopts: <G>begin</G> -o 'fa:' -l 'flag,arg:,long-flag-only,long-arg-only:' -- "$@"^

   while :getopts: <G>next</G> Option Value; do     ^# Recognize args as Option/Value pairs until end/unknown
      case "$Option" in                      ^# ${Option[0]} (same as $Option)
      -f|--flag)        Flag=true;;          ^# Store an option representing a flag value
      -a|--arg)         Arg="$Value";;       ^# Store an option that takes an argument
      --long-flag-only) LongFlag=true;;      ^# This long flag option has no corresponding short option
      --long-arg-only)  LongArg="$Value";;   ^# This long arg option has no corresonding short option

      *)                break;;              ^# On an unrecongized arg, break out of the while loop
      esac                                   ^
   done                                      ^

   :getopts: <G>end</G> --save Remaining --append^
                                             ^# End the option parsing and save remaining args by appending
   set -- "${Remaining[@]}"                  ^# Copy remaining args back to positional parameters
EOF
}

:getopts:()
{
   if [[ ! -v __getopts______t ]]; then
      ##############################################
      # One-Time Initialization of Stack Variables #
      ##############################################
      local -ig __getopts______t=-1                                 # TOP:     Set stack top to unused (-1)
      local -ag __getopts______o=()                                 # OPTIONS: All options as encoded associative array
      local -ag __getopts______s=()                                 # SHORT:   Short options as a string
      local -ag __getopts______a=()                                 # ARGS:    Store arguments to be processed
      local -ag __getopts______i=()                                 # OPTIND:  store OPTIND index
      local -ig __getopts______r=0                                  # RETURN:  store the return status
   fi

   if [[ -z $1 ]]; then                                  # If no directive is present, then report an error
      echo ':getopts: Missing directive' >&2
      return 1
   fi

   if :test:has_func ":getopts:Directive_$1"; then            # If the directive is known,
      ":getopts:Directive_$1" "${@:2}"                        # ... then call that function with the remaining args

   else
      echo ":getopts: Unknown directive: $1" >&2         # ... otherwise, return an error
      return 1
   fi
}

:getopts:Directive_begin()
{
   local __getopts_____Directive_begin___Options                                     # Process options for this directive
   __getopts_____Directive_begin___Options=$(getopt -o 'o:l:' -l 'short-options:,long-options:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__getopts_____Directive_begin___Options"                            # Set back to positional parameters

   local __getopts_____Directive_begin___ShortRequests=                              # The short option charstring
   local __getopts_____Directive_begin___LongRequests=                               # The long option charstring
   while true; do
      case "$1" in
      -o|--short-options)  __getopts_____Directive_begin___ShortRequests="${2// }"   # Remove spaces from short options string
                           shift 2;;

      -l|--long-options)   __getopts_____Directive_begin___LongRequests="${2// }"    # Remove spaces from short options string
                           shift 2;;

      --)                  shift; break;;                # Requested early termination
      *)                   break;;
      esac
   done

   unset __getopts_____Directive_begin___AllOptions                                  # Ensure this variable is unset before using
   local -A __getopts_____Directive_begin___AllOptions                               # Key=option (short or long), Value is true if takes an arg

   #################
   # Short Options #
   #################
   local __getopts_____Directive_begin___ShortOptions=                               # Build up the short options to be saved on the stack
   local -i I

   for (( I=0; I<${#__getopts_____Directive_begin___ShortRequests}; I++ )); do
      if [[ ${__getopts_____Directive_begin___ShortRequests:I+1:1} = : ]]; then      # Determine if the short option takes an argument
         __getopts_____Directive_begin___AllOptions["${__getopts_____Directive_begin___ShortRequests:I:1}"]=true # true: option with argument
         __getopts_____Directive_begin___ShortOptions+="${__getopts_____Directive_begin___ShortRequests:I:2}"
         I=$(( I + 1 ))                                  # Move to the next argument

      else
         __getopts_____Directive_begin___AllOptions["${__getopts_____Directive_begin___ShortRequests:I:1}"]=false
                                                         # false: flag option
         __getopts_____Directive_begin___ShortOptions+="${__getopts_____Directive_begin___ShortRequests:I:1}"
      fi
   done

   ################
   # Long Options #
   ################
   local __getopts_____Directive_begin___LongOption                                  # Long option iterator

   for __getopts_____Directive_begin___LongOption in ${__getopts_____Directive_begin___LongRequests//,/ }; do    # Iterate over long options
      if [[ $__getopts_____Directive_begin___LongOption =~ : ]]; then
         __getopts_____Directive_begin___AllOptions["${__getopts_____Directive_begin___LongOption%%:}"]=true     # true: option with argument
      else
         __getopts_____Directive_begin___AllOptions["${__getopts_____Directive_begin___LongOption%%:}"]=false    # false: flag option
      fi
   done

   ##############################
   # Store items into the stack #
   ##############################
   __getopts______t=$(( __getopts______t + 1 ))                                # Push new getopts processing onto the stack

   __getopts______s[$__getopts______t]=":$__getopts_____Directive_begin___ShortOptions-:"                  # Store the short options string
                                                         # The leading : indicates silent operation
                                                         # The trailing -: is used to capture long options: --<arg>
                                                         # The first '-' indicates what follows is an option
                                                         # The second '-' is the option 'letter' and takes an <arg>
                                                         # The <arg> is the long option word.

   printf -v "__getopts______o[$__getopts______t]" '%s' "$(declare -p __getopts_____Directive_begin___AllOptions | LC_ALL=C sed 's|^[^=]*=||')"
                                                         # Store the encoded associative array that maps all options
                                                         # to a boolean: true if the option takes an arg

   local -a __getopts_____Directive_begin___Args=( "$@" )
   printf -v "__getopts______a[$__getopts______t]" '%s' "$(declare -p __getopts_____Directive_begin___Args | LC_ALL=C sed 's|^[^=]*=||')"
                                                         # Copy arguments into the stack

   __getopts______i[$__getopts______t]=1                                       # Initialize OPTIND for current stack to 1
}

:getopts:Directive_next()
{
   local __getopts_____Directive_next___OptionVar="$1"                              # Place short/long option into this variable: -s or --long
   local __getopts_____Directive_next___ValueVar="$2"                               # Place arg into this variable for options taking a value
   local __getopts_____Directive_next___StopVar="${3:-__getopts_____Directive_next___UnspecifiedStopVar}"      # Place status for Stop processing (explicit --)

   ##############################
   # Set up the Option Variable #
   ##############################
   if [[ -z $__getopts_____Directive_next___OptionVar ]]; then                      # It is an error if $__getopts_____Directive_next___OptionVar is empty
      echo ':getopts: next is missing the required variable name'
      return 1
   fi
   [[ -v $__getopts_____Directive_next___OptionVar ]] || local -g "$__getopts_____Directive_next___OptionVar"
                                                         # Declare array if it does not already exist

   #########################
   # Load state from stack #
   #########################
   if (( OPTIND != ${__getopts______i[$__getopts______t]} )); then
      OPTIND="${__getopts______i[$__getopts______t]}"                          # Load OPTIND, but only if it has changed to preserve state
   fi
   eval local -a "__getopts_____Directive_next___Args=${__getopts______a[$__getopts______t]}"
                                                         # Load positional args to process

   local __getopts_____Directive_next___ShortOptions="${__getopts______s[$__getopts______t]}"             # Load short options, including the -: handler
   unset __getopts_____Directive_next___Options
   eval local -A "__getopts_____Directive_next___Options=${__getopts______o[$__getopts______t]}"
                                                         # Load all options from the associative array

   local __getopts_____Directive_next___OptChar                                     # The single-char iterator
   local -i __getopts_____Directive_next___Status=0                                 # Assume that getopts will succeed

   ###########################
   # Call underlying getopts #
   ###########################
   getopts "$__getopts_____Directive_next___ShortOptions" __getopts_____Directive_next___OptChar "${__getopts_____Directive_next___Args[@]}" || __getopts_____Directive_next___Status=$?

   ################################
   # IMPORTANT OPTIND EXPLANATION #
   ################################
   # The getopts Bash builtin parses POSITIONAL parameters. These being with index 1, not 0.
   #
   # OPTIND is the index following the parsed argument as part of determining whether it is
   # matches option syntax -<optchar> or a non-option argument (that doesn't begin with -).
   #
   # The __getopts_____Directive_next___Args array is a copy of the positional parameters.
   # IMPORTANT: This array is 0 indexed.
   #
   # The combination of the above two facts means that OPTIND - 2 is the index into the
   # __getopts_____Directive_next___Args array of the CURRENT OPTION string being parsed.
   # So, the idiom ${__getopts_____Directive_next___Args[OPTIND-2]} and variations of it refer to the current option string.

   if (( __getopts_____Directive_next___Status != 0 )); then                        # If the argument is not an option or -- then return
      if (( OPTIND >= 2 )) && [[ -z ${__getopts_____Directive_next___Args[OPTIND-2]#--} ]]; then
                                                         # Explicit -- found?
         printf -v "$__getopts_____Directive_next___StopVar" '%s' true              # Yes: store true and return
         printf -v "__getopts______i[$__getopts______t]" '%s' "$OPTIND"        # Save the OPTIND back to the stack
      fi

      return 1
   fi
                                                         # Can fail when encountering unrecognized arg or option
   [[ -v $__getopts_____Directive_next___StopVar ]] || local -g "$__getopts_____Directive_next___StopVar"=     # Ensure the StopVar is set; presume not found
   printf -v "$__getopts_____Directive_next___StopVar" '%s' false

   [[ $__getopts_____Directive_next___OptChar != '?' ]] || return 1                 # Return on unrecognized Bash getopts option

   ### LONG OPTION HANDLING ###
   if [[ $__getopts_____Directive_next___OptChar = - ]]; then

      printf -v "$__getopts_____Directive_next___OptionVar" "%s" "${__getopts_____Directive_next___Args[OPTIND-2]}"
                                                         # Save the full option string to be used in a case statement
      if [[ ${__getopts_____Directive_next___Options[${__getopts_____Directive_next___Args[OPTIND-2]#--}]} = true ]]; then
                                                         # If this option takes an argument,
         printf -v "$__getopts_____Directive_next___ValueVar" "%s" "${__getopts_____Directive_next___Args[$OPTIND-1]}"
                                                         # ... save the value string to be used in a case statement
         OPTIND=$(( OPTIND + 1 ))                        # ... and advance over the value arg

      else
         printf -v "$__getopts_____Directive_next___ValueVar" "%s" ''               # Otherwise, store no argument as an empty string
      fi

   ### SHORT OPTION HANDLING ###
   else
      [[ -n ${__getopts_____Directive_next___Options[$__getopts_____Directive_next___OptChar]} ]] || return 1  # Return if unrecognized :getopts: short option

      printf -v "$__getopts_____Directive_next___OptionVar" "%s" "-$__getopts_____Directive_next___OptChar"    # Save the full option string to be used in a case statement

      if ${__getopts_____Directive_next___Options[$__getopts_____Directive_next___OptChar]}; then              # If this option takes an argument,
         printf -v "$__getopts_____Directive_next___ValueVar" "%s" "$OPTARG"        # ... save the value string to be used in a case statement
                                                         # It is not necessary to advance as getopts has done it
      else
         printf -v "$__getopts_____Directive_next___ValueVar" "%s" ''               # Otherwise, store no argument as an empty string
      fi
   fi

   printf -v "__getopts______i[$__getopts______t]" '%s' "$OPTIND"              # Save the OPTIND back to the stack

   return $__getopts_____Directive_next___Status                                    # Return the status indicating whether to continue or not
}

:getopts:Directive_end()
{
   local __getopts_____Directive_end___Options                                     # Process options for this directive
   __getopts_____Directive_end___Options=$(getopt -o '' -l 'save:,append' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__getopts_____Directive_end___Options"                            # Set back to positional parameters

   local __getopts_____Directive_end___SaveVar=                                    # The optional save variable for unprocessed args
   local __getopts_____Directive_end___Append=false
   while true ; do
      case "$1" in
      --save)     __getopts_____Directive_end___SaveVar="$2"; shift 2;;            # Store the save variable
      --append)   __getopts_____Directive_end___Append=true; shift;;               # Append to the SaveVar instead of overwriting
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $__getopts_____Directive_end___SaveVar ]]; then                        # Save the unprocessed options and args
      [[ -v $__getopts_____Directive_end___SaveVar ]] || local -ga "$__getopts_____Directive_end___SaveVar"
                                                         # Declare array if it does not already exist

      OPTIND="${__getopts______i[$__getopts______t]}"                          # Load OPTIND
      eval local -a "__getopts_____Directive_end___Args=${__getopts______a[$__getopts______t]}"
                                                         # Load positional args to process


      local -a __getopts_____Directive_end___Remaining=()                          # Build the remaining args array
      if $__getopts_____Directive_end___Append; then                               # If appending,
         local _getopts_Indirect="$__getopts_____Directive_end___SaveVar[@]"       # ... form the indirect reference to the existing array
         __getopts_____Directive_end___Remaining=( "${!_getopts_Indirect}" )       # ... and use it to start with the existing array elements
      fi
      __getopts_____Directive_end___Remaining+=( "${__getopts_____Directive_end___Args[@]:OPTIND-1}" )
                                                         # Slice the array, adding only the unprocessed args

      declare -ga "$__getopts_____Directive_end___SaveVar"=
      eval "$__getopts_____Directive_end___SaveVar"=$(declare -p __getopts_____Directive_end___Remaining | LC_ALL=C sed -e 's|^[^=]*=||' -e "s|^'||" -e "s|'$||")
                                                         # Write to the save var, being careful of special chars
   fi

   if (( $__getopts______t >= 0 )); then
      __getopts______t=$(( $__getopts______t - 1 ))                            # Decrease stack level
   fi
}

:getopts:%TEST()
{
   if (( $# == 0 )); then                                # Set default test case
      local __getopts_____TEST___Special='"a \ b \ c"'                    # An argument with special characters in it
      local -a __getopts_____TEST___TestArgs=(
         -f --flag -a 1 --arg "$__getopts_____TEST___Special" --long-flag-only --long-arg-only 3 -- extra here
      )

      set -- "${__getopts_____TEST___TestArgs[@]}"                        # Place the test args into the positional parameters
      local __getopts_____TEST___UsingDefaultTest=true

   else
      local __getopts_____TEST___UsingDefaultTest=false
   fi

   cat <<EOF |
<B>
   set -- ${__getopts_____TEST___TestArgs[@]}

   :getopts: begin -o 'fa:' -l 'flag,arg:,long-flag-only,long-arg-only:' -- "\$@"

   while :getopts: next (.)_Option (.)_Value; do
      case "\$(.)_Option" in
      -f|--flag)        (.)_Flag=true;;
      -a|--arg)         (.)_Arg="\$(.)_Value";;
      --long-flag-only) (.)_LongFlag=true;;
      --long-arg-only)  (.)_LongArg="\$(.)_Value";;

      *)                break;;
      esac
   done

   local -a (.)_Remaining=( 'starts' 'with' )

   :getopts: end --save (.)_Remaining --append
</B>
EOF
:highlight:

   local __getopts_____TEST___Flag=false                                  # Short flag option default value
   local __getopts_____TEST___Arg=                                        # Short arg option default value
   local __getopts_____TEST___LongFlag=false                              # Long flag option default value
   local __getopts_____TEST___LongArg=                                    # Long arg option default value

   local __getopts_____TEST___Option                                      # Iterator: option to process
   local __getopts_____TEST___Value                                       # Iterator: value to process

   :getopts: begin -o 'fa:' -l 'flag,arg:,long-flag-only,long-arg-only:' -- "$@"

   while :getopts: next __getopts_____TEST___Option __getopts_____TEST___Value; do         # Recognize args as option/value pairs until end/unknown
      case "$__getopts_____TEST___Option" in                              # \${__getopts_____TEST___Option[0]} (same as \$__getopts_____TEST___Option)
      -f|--flag)        __getopts_____TEST___Flag=true;;                  # Store an option representing a flag value
      -a|--arg)         __getopts_____TEST___Arg="$__getopts_____TEST___Value";;           # Store an option that takes an argument
      --long-flag-only) __getopts_____TEST___LongFlag=true;;              # This long flag option has no corresponding short option
      --long-arg-only)  __getopts_____TEST___LongArg="$__getopts_____TEST___Value";;       # This long arg option has no corresonding short option

      *)                break;;                          # On an unrecongized arg, break out of the while loop
      esac
   done

   local -a __getopts_____TEST___Remaining=( 'starts' 'with' )

   :getopts: end --save __getopts_____TEST___Remaining --append           # End the _getopts parsing context and save remaining args

   if $__getopts_____TEST___UsingDefaultTest; then                        # Perform asserts if running the default test
      :test:assert '[[ $__getopts_____TEST___Flag = true ]]'           '(.)_Flag = true'
      :test:assert "[[ \$__getopts_____TEST___Arg = '$__getopts_____TEST___Special' ]]" "(.)_Arg = $__getopts_____TEST___Special"
      :test:assert '[[ $__getopts_____TEST___LongFlag = true ]]'       '(.)_LongFlag = true'
      :test:assert '[[ $__getopts_____TEST___LongArg = 3 ]]'           '(.)_LongArg = 3'
      :test:assert '[[ ${__getopts_____TEST___Remaining[@]} = "starts with extra here" ]]' '(.)_Remaining = "starts with extra here'
   fi
}
