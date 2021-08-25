#!/bin/bash

:nop:%HELP()
{
   local ___nop_____HELP___Synopsis='NOP and emit to log'
   local ___nop_____HELP___Usage=''

   :help: --set "$___nop_____HELP___Synopsis" --usage '' <<EOF
DESCRIPTION:
   Do nothing but emit a No OP message to the log

   This function may be called when merely looking to emit a timestamped entry to the log.
EOF
}

:nop:()
{
   :log: 'NOP'                                           # Provide this message to indicate a NOP was processed
}

:nop:silent%HELP()
{
   local ___nop_____silentHELP___Synopsis='NOP'
   local ___nop_____silentHELP___Usage=''

   :help: --set "$___nop_____silentHELP___Synopsis" --usage '' <<EOF
DESCRIPTION:
   Do nothing at all

   This function is included for completeness: it does nothing and always returns 0.
EOF
}

:nop:silent()
{
   true                                                  # Emit nothing
}
