#!/bin/bash

+ merge%HELP()
{
   local (.)_Synopsis='Merge from one git branch to another'
   local (.)_Usage='[OPTIONS] [<from-branch>] <to-branch>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
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

+ merge()
{
   local -Ag (-)_MergeInfo                               # Store data to be persisted in this variable
   (++:launcher):persist (-)_MergeInfo                   # Indicate this is to be a persisted variable

   (-):ProcessOptionsAndValidate "$@"                    # Gather information and store in MergeInfo
   (-):PerformMerge "${(-)_MergeInfo[User]}"             # Ensure the branches are ready for merging
}

- ProcessOptionsAndValidate()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'd:u:r:fn' -l 'dir:,user:,remote:,force,no-push' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   ########################################
   # Variables Available after Processing #
   ########################################
   (-)_MergeInfo[FromBranch]=                            # The branch from which to merge
   (-)_MergeInfo[ToBranch]=                              # The branch into which to merge
   (-)_MergeInfo[TopDir]=                                # The top directory of the git project
   (-)_MergeInfo[CurrentBranch]=                         # The current branch before processing

   ### User-specified options or defaults
   (-)_MergeInfo[Path]=                                  # A directory within the git project
   (-)_MergeInfo[User]=                                  # The user to perform git operations as
   (-)_MergeInfo[Remote]=origin                          # The remote which to push
   (-)_MergeInfo[Force]=false                            # Force branch cleanup?
   (-)_MergeInfo[Push]=true                              # Perform the push step?

   while true ; do
      case "$1" in
      -d|--dir)      (-)_MergeInfo[Path]="$2"; shift 2;;
      -u|--user)     (-)_MergeInfo[User]="$2"; shift 2;;
      -r|--remote)   (-)_MergeInfo[Remote]="$2"; shift 2;;
      -f|--force)    (-)_MergeInfo[Force]=true; shift;;
      -n|--no-push)  (-)_MergeInfo[Push]=false; shift;;

      --)            shift; break;;
      *)             break;;
      esac
   done


   ##############
   # VALIDATION #
   ##############
   # --dir <path>
   if [[ -n ${(-)_MergeInfo[Path]} ]]; then
      if ! cd "${(-)_MergeInfo[Path]}"; then
         :error: 2 "Cannot change directory to ${(-)_MergeInfo[Path]}"
         return
      fi
   else
      (-)_MergeInfo[Path]="$( pwd )"
   fi

   # Verify <path> is within a git project
   if ! (-)_MergeInfo[TopDir]="$( git rev-parse --show-toplevel 2>/dev/null )"; then
      :error: 3 "Not a git directory: ${(-)_MergeInfo[Path]}"
      return
   fi

   # --user <name>
   if [[ -n ${(-)_MergeInfo[User]} ]]; then
      if ! :test:has_user "${(-)_MergeInfo[User]}"; then # Ensure the specified user exists
         :error: 4 "No such user: ${(-)_MergeInfo[User]}"
         return
      fi
   else
      (-)_MergeInfo[User]="$(stat -c '%U' "${(-)_MergeInfo[TopDir]}")"
                                                         # Use the owner of the git top-level dir by default
   fi

   (-)_MergeInfo[CurrentBranch]="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

   # 1 or 2 arguments are required and specify the branch names
   if (( $# == 1 )); then                                # The current branch is the <from-branch>
      (-)_MergeInfo[FromBranch]="${(-)_MergeInfo[CurrentBranch]}"
      (-)_MergeInfo[ToBranch]="$1"

   elif (( $# != 2 )); then                              # 0 or >2 arguments is not allowed
      :error: 5 'Invalid number of arguments'
      return

   else
      (-)_MergeInfo[FromBranch]="$1"
      (-)_MergeInfo[ToBranch]="$2"
   fi

   # --remote <remote>
   if ! git config remote.${(-)_MergeInfo[Remote]}.url &>/dev/null; then
      :error: 6 "Invalid remote: ${(-)_MergeInfo[Remote]}"
      return
   fi
}

- PerformMerge()
{
   :test:has_user "${(-)_MergeInfo[User]}" || return 1   # A valid user must be specified

   :sudo "${(-)_MergeInfo[User]}" || :reenter            # This function must run as root

   cd "${(-)_MergeInfo[TopDir]}"                         # Run within the git project

   # Check branches for changes
   (-):CheckOrCleanBranch "${(-)_MergeInfo[CurrentBranch]}" || return
   (-):CheckOrCleanBranch "${(-)_MergeInfo[FromBranch]}" || return
   (-):CheckOrCleanBranch "${(-)_MergeInfo[ToBranch]}" || return

   git merge --no-ff -m "Merge ${(-)_MergeInfo[FromBranch]} into ${(-)_MergeInfo[ToBranch]}" "${(-)_MergeInfo[FromBranch]}"
                                                         # Merge into the ToBranch (current) from the FromBranch

   local (.)_Changes                                     # Used for identifying pending changes
   (.)_Changes="$( git status --porcelain Source/content 2>/dev/null )"

   if [[ -z $(.)_Changes && -z $( git ls-files -u ) ]]; then
      echo 'No changes to merge'
      git checkout "${(-)_MergeInfo[CurrentBranch]}"     # Return to the original branch
      return 0
   fi

   git commit --amend --no-edit                          # Ensure Change-Id is in the commit

   if [[ -n $( git ls-files -u ) ]]; then
      :error: 9 "Merge conflicts in ${(-)_MergeInfo[TopDir]} prevent merging from ${(-)_MergeInfo[FromBranch]} into ${(-)_MergeInfo[ToBranch]}"
      return
   fi

   if ${(-)_MergeInfo[Push]}; then
      git push "${(-)_MergeInfo[Remote]}"                # Push the merge to the remote
   else
      echo 'Not pushing changes'
      return 0
   fi

   local (.)_CurrentBranch
   (.)_CurrentBranch="$( git rev-parse --abbrev-ref HEAD 2>/dev/null )"

   if [[ $(.)_CurrentBranch != ${(-)_MergeInfo[CurrentBranch]} ]]; then
      git checkout "${(-)_MergeInfo[CurrentBranch]}"
   fi
}

- CheckOrCleanBranch()
{
   local (.)_Branch="$1"

   local (.)_CurrentBranch
   (.)_CurrentBranch="$( git rev-parse --abbrev-ref HEAD 2>/dev/null )"

   if [[ $(.)_CurrentBranch != $(.)_Branch ]]; then
      if ${(-)_MergeInfo[Force]}; then
         :git:is_local_branch --checkout "${(-)_MergeInfo[Remote]}" --force "$(.)_Branch" || return 7
      else
         :git:is_local_branch --checkout "${(-)_MergeInfo[Remote]}" "$(.)_Branch" || return 7
      fi

   elif ${(-)_MergeInfo[Force]}; then
      git reset --hard "${(-)_MergeInfo[Remote]}/$(.)_Branch"
      git clean -f -d
      git pull --all

   else
      local (.)_Changes                                  # Used for identifying pending changes
      (.)_Changes="$( git status --porcelain Source/content 2>/dev/null )"

      # If there are changes or if merge conflicts presently exist, then error return
      if [[ -n $(.)_Changes || -n $( git ls-files -u ) ]]; then
         :error: 8 "Changes or untracked files prevent merging:\n\n$(.)_Changes"
         return
      fi
   fi
}
