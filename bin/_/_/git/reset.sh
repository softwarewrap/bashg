#!/bin/bash

:git:reset%HELP()
{
   local ___git__reset__resetHELP___Synopsis='Reset a git branch'
   local ___git__reset__resetHELP___Usage='[OPTIONS] <branch>'

   :help: --set "$___git__reset__resetHELP___Synopsis" --usage "$___git__reset__resetHELP___Usage" <<EOF
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
   local ___git__reset__reset___Options
   ___git__reset__reset___Options=$(getopt -o 'n' -l 'no-clean' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___git__reset__reset___Options"

   local ___git__reset__reset___Clean=true
   while true ; do
      case "$1" in
      -n|--no-clean) ___git__reset__reset___Clean=false; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local ___git__reset__reset___CurrentBranch                               # The branch to reset
   local ___git__reset__reset___TopDir                                      # The top directory of the git project
   local ___git__reset__reset___Remote                                      # The current remote
   local ___git__reset__reset___Branch="$1"                                 # The requested branch
   local ___git__reset__reset___Owner                                       # The owner of the project

   ___git__reset__reset___CurrentBranch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
   ___git__reset__reset___TopDir="$(git rev-parse --show-toplevel 2>/dev/null)"

   if [[ -z $___git__reset__reset___TopDir ]]; then
      :error: 1 'Not in a git project directory'         # If not within a git project, then raise an error
      return
   fi

   ___git__reset__reset___Owner="$(stat -c '%U' "$___git__reset__reset___TopDir")"             # The presumed owner of the git project

   if [[ -z $___git__reset__reset___Owner ]]; then
      :error: 2 'Could not determine the owner of the project'
      return
   fi

   ___git__reset__reset___Remote="$(git remote show)"                       # Get the current git remote (commonly, origin)
   ___git__reset__reset___Branch="${___git__reset__reset___Branch#$___git__reset__reset___Remote/}"               # Ensure the specified branch doesn't begin with the remote

   if [[ -n $___git__reset__reset___Branch && $___git__reset__reset___Branch != $___git__reset__reset___CurrentBranch ]]; then
                                                         # Is branch specified and different from the current branch?
      if git rev-parse --verify "$___git__reset__reset___Remote/$___git__reset__reset___Branch" >/dev/null 2>&1; then
         ___git__reset__reset___CurrentBranch="$___git__reset__reset___Branch"                 # If a valid branch, then update the current branch
         :sudo "$___git__reset__reset___Owner" git checkout "$___git__reset__reset___CurrentBranch"
                                                         # ... and checkout the indicated branch to make it current

      else
         :error: 3 "No such branch: $___git__reset__reset___Branch"         # Ensure the requested branch is valid: if not raise an error
         return
      fi
   fi

   :sudo "$___git__reset__reset___Owner" git reset --hard "$___git__reset__reset___Remote/$___git__reset__reset___CurrentBranch"

   if $___git__reset__reset___Clean; then
      :sudo "$___git__reset__reset___Owner" git clean -f -d
   fi

   :sudo "$___git__reset__reset___Owner" git pull --all
}
