#!/bin/bash

:log:%STARTUP-1()
{
   local -gi ___log___Level=0                                 # Default: Log level is 0 (entry level)
   local -ga ___log___Message=()                              # Default: Start with no log message stack
}

:log:()
{
   local ___log________Push=false                                  # Default: not increasing the stack level
   local ___log________Pop=false                                   # Default: not decreasing the stack level
   local ___log________Prefix=                                     # Default: no prefix to log message

   local IFS=' '                                         # Positional args: separate with spaces

   if [[ $1 = --push-section ]]; then
      ___log________Push=true
      shift

      ___log___Message[$___log___Level]="$(printf '%0.s=' {1..40}) ${1^^} ${*:2}"
                                                         # Make --push-section messages standout: = line + ALL CAPS

      ___log________Prefix='{ '                                    # Use { prefix when pushing the log level

   elif [[ $1 = --push ]]; then
      ___log________Push=true
      shift

      ___log___Message[$___log___Level]="$*"                       # Set the log message on push

      ___log________Prefix='{ '                                    # Use { prefix when pushing the log level

   elif [[ $1 = --pop ]]; then                           # Do not set the log message on pop
      ___log________Pop=true
      shift

      ___log________Prefix='} '                                    # Use END: prefix when popping the log level

   else
      ___log___Message[$___log___Level]="$*"                       # Set the log message when neither push nor pop are used
   fi

   if $___log________Pop && (( ___log___Level > 0 )); then              # Do any log level decreases before outputting message
      if (( $# > 0 )); then
         :log: "$@"
      fi

      ___log___Level="$((___log___Level-1))"
   fi

   local ___log________Date
   ___log________Date="$(date +%Y-%m-%d.%H%M%S)"

   if $___log________Push; then
      echo                                               # Make push/pop messages standout with blank line
   fi

   if (( ___log___Level > 0 )); then
      echo -e "[$___log________Date] $(printf '#%0.s' $( seq $(( ___log___Level*2 )) ) ) $___log________Prefix${___log___Message[$___log___Level]}"
                                                         # Add indent
   else
      echo -e "[$___log________Date] $___log________Prefix${___log___Message[$___log___Level]}"
   fi

   if $___log________Pop; then
      echo                                               # Make push/pop messages standout with blank line
   fi

   if $___log________Push; then                                    # Do any log level increases after outputting message
      ___log___Level="$((___log___Level+1))"
   fi
}

:log:%TEST()
{
   :log: --push ':log:test'

   echo 'Emit to stdout'
   echo 'Emit to stderr' >&2

   :log: --pop
}
