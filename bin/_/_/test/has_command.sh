#!/bin/bash

:test:has_command%HELP()
{
   local __test__has_command__has_commandHELP___Synopsis='Is true if the provided command(s) exist'
   :help: --usage '<OPTIONS> <command>...' <<EOF
DESCRIPTION:
   Return 0 if all commands provided exist; return non-zero otherwise.

OPTIONS:
   --var <path-var>^
         Add command/path key-value pairs to the named associative array.
         If the associative array variable is not set, then it is declared with global scope

   --reset
         Reset the named associative array variable, if specified, before processing all <command> requests.

   --help^
         Show help.

EXAMPLES:
   $__ :test:has_command ls         ^Returns 0
   $__ :test:has_command ls cat     ^Returns 0 as both commands exist
   $__ :test:has_command badcmd     ^Returns 1
   $__ :test:has_command ls badcmd  ^Returns 1 as one of the commands do not exist

SCRIPTING EXAMPLE:
   if :test:has_command --var (.)_Path wget; then    ^# Determine if the wget command exists
      "\${(.)_Path[wget]}" "<some-url>"^
   fi^
EOF
}

:test:has_command()
{
   local __test__has_command__has_command___Command
   local __test__has_command__has_command___Path=

   local __test__has_command__has_command___Options
   __test__has_command__has_command___Options=$(getopt -o '' -l 'var:' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$__test__has_command__has_command___Options"

   local __test__has_command__has_command___Var=__test__has_command__has_command___UnspecifiedVar                      # The variable to store the path of the last command requested
   local __test__has_command__has_command___UnspecifiedVar=                             # The default location to store results
   local __test__has_command__has_command___Reset=false

   while true ; do
      case "$1" in
      --var)      __test__has_command__has_command___Var="$2"; shift 2;;
      --reset)    __test__has_command__has_command___Reset=true; shift;;

      --help)     $FUNCNAME%HELP; return 0;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   # If storage is requested, then ensure the associative array variable exists. Reset if requested.
   if [[ -n $__test__has_command__has_command___Var ]]; then
      ! $__test__has_command__has_command___Reset || unset "$__test__has_command__has_command___Var"

      [[ -v $__test__has_command__has_command___Var[@] ]] || local -Ag "$__test__has_command__has_command___Var"
   fi

   for __test__has_command__has_command___Command in "$@"; do
      if ! command -v "$__test__has_command__has_command___Command" &>/dev/null; then
         return 1
      fi
   done

   return 0
}
