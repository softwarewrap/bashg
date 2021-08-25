#!/bin/bash

:run_as%HELP()
{
   local _____run_as__run_asHELP___Synopsis='Run command as user'
   local _____run_as__run_asHELP___Usage='<user> <command> <args>'

   :help: --set "$_____run_as__run_asHELP___Synopsis" --usage "$_____run_as__run_asHELP___Usage" <<EOF
DESCRIPTION:
   Run a command as a specified user

   The first argument is taken to be the user that is used to run a command.
   The remaining arguments are the command and options to that command.

   Note: The command can be an internal function call or an external program call.
EOF
}

:run_as()
{
   :sudo "$1" || :reenter                                # This function must run as the specified user

   shift

   "$@"
}
