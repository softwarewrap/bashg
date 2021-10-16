#!/bin/bash

:git:reset%HELP()
{
   local __git__reset__resetHELP___Synopsis='Reset a git branch'
   local __git__reset__resetHELP___Usage='[OPTIONS] <branch>'

   :help: --set "$__git__reset__resetHELP___Synopsis" --usage "$__git__reset__resetHELP___Usage" <<EOF
OPTIONS:
   -n|--no-clean     ^Do not remove untracked files and directories

DESCRIPTION:
   Perform a hard reset of the current or indicated <branch>.

   If --no-clean is specified, then the <b>git clean -f -d</b> command is not issued.

   If <branch> is specified, then the current branch is not used and the reset operation
   applies to the indicated branch.

RETURN STATUS:
   0  ^Success
   1  ^Not in a git project directory
   2  ^Could not determine the owner of the git project
   3  ^The specified branch is not valid
EOF
}

:git:reset()
{
   local __git__reset__reset___Options
   __git__reset__reset___Options=$(getopt -o 'n' -l 'no-clean' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__git__reset__reset___Options"

   local __git__reset__reset___Clean=true
   while true ; do
      case "$1" in
      -n|--no-clean) __git__reset__reset___Clean=false; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local __git__reset__reset___CurrentBranch                               # The branch to reset
   local __git__reset__reset___TopDir                                      # The top directory of the git project
   local __git__reset__reset___Remote                                      # The current remote
   local __git__reset__reset___Branch="$1"                                 # The requested branch
   local __git__reset__reset___Owner                                       # The owner of the project

   __git__reset__reset___CurrentBranch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
   __git__reset__reset___TopDir="$(git rev-parse --show-toplevel 2>/dev/null)"

   if [[ -z $__git__reset__reset___TopDir ]]; then
      :error: 1 'Not in a git project directory'         # If not within a git project, then raise an error
      return
   fi

   __git__reset__reset___Owner="$(stat -c '%U' "$__git__reset__reset___TopDir")"             # The presumed owner of the git project

   if [[ -z $__git__reset__reset___Owner ]]; then
      :error: 2 'Could not determine the owner of the project'
      return
   fi

   __git__reset__reset___Remote="$(git remote show)"                       # Get the current git remote (commonly, origin)
   __git__reset__reset___Branch="${__git__reset__reset___Branch#$__git__reset__reset___Remote/}"               # Ensure the specified branch doesn't begin with the remote

   if [[ -n $__git__reset__reset___Branch && $__git__reset__reset___Branch != $__git__reset__reset___CurrentBranch ]]; then
                                                         # Is branch specified and different from the current branch?
      if git rev-parse --verify "$__git__reset__reset___Remote/$__git__reset__reset___Branch" >/dev/null 2>&1; then
         __git__reset__reset___CurrentBranch="$__git__reset__reset___Branch"                 # If a valid branch, then update the current branch
         :sudo "$__git__reset__reset___Owner" git checkout "$__git__reset__reset___CurrentBranch"
                                                         # ... and checkout the indicated branch to make it current

      else
         :error: 3 "No such branch: $__git__reset__reset___Branch"         # Ensure the requested branch is valid: if not raise an error
         return
      fi
   fi

   :sudo "$__git__reset__reset___Owner" git reset --hard "$__git__reset__reset___Remote/$__git__reset__reset___CurrentBranch"

   if $__git__reset__reset___Clean; then
      :sudo "$__git__reset__reset___Owner" git clean -f -d
   fi

   :sudo "$__git__reset__reset___Owner" git pull --all
}
