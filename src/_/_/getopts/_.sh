#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Process options with no rearrangement and partial handling'

   :help: --set "$(.)_Synopsis" --usage '<directive> [<directive-options>]' <<'EOF'
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

+ ()
{
   if [[ ! -v (-)_t ]]; then
      ##############################################
      # One-Time Initialization of Stack Variables #
      ##############################################
      local -ig (-)_t=-1                                 # TOP:     Set stack top to unused (-1)
      local -ag (-)_o=()                                 # OPTIONS: All options as encoded associative array
      local -ag (-)_s=()                                 # SHORT:   Short options as a string
      local -ag (-)_a=()                                 # ARGS:    Store arguments to be processed
      local -ag (-)_i=()                                 # OPTIND:  store OPTIND index
      local -ig (-)_r=0                                  # RETURN:  store the return status
   fi

   if [[ -z $1 ]]; then                                  # If no directive is present, then report an error
      echo ':getopts: Missing directive' >&2
      return 1
   fi

   if :test:has_func "(+):Directive_$1"; then            # If the directive is known,
      "(+):Directive_$1" "${@:2}"                        # ... then call that function with the remaining args

   else
      echo ":getopts: Unknown directive: $1" >&2         # ... otherwise, return an error
      return 1
   fi
}

+ Directive_begin()
{
   local (.)_Options                                     # Process options for this directive
   (.)_Options=$(getopt -o 'o:l:' -l 'short-options:,long-options:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"                            # Set back to positional parameters

   local (.)_ShortRequests=                              # The short option charstring
   local (.)_LongRequests=                               # The long option charstring
   while true; do
      case "$1" in
      -o|--short-options)  (.)_ShortRequests="${2// }"   # Remove spaces from short options string
                           shift 2;;

      -l|--long-options)   (.)_LongRequests="${2// }"    # Remove spaces from short options string
                           shift 2;;

      --)                  shift; break;;                # Requested early termination
      *)                   break;;
      esac
   done

   unset (.)_AllOptions                                  # Ensure this variable is unset before using
   local -A (.)_AllOptions                               # Key=option (short or long), Value is true if takes an arg

   #################
   # Short Options #
   #################
   local (.)_ShortOptions=                               # Build up the short options to be saved on the stack
   local -i I

   for (( I=0; I<${#(.)_ShortRequests}; I++ )); do
      if [[ ${(.)_ShortRequests:I+1:1} = : ]]; then      # Determine if the short option takes an argument
         (.)_AllOptions["${(.)_ShortRequests:I:1}"]=true # true: option with argument
         (.)_ShortOptions+="${(.)_ShortRequests:I:2}"
         I=$(( I + 1 ))                                  # Move to the next argument

      else
         (.)_AllOptions["${(.)_ShortRequests:I:1}"]=false
                                                         # false: flag option
         (.)_ShortOptions+="${(.)_ShortRequests:I:1}"
      fi
   done

   ################
   # Long Options #
   ################
   local (.)_LongOption                                  # Long option iterator

   for (.)_LongOption in ${(.)_LongRequests//,/ }; do    # Iterate over long options
      if [[ $(.)_LongOption =~ : ]]; then
         (.)_AllOptions["${(.)_LongOption%%:}"]=true     # true: option with argument
      else
         (.)_AllOptions["${(.)_LongOption%%:}"]=false    # false: flag option
      fi
   done

   ##############################
   # Store items into the stack #
   ##############################
   (-)_t=$(( (-)_t + 1 ))                                # Push new getopts processing onto the stack

   (-)_s[$(-)_t]=":$(.)_ShortOptions-:"                  # Store the short options string
                                                         # The leading : indicates silent operation
                                                         # The trailing -: is used to capture long options: --<arg>
                                                         # The first '-' indicates what follows is an option
                                                         # The second '-' is the option 'letter' and takes an <arg>
                                                         # The <arg> is the long option word.

   printf -v "(-)_o[$(-)_t]" '%s' "$(declare -p (.)_AllOptions | LC_ALL=C sed 's|^[^=]*=||')"
                                                         # Store the encoded associative array that maps all options
                                                         # to a boolean: true if the option takes an arg

   local -a (.)_Args=( "$@" )
   printf -v "(-)_a[$(-)_t]" '%s' "$(declare -p (.)_Args | LC_ALL=C sed 's|^[^=]*=||')"
                                                         # Copy arguments into the stack

   (-)_i[$(-)_t]=1                                       # Initialize OPTIND for current stack to 1
}

+ Directive_next()
{
   local (.)_OptionVar="$1"                              # Place short/long option into this variable: -s or --long
   local (.)_ValueVar="$2"                               # Place arg into this variable for options taking a value
   local (.)_StopVar="${3:-(.)_UnspecifiedStopVar}"      # Place status for Stop processing (explicit --)

   ##############################
   # Set up the Option Variable #
   ##############################
   if [[ -z $(.)_OptionVar ]]; then                      # It is an error if $(.)_OptionVar is empty
      echo ':getopts: next is missing the required variable name'
      return 1
   fi
   [[ -v $(.)_OptionVar ]] || local -g "$(.)_OptionVar"
                                                         # Declare array if it does not already exist

   #########################
   # Load state from stack #
   #########################
   if (( OPTIND != ${(-)_i[$(-)_t]} )); then
      OPTIND="${(-)_i[$(-)_t]}"                          # Load OPTIND, but only if it has changed to preserve state
   fi
   eval local -a "(.)_Args=${(-)_a[$(-)_t]}"
                                                         # Load positional args to process

   local (.)_ShortOptions="${(-)_s[$(-)_t]}"             # Load short options, including the -: handler
   unset (.)_Options
   eval local -A "(.)_Options=${(-)_o[$(-)_t]}"
                                                         # Load all options from the associative array

   local (.)_OptChar                                     # The single-char iterator
   local -i (.)_Status=0                                 # Assume that getopts will succeed

   ###########################
   # Call underlying getopts #
   ###########################
   getopts "$(.)_ShortOptions" (.)_OptChar "${(.)_Args[@]}" || (.)_Status=$?

   ################################
   # IMPORTANT OPTIND EXPLANATION #
   ################################
   # The getopts Bash builtin parses POSITIONAL parameters. These being with index 1, not 0.
   #
   # OPTIND is the index following the parsed argument as part of determining whether it is
   # matches option syntax -<optchar> or a non-option argument (that doesn't begin with -).
   #
   # The (.)_Args array is a copy of the positional parameters.
   # IMPORTANT: This array is 0 indexed.
   #
   # The combination of the above two facts means that OPTIND - 2 is the index into the
   # (.)_Args array of the CURRENT OPTION string being parsed.
   # So, the idiom ${(.)_Args[OPTIND-2]} and variations of it refer to the current option string.

   if (( (.)_Status != 0 )); then                        # If the argument is not an option or -- then return
      if (( OPTIND >= 2 )) && [[ -z ${(.)_Args[OPTIND-2]#--} ]]; then
                                                         # Explicit -- found?
         printf -v "$(.)_StopVar" '%s' true              # Yes: store true and return
         printf -v "(-)_i[$(-)_t]" '%s' "$OPTIND"        # Save the OPTIND back to the stack
      fi

      return 1
   fi
                                                         # Can fail when encountering unrecognized arg or option
   [[ -v $(.)_StopVar ]] || local -g "$(.)_StopVar"=     # Ensure the StopVar is set; presume not found
   printf -v "$(.)_StopVar" '%s' false

   [[ $(.)_OptChar != '?' ]] || return 1                 # Return on unrecognized Bash getopts option

   ### LONG OPTION HANDLING ###
   if [[ $(.)_OptChar = - ]]; then

      printf -v "$(.)_OptionVar" "%s" "${(.)_Args[OPTIND-2]}"
                                                         # Save the full option string to be used in a case statement
      if [[ ${(.)_Options[${(.)_Args[OPTIND-2]#--}]} = true ]]; then
                                                         # If this option takes an argument,
         printf -v "$(.)_ValueVar" "%s" "${(.)_Args[$OPTIND-1]}"
                                                         # ... save the value string to be used in a case statement
         OPTIND=$(( OPTIND + 1 ))                        # ... and advance over the value arg

      else
         printf -v "$(.)_ValueVar" "%s" ''               # Otherwise, store no argument as an empty string
      fi

   ### SHORT OPTION HANDLING ###
   else
      [[ -n ${(.)_Options[$(.)_OptChar]} ]] || return 1  # Return if unrecognized :getopts: short option

      printf -v "$(.)_OptionVar" "%s" "-$(.)_OptChar"    # Save the full option string to be used in a case statement

      if ${(.)_Options[$(.)_OptChar]}; then              # If this option takes an argument,
         printf -v "$(.)_ValueVar" "%s" "$OPTARG"        # ... save the value string to be used in a case statement
                                                         # It is not necessary to advance as getopts has done it
      else
         printf -v "$(.)_ValueVar" "%s" ''               # Otherwise, store no argument as an empty string
      fi
   fi

   printf -v "(-)_i[$(-)_t]" '%s' "$OPTIND"              # Save the OPTIND back to the stack

   return $(.)_Status                                    # Return the status indicating whether to continue or not
}

+ Directive_end()
{
   local (.)_Options                                     # Process options for this directive
   (.)_Options=$(getopt -o '' -l 'save:,append' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"                            # Set back to positional parameters

   local (.)_SaveVar=                                    # The optional save variable for unprocessed args
   local (.)_Append=false
   while true ; do
      case "$1" in
      --save)     (.)_SaveVar="$2"; shift 2;;            # Store the save variable
      --append)   (.)_Append=true; shift;;               # Append to the SaveVar instead of overwriting
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $(.)_SaveVar ]]; then                        # Save the unprocessed options and args
      [[ -v $(.)_SaveVar ]] || local -ga "$(.)_SaveVar"
                                                         # Declare array if it does not already exist

      OPTIND="${(-)_i[$(-)_t]}"                          # Load OPTIND
      eval local -a "(.)_Args=${(-)_a[$(-)_t]}"
                                                         # Load positional args to process


      local -a (.)_Remaining=()                          # Build the remaining args array
      if $(.)_Append; then                               # If appending,
         local _getopts_Indirect="$(.)_SaveVar[@]"       # ... form the indirect reference to the existing array
         (.)_Remaining=( "${!_getopts_Indirect}" )       # ... and use it to start with the existing array elements
      fi
      (.)_Remaining+=( "${(.)_Args[@]:OPTIND-1}" )
                                                         # Slice the array, adding only the unprocessed args

      eval "declare -g $(.)_SaveVar=$(declare -p (.)_Remaining | LC_ALL=C sed 's|^[^=]*=||')"
                                                         # Write to the save var, being careful of special chars
   fi

   if (( $(-)_t >= 0 )); then
      (-)_t=$(( $(-)_t - 1 ))                            # Decrease stack level
   fi
}

+ %TEST()
{
   if (( $# == 0 )); then                                # Set default test case
      local (.)_Special='"a \ b \ c"'                    # An argument with special characters in it
      local -a (.)_TestArgs=(
         -f --flag -a 1 --arg "$(.)_Special" --long-flag-only --long-arg-only 3 -- extra here
      )

      set -- "${(.)_TestArgs[@]}"                        # Place the test args into the positional parameters
      local (.)_UsingDefaultTest=true

   else
      local (.)_UsingDefaultTest=false
   fi

   cat <<EOF |
<B>
   set -- ${(.)_TestArgs[@]}

   :getopts: begin -o 'fa:' -l 'flag,arg:,long-flag-only,long-arg-only:' -- "\$@"

   while :getopts: next \(.)_Option \(.)_Value; do
      case "\$\(.)_Option" in
      -f|--flag)        \(.)_Flag=true;;
      -a|--arg)         \(.)_Arg="\$\(.)_Value";;
      --long-flag-only) \(.)_LongFlag=true;;
      --long-arg-only)  \(.)_LongArg="\$\(.)_Value";;

      *)                break;;
      esac
   done

   local -a \(.)_Remaining=( 'starts' 'with' )

   :getopts: end --save \(.)_Remaining --append
</B>
EOF
:highlight:

   local (.)_Flag=false                                  # Short flag option default value
   local (.)_Arg=                                        # Short arg option default value
   local (.)_LongFlag=false                              # Long flag option default value
   local (.)_LongArg=                                    # Long arg option default value

   local (.)_Option                                      # Iterator: option to process
   local (.)_Value                                       # Iterator: value to process

   :getopts: begin -o 'fa:' -l 'flag,arg:,long-flag-only,long-arg-only:' -- "$@"

   while :getopts: next (.)_Option (.)_Value; do         # Recognize args as option/value pairs until end/unknown
      case "$(.)_Option" in                              # \${(.)_Option[0]} (same as \$(.)_Option)
      -f|--flag)        (.)_Flag=true;;                  # Store an option representing a flag value
      -a|--arg)         (.)_Arg="$(.)_Value";;           # Store an option that takes an argument
      --long-flag-only) (.)_LongFlag=true;;              # This long flag option has no corresponding short option
      --long-arg-only)  (.)_LongArg="$(.)_Value";;       # This long arg option has no corresonding short option

      *)                break;;                          # On an unrecongized arg, break out of the while loop
      esac
   done

   local -a (.)_Remaining=( 'starts' 'with' )

   :getopts: end --save (.)_Remaining --append           # End the _getopts parsing context and save remaining args

   if $(.)_UsingDefaultTest; then                        # Perform asserts if running the default test
      :test:assert '[[ $(.)_Flag = true ]]'           '\(.)_Flag = true'
      :test:assert "[[ \$(.)_Arg = '$(.)_Special' ]]" "\(.)_Arg = $(.)_Special"
      :test:assert '[[ $(.)_LongFlag = true ]]'       '\(.)_LongFlag = true'
      :test:assert '[[ $(.)_LongArg = 3 ]]'           '\(.)_LongArg = 3'
      :test:assert '[[ ${(.)_Remaining[@]} = "starts with extra here" ]]' '\(.)_Remaining = "starts with extra here'
   fi
}
