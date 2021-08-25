#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='NOP and emit to log'
   local (.)_Usage=''

   :help: --set "$(.)_Synopsis" --usage '' <<EOF
DESCRIPTION:
   Do nothing but emit a No OP message to the log

   This function may be called when merely looking to emit a timestamped entry to the log.
EOF
}

+ ()
{
   :log: 'NOP'                                           # Provide this message to indicate a NOP was processed
}

+ silent%HELP()
{
   local (.)_Synopsis='NOP'
   local (.)_Usage=''

   :help: --set "$(.)_Synopsis" --usage '' <<EOF
DESCRIPTION:
   Do nothing at all

   This function is included for completeness: it does nothing and always returns 0.
EOF
}

+ silent()
{
   true                                                  # Emit nothing
}
