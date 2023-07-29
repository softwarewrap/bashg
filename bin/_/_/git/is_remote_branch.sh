#!/bin/bash

:git:is_remote_branch%HELP()
{
   local __git__is_remote_branch__is_remote_branchHELP___Synopsis='Test if a branch exists in the remote repository'
   local __git__is_remote_branch__is_remote_branchHELP___Usage='[OPTIONS] <branch>'

   :help: --set "$__git__is_remote_branch__is_remote_branchHELP___Synopsis" --usage "$__git__is_remote_branch__is_remote_branchHELP___Usage" <<EOF
OPTIONS:
   -d|--dir <dir>          ^A directory within the git project
      The current working directory is the default if not specified.

   -r|--remote <remote>    ^The remote name [default: origin]
      The remote must exist.

DESCRIPTION:
   Test whether the specified <branch> exists both in the remote repository.

   No output is emitted.

RETURN STATUS:
   0  ^Success: branch found in the remote repository
   1  ^Invalid option detected
   2  ^The <branch> was not specified
   3  ^The <remote> is invalid: not configured
   4  ^The <remote> is invalid: connection error
   5  ^The branch was not found on the remote
   6  ^The <dir> is not within a git project
EOF
}

:git:is_remote_branch()
{
   local __git__is_remote_branch__is_remote_branch___Options
   __git__is_remote_branch__is_remote_branch___Options=$(getopt -o 'd:r:' -l 'dir:,remote:' -n "${FUNCNAME[0]}" -- "$@") || return 1
   eval set -- "$__git__is_remote_branch__is_remote_branch___Options"

   local __git__is_remote_branch__is_remote_branch___Dir="$_invocation_dir"
   local __git__is_remote_branch__is_remote_branch___Remote='origin'

   while true ; do
      case "$1" in
      -d|--dir)      __git__is_remote_branch__is_remote_branch___Dir="$2"; shift 2;;
      -r|--remote)   __git__is_remote_branch__is_remote_branch___Remote="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   :git:is_project_dir "$__git__is_remote_branch__is_remote_branch___Dir" || return 6

   # Verify branch name was provided
   local __git__is_remote_branch__is_remote_branch___Branch="$1"                                 # The <branch> is a required parameter
   [[ -n $__git__is_remote_branch__is_remote_branch___Branch ]] || return 2

   # Verify remote is defined
   if [[ -z $__git__is_remote_branch__is_remote_branch___Remote ]] || ! git -C "$__git__is_remote_branch__is_remote_branch___Dir" config remote.$__git__is_remote_branch__is_remote_branch___Remote.url &>/dev/null; then
      return 3                                           # The remote is invalid: not configured
   fi

   # Ensure remote-tracking branches are up-to-date
   git -C "$__git__is_remote_branch__is_remote_branch___Dir" fetch --all &>/dev/null

   local __git__is_remote_branch__is_remote_branch___RemoteBranch
   if ! __git__is_remote_branch__is_remote_branch___RemoteBranch="$( git -C "$__git__is_remote_branch__is_remote_branch___Dir" ls-remote --heads "$__git__is_remote_branch__is_remote_branch___Remote" "$__git__is_remote_branch__is_remote_branch___Branch" 2>/dev/null )"; then
      return 4                                           # The remote branch is invalid
   fi

   [[ -n $__git__is_remote_branch__is_remote_branch___RemoteBranch ]] || return 5                # The branch was not found on the remote
}
