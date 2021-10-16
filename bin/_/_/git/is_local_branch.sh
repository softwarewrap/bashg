#!/bin/bash

:git:is_local_branch%HELP()
{
   local __git__is_local_branch__is_local_branchHELP___Synopsis='Test if a local branch exists'
   local __git__is_local_branch__is_local_branchHELP___Usage='[OPTIONS] <branch>'

   :help: --set "$__git__is_local_branch__is_local_branchHELP___Synopsis" --usage "$__git__is_local_branch__is_local_branchHELP___Usage" <<EOF
OPTIONS:
   --checkout <remote>     ^If the branch is not local, attempt to checkout
   --force                 ^Force git project directories to be clean

DESCRIPTION:
   Test whether the specified <branch> exists in the local repository.

   If --checkout is specified and the branch is presently not local, then a checkout
   is performed only if there are no changes or untracked files pending.
   The <remote> must existand has a default of <B>origin</B>.

   No output is emitted.

RETURN STATUS:
   0  Success: branch found in the local repository
   1  Invalid option detected
   2  The <branch> was not specified
   3  Not local and --checkout not specified
   4  Cannot checkout because changes or untracked files are present
   5  The <remote> is invalid: not configured
   6  The <remote> is invalid: connection error
   7  The branch was not found on the remote
   8  The git checkout failed
EOF
}

:git:is_local_branch()
{
   local __git__is_local_branch__is_local_branch___Options
   __git__is_local_branch__is_local_branch___Options=$(getopt -o '' -l 'checkout:,force' -n "${FUNCNAME[0]}" -- "$@") || return 1
   eval set -- "$__git__is_local_branch__is_local_branch___Options"

   local __git__is_local_branch__is_local_branch___Checkout=false                              # Checkout the branch if not local?
   local __git__is_local_branch__is_local_branch___Remote=origin                               # Set when --checkout is specified
   local __git__is_local_branch__is_local_branch___Force=false                                 # Force clean directories

   while true ; do
      case "$1" in
      --checkout) __git__is_local_branch__is_local_branch___Checkout=true; __git__is_local_branch__is_local_branch___Remote="$2"; shift 2;;
      --force)    __git__is_local_branch__is_local_branch___Force=true; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   # Verify branch name was provided
   local __git__is_local_branch__is_local_branch___Branch="$1"                                 # The <branch> is a required parameter
   [[ -n $__git__is_local_branch__is_local_branch___Branch ]] || return 2

   # Verify local branch name exists
   local __git__is_local_branch__is_local_branch___LocalBranch
   __git__is_local_branch__is_local_branch___LocalBranch="$( git branch --list "$__git__is_local_branch__is_local_branch___Branch" 2>/dev/null )"

   [[ -z $__git__is_local_branch__is_local_branch___LocalBranch ]] || return 0                 # The local branch exists
   $__git__is_local_branch__is_local_branch___Checkout || return 3                             # --checkout is not specified

   local __git__is_local_branch__is_local_branch___Changes
   __git__is_local_branch__is_local_branch___Changes="$( git status --porcelain Source/content 2>/dev/null )"
   if [[ -n $__git__is_local_branch__is_local_branch___Changes ]]; then
      if $__git__is_local_branch__is_local_branch___Force; then
         git reset --hard "$__git__is_local_branch__is_local_branch___Remote/$__git__is_local_branch__is_local_branch___Branch"
         git clean -f -d
         git pull --all
      else
         return 4                                        # Changes or untracked files are present
      fi
   fi

   # Verify remote is defined
   if [[ -z $__git__is_local_branch__is_local_branch___Remote ]] || ! git config remote.$__git__is_local_branch__is_local_branch___Remote.url &>/dev/null; then
      return 5                                           # The remote is invalid: not configured
   fi

   # Ensure remote-tracking branches are up-to-date
   git fetch --all &>/dev/null

   local __git__is_local_branch__is_local_branch___RemoteBranch
   if ! __git__is_local_branch__is_local_branch___RemoteBranch="$( git ls-remote --heads "$__git__is_local_branch__is_local_branch___Remote" "$__git__is_local_branch__is_local_branch___Branch" 2>/dev/null )"; then
      return 6                                           # The remote branch is invalid: connection error
   fi

   [[ -n $__git__is_local_branch__is_local_branch___RemoteBranch ]] || return 7                # The branch was not found on the remote

   git checkout -b "$__git__is_local_branch__is_local_branch___Branch" "$__git__is_local_branch__is_local_branch___Remote/$__git__is_local_branch__is_local_branch___Branch" || return 8
                                                         # Checkout the branch and return on failure
}
