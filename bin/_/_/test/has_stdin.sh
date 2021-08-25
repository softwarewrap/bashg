#!/bin/bash

:test:has_stdin%HELP()
{
   local ___test__has_stdin__has_stdinHELP___Synopsis='Test if stdin is available'

   :help: --set "$___test__has_stdin__has_stdinHELP___Synopsis" <<EOF
DESCRIPTION:
   Intended for scripting, this function returns true if stdin is available to read, even if empty.

RETURN STATUS:
   0  ^stdin is available to read
   1  ^stdin is not available to read
EOF
}

:test:has_stdin()
{
   sleep .001
   [[ ! -t 0 ]] && read -t 0
}
