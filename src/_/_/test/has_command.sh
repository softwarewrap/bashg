#!/bin/bash

+ has_command%HELP()
{
   local (.)_Synopsis='Is true if the provided command(s) exist'
   :help: --usage '<command>...' <<EOF
DESCRIPTION:
   Return 0 if all commands provided exist; return non-zero otherwise.

EXAMPLES:
   $__ :test:has_command ls         ^Returns 0
   $__ :test:has_command ls cat     ^Returns 0 as both commands exist
   $__ :test:has_command badcmd     ^Returns 1
   $__ :test:has_command ls badcmd  ^Returns 1 as one of the commands do not exist

SCRIPTING EXAMPLE:
   if :test:has_command wget; then  ^# Determine if the wget command exists
      wget "<some-url>"^
   fi^
EOF
}

+ has_command()
{
   local (.)_Command

   for (.)_Command in "$@"; do
      if ! command -v "$(.)_Command" &>/dev/null; then
         return 1
      fi
   done

   return 0
}
