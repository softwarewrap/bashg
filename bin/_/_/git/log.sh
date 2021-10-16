#!/bin/bash

:git:log%HELP()
{
   local __git__log__logHELP___Synopsis='Show a formatted log of git changes'
   local __git__log__logHELP___Usage='[OPTIONS] [<range-spec>]'

   :help: --set "$__git__log__logHELP___Synopsis" --usage "$__git__log__logHELP___Usage" <<EOF
OPTIONS:
   -a|--all          ^Show all commits for the current branch
   -r|--raw          ^Raw mode: do not perform idiom replacements
   -u|--user <name>  ^Show commits made only by <name>

DESCRIPTION:
   Show a formatted log of git changes, using color for emphasis.

   If <range-spec> is specified, then it must be of a form consumable by git log.
   If <range-spec> is not specified, then <B>-1</B> is assumed.

   If --all is specified, then all commits to the current branch are emitted.

   If --user is specified, then show commits made only for authors that
   exactly match the author name with <name>.

   Paging using commands such as <b>more</b> and <b>less</b> is not provided.

IDIOM REPLACEMENTS:
   This section applies only if --raw is not specified.

   If the <range-spec> takes one of the forms below to select a commit ID <ID> or a
   range of commit IDs <ID1> and <ID2>, then these forms are automatically translated
   as indicated:

      <G>IDIOM:         TAKEN TO BE:</G>
      <b><ID></b>           <B><ID>\^..<ID></B>
                     - Show just the one commit

      <b><ID>..</b>         <B><ID>\^..HEAD</B>
                     - Show the commits from the specified commit to HEAD, inclusive

      <b><ID1>..<ID2></b>   <B><ID1>\^..<ID2></B>
                     - Show the commits between the specified commits, inclusive

OUTPUT:
   The output contains the following entries for each commit (most recent first):

      Line 1^<K
         commit-id   - The commit-id is shown in <B>blue</B>
         age         - The age of the commit is shown in <G>green</G>
         commit-msg  - The commit message is shown as <b>bold</b>
         commit-user - The commit user is shown in <M>magenta</M>

      Subsequent Lines^<K
         The file changes are shown

EXAMPLES:
   :git:log                    ^Show the most recent commit
   :git:log -5                 ^Show the most recent 5 commits
   :git:log 00e2704            ^Show the changes for just the one commit-id 00e2704
   :git:log 00e2704..          ^Show the changes from the commit-id 00e2704 to HEAD, inclusive
   :git:log 00e2704..4644050   ^Show the changes from the commit-id 00e2704 to 4644050, inclusive

SEE:
   https://git-scm.com/docs/gitrevisions
EOF
}

:git:log()
{
   local -ag __git__log__log___GitOptions=(
      --no-pager
      log
      --color
      --graph
      --abbrev-commit
      --decorate
      --name-status
      --date='format:%Y-%m-%d.%H:%M'
      --format='format:%C(bold blue)%h%C(reset) - %C(bold green)%ar (%ad)%C(reset) - %C(bold black)%s%C(reset) - %C(bold magenta)%an%C(reset)%C(bold yellow)%d%C(reset)%n'
   )

   local -g __git__log__log___Args=()                                  # Store any remaining args in this variable

   :getopts: begin \
      -o 'aru:' \
      -l 'all,raw,user:' \
      -- "$@"

   local __git__log__log___Option                                      # Option character or word
   local __git__log__log___Value                                       # Value for options that take a value
   local __git__log__log___All=false
   local __git__log__log___RawMode=false

   while :getopts: next __git__log__log___Option __git__log__log___Value; do
      case "$__git__log__log___Option" in
      -a|--all)   __git__log__log___All=true;;
      -r|--raw)   __git__log__log___RawMode=true;;
      -u|--user)  __git__log__log___GitOptions+=( --author="^$__git__log__log___Value\\s" )
                  __git__log__log___RawMode=true;;
                                                         # Show commits only for the specified user
      *)          break;;
      esac
   done

   :getopts: end --save __git__log__log___Args                         # Save unused args
   set -- "${__git__log__log___Args[@]}"                               # Set positional parameters to unused args

   ### VALIDATION
   local __git__log__log___CurrentBranch
   if ! __git__log__log___CurrentBranch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"; then
      :error: 1 "Current directory is not in a git project: $PWD"
      return 1
   fi

   ### ARGUMENT EVALUATION
   if $__git__log__log___All; then
      set -- "$__git__log__log___CurrentBranch"

   elif [[ $# -le 1 ]] && ! $__git__log__log___RawMode; then
      (( $# > 0 )) || set -- '-1'                        # Default: show most recent commit
      if [[ $1 =~ '..'$ && ! $1 =~ '^..'$ ]]; then
         set -- "${1%..}^..HEAD"                         # Show changes from commit-id to HEAD, inclusive

      elif [[ $1 =~ '..' && ! $1 =~ '^..' && ! $1 =~ '..'$ ]]; then
         set -- "${1//../^..}"

      elif [[ ! $1 =~ '..' && ! $1 =~ ^-[0-9]+$ ]]; then
         set -- "$1^..$1"                                # Show changes just for the one commit-id
      fi
   fi

   git "${__git__log__log___GitOptions[@]}" "$@"                       # Show the git log
}
