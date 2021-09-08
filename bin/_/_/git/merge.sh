#!/bin/bash

:git:merge%HELP()
{
   local ___git__merge__mergeHELP___Synopsis='Merge from one git branch to another'
   local ___git__merge__mergeHELP___Usage='[OPTIONS] [<from-branch>] <to-branch>'

   :help: --set "$___git__merge__mergeHELP___Synopsis" --usage "$___git__merge__mergeHELP___Usage" <<EOF
OPTIONS:
   -d|--dir <path>      ^Perform the operation in the directory <path>
   -u|--user <name>     ^Perform the merge as the user <name>
   -r|--remote <remote> ^Push the merge result to <remote> [default: origin]
   -f|--force           ^Force git project directories to be clean
   -n|--no-push         ^Do all steps except for the final <b>git push</b>

DESCRIPTION:
   Merge files from one git branch to another git branch

   If --dir is specified, then <path> can be any directory within
   a git project; otherwise, the current directory is taken to be the path.

   If the <from-branch> is omitted, then the current branch is presumed.
   The <to-branch> is required.

   If --user is specified, then the merge is performed as that user;
   otherwise, the user to perform the merge is taken to be the owner of
   the git project top-level directory.

   If --remote is specified, then the git push is made to the <remote>;
   otherwise, <B>origin</B> is taken to be the remote name.

   If --force is specified, then the git directory is cleaned of any
   changes, including untracked files. If this option is not specified,
   it is an error if the git directory contains any changes, including
   untracked files.

   If --no-push is specified, then all steps except for the final <b>git push</b>
   are performed. This is intended to allow a manual inspection opportunity
   prior to pushing to the remote.

   On a successful merge, the branch is set to branch before merging.
   On a failed merge, the branch is left as the <to-branch>.

RETURN STATUS:
   0  Success
   1  Error
   2  Cannot change directory to <path>
   3  Not a git directory: <path>
   4  No such user: <name>
   5  Invalid number of arguments
   6  Invalid remote: <remote>
   7  Invalid branch: <branch>
   8  Changes or untracked files prevent merging
   9  Merge conflicts prevent merging

EXAMPLES:
   Example here               ^: comment here
EOF
}

:git:merge()
{
   local -Ag ___git__merge___MergeInfo                               # Store data to be persisted in this variable
   :launcher:persist ___git__merge___MergeInfo                   # Indicate this is to be a persisted variable

   :git:merge:ProcessOptionsAndValidate "$@"                    # Gather information and store in MergeInfo
   :git:merge:PerformMerge "${___git__merge___MergeInfo[User]}"             # Ensure the branches are ready for merging
}

:git:merge:ProcessOptionsAndValidate()
{
   local ___git__merge__ProcessOptionsAndValidate___Options
   ___git__merge__ProcessOptionsAndValidate___Options=$(getopt -o 'd:u:r:fn' -l 'dir:,user:,remote:,force,no-push' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___git__merge__ProcessOptionsAndValidate___Options"

   ########################################
   # Variables Available after Processing #
   ########################################
   ___git__merge___MergeInfo[FromBranch]=                            # The branch from which to merge
   ___git__merge___MergeInfo[ToBranch]=                              # The branch into which to merge
   ___git__merge___MergeInfo[TopDir]=                                # The top directory of the git project
   ___git__merge___MergeInfo[CurrentBranch]=                         # The current branch before processing

   ### User-specified options or defaults
   ___git__merge___MergeInfo[Path]=                                  # A directory within the git project
   ___git__merge___MergeInfo[User]=                                  # The user to perform git operations as
   ___git__merge___MergeInfo[Remote]=origin                          # The remote which to push
   ___git__merge___MergeInfo[Force]=false                            # Force branch cleanup?
   ___git__merge___MergeInfo[Push]=true                              # Perform the push step?

   while true ; do
      case "$1" in
      -d|--dir)      ___git__merge___MergeInfo[Path]="$2"; shift 2;;
      -u|--user)     ___git__merge___MergeInfo[User]="$2"; shift 2;;
      -r|--remote)   ___git__merge___MergeInfo[Remote]="$2"; shift 2;;
      -f|--force)    ___git__merge___MergeInfo[Force]=true; shift;;
      -n|--no-push)  ___git__merge___MergeInfo[Push]=false; shift;;

      --)            shift; break;;
      *)             break;;
      esac
   done


   ##############
   # VALIDATION #
   ##############
   # --dir <path>
   if [[ -n ${___git__merge___MergeInfo[Path]} ]]; then
      if ! cd "${___git__merge___MergeInfo[Path]}"; then
         :error: 2 "Cannot change directory to ${___git__merge___MergeInfo[Path]}"
         return
      fi
   else
      ___git__merge___MergeInfo[Path]="$( pwd )"
   fi

   # Verify <path> is within a git project
   if ! ___git__merge___MergeInfo[TopDir]="$( git rev-parse --show-toplevel 2>/dev/null )"; then
      :error: 3 "Not a git directory: ${___git__merge___MergeInfo[Path]}"
      return
   fi

   # --user <name>
   if [[ -n ${___git__merge___MergeInfo[User]} ]]; then
      if ! :test:has_user "${___git__merge___MergeInfo[User]}"; then # Ensure the specified user exists
         :error: 4 "No such user: ${___git__merge___MergeInfo[User]}"
         return
      fi
   else
      ___git__merge___MergeInfo[User]="$(stat -c '%U' "${___git__merge___MergeInfo[TopDir]}")"
                                                         # Use the owner of the git top-level dir by default
   fi

   ___git__merge___MergeInfo[CurrentBranch]="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

   # 1 or 2 arguments are required and specify the branch names
   if (( $# == 1 )); then                                # The current branch is the <from-branch>
      ___git__merge___MergeInfo[FromBranch]="${___git__merge___MergeInfo[CurrentBranch]}"
      ___git__merge___MergeInfo[ToBranch]="$1"

   elif (( $# != 2 )); then                              # 0 or >2 arguments is not allowed
      :error: 5 'Invalid number of arguments'
      return

   else
      ___git__merge___MergeInfo[FromBranch]="$1"
      ___git__merge___MergeInfo[ToBranch]="$2"
   fi

   # --remote <remote>
   if ! git config remote.${___git__merge___MergeInfo[Remote]}.url &>/dev/null; then
      :error: 6 "Invalid remote: ${___git__merge___MergeInfo[Remote]}"
      return
   fi
}

:git:merge:PerformMerge()
{
   :test:has_user "${___git__merge___MergeInfo[User]}" || return 1   # A valid user must be specified

   :sudo "${___git__merge___MergeInfo[User]}" || :reenter            # This function must run as root

   cd "${___git__merge___MergeInfo[TopDir]}"                         # Run within the git project

   # Check branches for changes
   :git:merge:CheckOrCleanBranch "${___git__merge___MergeInfo[CurrentBranch]}" || return
   :git:merge:CheckOrCleanBranch "${___git__merge___MergeInfo[FromBranch]}" || return
   :git:merge:CheckOrCleanBranch "${___git__merge___MergeInfo[ToBranch]}" || return

   git merge --no-ff -m "Merge ${___git__merge___MergeInfo[FromBranch]} into ${___git__merge___MergeInfo[ToBranch]}" "${___git__merge___MergeInfo[FromBranch]}"
                                                         # Merge into the ToBranch (current) from the FromBranch

   local ___git__merge__PerformMerge___Changes                                     # Used for identifying pending changes
   ___git__merge__PerformMerge___Changes="$( git status --porcelain Source/content 2>/dev/null )"

   if [[ -z $___git__merge__PerformMerge___Changes && -z $( git ls-files -u ) ]]; then
      echo 'No changes to merge'
      git checkout "${___git__merge___MergeInfo[CurrentBranch]}"     # Return to the original branch
      return 0
   fi

   git commit --amend --no-edit                          # Ensure Change-Id is in the commit

   if [[ -n $( git ls-files -u ) ]]; then
      :error: 9 "Merge conflicts in ${___git__merge___MergeInfo[TopDir]} prevent merging from ${___git__merge___MergeInfo[FromBranch]} into ${___git__merge___MergeInfo[ToBranch]}"
      return
   fi

   if ${___git__merge___MergeInfo[Push]}; then
      git push "${___git__merge___MergeInfo[Remote]}"                # Push the merge to the remote
   else
      echo 'Not pushing changes'
      return 0
   fi

   local ___git__merge__PerformMerge___CurrentBranch
   ___git__merge__PerformMerge___CurrentBranch="$( git rev-parse --abbrev-ref HEAD 2>/dev/null )"

   if [[ $___git__merge__PerformMerge___CurrentBranch != ${___git__merge___MergeInfo[CurrentBranch]} ]]; then
      git checkout "${___git__merge___MergeInfo[CurrentBranch]}"
   fi
}

:git:merge:CheckOrCleanBranch()
{
   local ___git__merge__CheckOrCleanBranch___Branch="$1"

   local ___git__merge__CheckOrCleanBranch___CurrentBranch
   ___git__merge__CheckOrCleanBranch___CurrentBranch="$( git rev-parse --abbrev-ref HEAD 2>/dev/null )"

   if [[ $___git__merge__CheckOrCleanBranch___CurrentBranch != $___git__merge__CheckOrCleanBranch___Branch ]]; then
      if ${___git__merge___MergeInfo[Force]}; then
         :git:is_local_branch --checkout "${___git__merge___MergeInfo[Remote]}" --force "$___git__merge__CheckOrCleanBranch___Branch" || return 7
      else
         :git:is_local_branch --checkout "${___git__merge___MergeInfo[Remote]}" "$___git__merge__CheckOrCleanBranch___Branch" || return 7
      fi

   elif ${___git__merge___MergeInfo[Force]}; then
      git reset --hard "${___git__merge___MergeInfo[Remote]}/$___git__merge__CheckOrCleanBranch___Branch"
      git clean -f -d
      git pull --all

   else
      local ___git__merge__CheckOrCleanBranch___Changes                                  # Used for identifying pending changes
      ___git__merge__CheckOrCleanBranch___Changes="$( git status --porcelain Source/content 2>/dev/null )"

      # If there are changes or if merge conflicts presently exist, then error return
      if [[ -n $___git__merge__CheckOrCleanBranch___Changes || -n $( git ls-files -u ) ]]; then
         :error: 8 "Changes or untracked files prevent merging:\n\n$___git__merge__CheckOrCleanBranch___Changes"
         return
      fi
   fi
}
