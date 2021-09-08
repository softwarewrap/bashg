#!/bin/bash

+ is_remote_branch%HELP()
{
   local (.)_Synopsis='Test if a branch exists in the remote repository'
   local (.)_Usage='[OPTIONS] <branch>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
OPTIONS:
   -r|--remote <remote>    ^The remote name [default: origin]

DESCRIPTION:
   Test whether the specified <branch> exists both in the remote repository.

   If --remote is specified, then the remote must exist. The default is <B>origin</B>.

   No output is emitted.

RETURN STATUS:
   0  Success: branch found in the remote repository
   1  Invalid option detected
   2  The <branch> was not specified
   3  The <remote> is invalid: not configured
   4  The <remote> is invalid: connection error
   5  The branch was not found on the remote
EOF
}

+ is_remote_branch()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'r:' -l 'remote:' -n "${FUNCNAME[0]}" -- "$@") || return 1
   eval set -- "$(.)_Options"

   local (.)_Remote='origin'
   while true ; do
      case "$1" in
      -r|--remote)   (.)_Remote="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   # Verify branch name was provided
   local (.)_Branch="$1"                                 # The <branch> is a required parameter
   [[ -n $(.)_Branch ]] || return 2

   # Verify remote is defined
   if [[ -z $(.)_Remote ]] || ! git config remote.$(.)_Remote.url &>/dev/null; then
      return 3                                           # The remote is invalid: not configured
   fi

   # Ensure remote-tracking branches are up-to-date
   git fetch --all &>/dev/null

   local (.)_RemoteBranch
   if ! (.)_RemoteBranch="$( git ls-remote --heads "$(.)_Remote" "$(.)_Branch" 2>/dev/null )"; then
      return 4                                           # The remote branch is invalid
   fi

   [[ -n $(.)_RemoteBranch ]] || return 5                # The branch was not found on the remote
}
