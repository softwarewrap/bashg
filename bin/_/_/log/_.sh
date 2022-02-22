#!/bin/bash

:log:%STARTUP-1()
{
   local -gi __log___Level=0                                 # Default: Log level is 0 (entry level)
   local -ga __log___Message=()                              # Default: Start with no log message stack
}

:log:()
{
   local __log________Push=false                                  # Default: not increasing the stack level
   local __log________Pop=false                                   # Default: not decreasing the stack level
   local __log________Prefix=                                     # Default: no prefix to log message

   local IFS=' '                                         # Positional args: separate with spaces

   if [[ $1 = --push-section ]]; then
      __log________Push=true
      shift

      __log___Message[$__log___Level]="$(printf '%0.s=' {1..40}) ${1^^} ${*:2}"
                                                         # Make --push-section messages standout: = line + ALL CAPS

      __log________Prefix='{ '                                    # Use { prefix when pushing the log level

   elif [[ $1 = --push ]]; then
      __log________Push=true
      shift

      __log___Message[$__log___Level]="$*"                       # Set the log message on push

      __log________Prefix='{ '                                    # Use { prefix when pushing the log level

   elif [[ $1 = --pop ]]; then                           # Do not set the log message on pop
      __log________Pop=true
      shift

      __log________Prefix='} '                                    # Use END: prefix when popping the log level

   else
      __log___Message[$__log___Level]="$*"                       # Set the log message when neither push nor pop are used
   fi

   if $__log________Pop && (( __log___Level > 0 )); then              # Do any log level decreases before outputting message
      if (( $# > 0 )); then
         :log: "$@"
      fi

      __log___Level="$(( __log___Level-1 ))"
   fi

   local __log________Date
   __log________Date="$(date +%Y-%m-%d.%H%M%S)"

   {
      if $__log________Push; then
         echo                                            # Make push/pop messages standout with blank line
      fi

      if (( __log___Level > 0 )); then
         echo -e "[$__log________Date] $(printf '#%0.s' $( seq -s ' ' 1 $__log___Level ) ) $__log________Prefix${__log___Message[$__log___Level]}"
                                                         # Add indent
      else
         echo -e "[$__log________Date] $__log________Prefix${__log___Message[$__log___Level]}"
      fi

      if $__log________Pop; then
         echo                                            # Make push/pop messages standout with blank line
      fi
   } >&2

   if $__log________Push; then                                    # Do any log level increases after outputting message
      __log___Level="$(( __log___Level+1 ))"
   fi
}

:log:%TEST()
{
   :log: --push ':log:test'

   echo 'Emit to stdout'
   echo 'Emit to stderr' >&2

   :log: --pop

   :log: --push-section 'SECTION A'
   :log: 'A'
   :log: --push-section 'SECTION B'
   :log: 'B'
   :log: --push-section 'SECTION C1'
   :log: 'C1'
   :log: --pop
   :log: --push-section 'SECTION C2'
   :log: 'C2'
   :log: --pop
   :log: --pop
   :log: --pop
}
