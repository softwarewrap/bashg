#!/bin/bash

+ %STARTUP-1()
{
   local -gi (+)_Level=0                                 # Default: Log level is 0 (entry level)
   local -ga (+)_Message=()                              # Default: Start with no log message stack
}

+ ()
{
   local (.)_Push=false                                  # Default: not increasing the stack level
   local (.)_Pop=false                                   # Default: not decreasing the stack level
   local (.)_Prefix=                                     # Default: no prefix to log message

   local IFS=' '                                         # Positional args: separate with spaces

   if [[ $1 = --push-section ]]; then
      (.)_Push=true
      shift

      (+)_Message[$(+)_Level]="$(printf '%0.s=' {1..40}) ${1^^} ${*:2}"
                                                         # Make --push-section messages standout: = line + ALL CAPS

      (.)_Prefix='{ '                                    # Use { prefix when pushing the log level

   elif [[ $1 = --push ]]; then
      (.)_Push=true
      shift

      (+)_Message[$(+)_Level]="$*"                       # Set the log message on push

      (.)_Prefix='{ '                                    # Use { prefix when pushing the log level

   elif [[ $1 = --pop ]]; then                           # Do not set the log message on pop
      (.)_Pop=true
      shift

      (.)_Prefix='} '                                    # Use END: prefix when popping the log level

   else
      (+)_Message[$(+)_Level]="$*"                       # Set the log message when neither push nor pop are used
   fi

   if $(.)_Pop && (( (+)_Level > 0 )); then              # Do any log level decreases before outputting message
      if (( $# > 0 )); then
         :log: "$@"
      fi

      (+)_Level="$(( (+)_Level-1 ))"
   fi

   local (.)_Date
   (.)_Date="$(date +%Y-%m-%d.%H%M%S)"

   {
      if $(.)_Push; then
         echo                                            # Make push/pop messages standout with blank line
      fi

      if (( (+)_Level > 0 )); then
         echo -e "[$(.)_Date] $(printf '#%0.s' $( seq -s ' ' 1 $(+)_Level ) ) $(.)_Prefix${(+)_Message[$(+)_Level]}"
                                                         # Add indent
      else
         echo -e "[$(.)_Date] $(.)_Prefix${(+)_Message[$(+)_Level]}"
      fi

      if $(.)_Pop; then
         echo                                            # Make push/pop messages standout with blank line
      fi
   } >&2

   if $(.)_Push; then                                    # Do any log level increases after outputting message
      (+)_Level="$(( (+)_Level+1 ))"
   fi
}

+ %TEST()
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
