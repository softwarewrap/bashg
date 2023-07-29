#!/bin/bash

+ has_stdin%HELP()
{
   local (.)_Synopsis='Test if stdin is available'

   :help: --set "$(.)_Synopsis" <<EOF
DESCRIPTION:
   Intended for scripting, this function returns true if stdin is available to read, even if empty.

RETURN STATUS:
   0  ^stdin is available to read
   1  ^stdin is not available to read
EOF
}

+ has_stdin()
{
   sleep .001
   [[ ! -t 0 ]] && read -t 0
}
