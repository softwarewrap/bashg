#!/bin/bash

:git:is_remote_branch%HELP()
{
   local ___git__is_remote_branch__is_remote_branchHELP___Synopsis='Test if a branch exists in the remote repository'
   local ___git__is_remote_branch__is_remote_branchHELP___Usage='[OPTIONS] <branch>'

   :help: --set "$___git__is_remote_branch__is_remote_branchHELP___Synopsis" --usage "$___git__is_remote_branch__is_remote_branchHELP___Usage" <<EOF
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

:git:is_remote_branch()
{
   local ___git__is_remote_branch__is_remote_branch___Options
   ___git__is_remote_branch__is_remote_branch___Options=$(getopt -o 'r:' -l 'remote:' -n "${FUNCNAME[0]}" -- "$@") || return 1
   eval set -- "$___git__is_remote_branch__is_remote_branch___Options"

   local ___git__is_remote_branch__is_remote_branch___Remote='origin'
   while true ; do
      case "$1" in
      -r|--remote)   ___git__is_remote_branch__is_remote_branch___Remote="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   # Verify branch name was provided
   local ___git__is_remote_branch__is_remote_branch___Branch="$1"                                 # The <branch> is a required parameter
   [[ -n $___git__is_remote_branch__is_remote_branch___Branch ]] || return 2

   # Verify remote is defined
   if [[ -z $___git__is_remote_branch__is_remote_branch___Remote ]] || ! git config remote.$___git__is_remote_branch__is_remote_branch___Remote.url &>/dev/null; then
      return 3                                           # The remote is invalid: not configured
   fi

   # Ensure remote-tracking branches are up-to-date
   git fetch --all &>/dev/null

   local ___git__is_remote_branch__is_remote_branch___RemoteBranch
   if ! ___git__is_remote_branch__is_remote_branch___RemoteBranch="$( git ls-remote --heads "$___git__is_remote_branch__is_remote_branch___Remote" "$___git__is_remote_branch__is_remote_branch___Branch" 2>/dev/null )"; then
      return 4                                           # The remote branch is invalid
   fi

   [[ -n $___git__is_remote_branch__is_remote_branch___RemoteBranch ]] || return 5                # The branch was not found on the remote
}
