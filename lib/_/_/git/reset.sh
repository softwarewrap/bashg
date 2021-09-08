#!/bin/bash

+ reset%HELP()
{
   local (.)_Synopsis='Reset a git branch'
   local (.)_Usage='[OPTIONS] <branch>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
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

+ reset()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'n' -l 'no-clean' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Clean=true
   while true ; do
      case "$1" in
      -n|--no-clean) (.)_Clean=false; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local (.)_CurrentBranch                               # The branch to reset
   local (.)_TopDir                                      # The top directory of the git project
   local (.)_Remote                                      # The current remote
   local (.)_Branch="$1"                                 # The requested branch
   local (.)_Owner                                       # The owner of the project

   (.)_CurrentBranch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
   (.)_TopDir="$(git rev-parse --show-toplevel 2>/dev/null)"

   if [[ -z $(.)_TopDir ]]; then
      :error: 1 'Not in a git project directory'         # If not within a git project, then raise an error
      return
   fi

   (.)_Owner="$(stat -c '%U' "$(.)_TopDir")"             # The presumed owner of the git project

   if [[ -z $(.)_Owner ]]; then
      :error: 2 'Could not determine the owner of the project'
      return
   fi

   (.)_Remote="$(git remote show)"                       # Get the current git remote (commonly, origin)
   (.)_Branch="${(.)_Branch#$(.)_Remote/}"               # Ensure the specified branch doesn't begin with the remote

   if [[ -n $(.)_Branch && $(.)_Branch != $(.)_CurrentBranch ]]; then
                                                         # Is branch specified and different from the current branch?
      if git rev-parse --verify "$(.)_Remote/$(.)_Branch" >/dev/null 2>&1; then
         (.)_CurrentBranch="$(.)_Branch"                 # If a valid branch, then update the current branch
         :sudo "$(.)_Owner" git checkout "$(.)_CurrentBranch"
                                                         # ... and checkout the indicated branch to make it current

      else
         :error: 3 "No such branch: $(.)_Branch"         # Ensure the requested branch is valid: if not raise an error
         return
      fi
   fi

   :sudo "$(.)_Owner" git reset --hard "$(.)_Remote/$(.)_CurrentBranch"

   if $(.)_Clean; then
      :sudo "$(.)_Owner" git clean -f -d
   fi

   :sudo "$(.)_Owner" git pull --all
}
