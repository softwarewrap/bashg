#!/bin/bash

:vi:diff%HELP()
{
   local __vi__diff__diffHELP___Synopsis='Recursively diff two directories and use vi to view differences'
   local __vi__diff__diffHELP___Usage='<path1> <path2>'

   :help: --set "$__vi__diff__diffHELP___Synopsis" --usage "$__vi__diff__diffHELP___Usage" <<EOF
OPTIONS:
   -i|--include         ^Include files matching the glob pattern <pat> (can be used multiple times)

   -.|--hidden          ^Exclude files or directories beginning with a dot (.)
   -_|--underscore      ^Exclude files or directories beginning with an underscore (_)
   -p|--prune           ^Exclude common binary formats and files or directories beginning with a dot (.)
   -x|--exclude <pat>   ^Exclude files matching the glob pattern <pat> (can be used multiple times)
   -1|--exclude-1       ^Exclude files that are present on only one side of the directories

   -g|--group           ^Group by deleted first, common next, and added last [default: dictionary order]
   -n|--no-dirs         ^Do not create directories as needed for one-sided diffs

   -l|--list            ^List filenames whose contents are different instead of invoking vi
   -s|--same            ^Also list filenames that are the same (implies --list)

DESCRIPTION:
   Edit or list differences between two directories

   The inclusion and inclusion options above are used to reduce the candidate
   files for comparison to just those that are include and not excluded.

   NOTE: The pattern used by --exclude is a glob pattern, not a regular expression.

   The <b>--exclude-1</b> option is used to exclude files that are present on just
   one side of the comparison.

   If <b>--no-dirs</b> is specified, then do not create directories that are not present
   on one side of the diff, but not the other side.

   NOTE: This is typically wanted for previewing differences when no changes are intended.

   If <b>--list</b> is specified, then just list the filenames whose contents are different.
EOF
}

:vi:diff()
{
   if [[ -f $HOME/.vim/diff.conf ]]; then
      set -- $( printf '%q\n' $( cat ~/.vim/diff.conf ) | xargs echo ) "$@"
   fi

   local __vi__diff__diff___Options
   __vi__diff__diff___Options=$(getopt -o '._pi:x:1gnls' -l "hidden,underscore,prune,include:,exclude:,exclude-1,group,no-dirs,list,same" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__vi__diff__diff___Options"

   local __vi__diff__diff___Exclude1=false
   local __vi__diff__diff___Group=
   local __vi__diff__diff___CreateDirs=true
   local __vi__diff__diff___List=false
   local __vi__diff__diff___Same=false
   local -a __vi__diff__diff___Include=()
   local -a __vi__diff__diff___Exclude=()

   while true ; do
      case "$1" in
      -.|--hidden)      __vi__diff__diff___Exclude+=( -o -name '\.*' ); shift;;
      -_|--underscore)  __vi__diff__diff___Exclude+=( -o -name '_*' ); shift;;
      -p|--prune)       __vi__diff__diff___Exclude+=( -o -name '\.*' -o -name '*.idea' -o -name '*.iml' ); shift;;
      -i|--include)     __vi__diff__diff___Include+=( -o -name "$2" ); shift 2;;
      -x|--exclude)     __vi__diff__diff___Exclude+=( -o -name "$2" ); shift 2;;
      -1|--exclude-1)   __vi__diff__diff___Exclude1=true; shift;;
      -g|--group)       __vi__diff__diff___Group=true; shift;;
      -n|--no-dirs)     __vi__diff__diff___CreateDirs=false; shift;;
      -l|--list)        __vi__diff__diff___List=true; shift;;
      -s|--same)        __vi__diff__diff___List=true; __vi__diff__diff___Same=true; shift;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local __vi__diff__diff___First="$1"
   local __vi__diff__diff___Second="$2"
   local __vi__diff__diff___Dir1="$(readlink -fm "$1")"
   local __vi__diff__diff___Dir2="$(readlink -fm "$2")"

   if ! [[ -d $__vi__diff__diff___Dir1 && -d $__vi__diff__diff___Dir2 ]]; then
      :highlight: <<<'<R>vi diff: an invalid directory was specified</R>'
      return 1
   fi

   # If pruning files and directories, then add arguments for pruning
   local -a __vi__diff__diff___Prune=()
   if (( ${#__vi__diff__diff___Exclude[@]} > 0 )); then
      __vi__diff__diff___Prune=( '(' "${__vi__diff__diff___Exclude[@]:1}" ')' -prune -o )
   fi

   if (( ${#__vi__diff__diff___Include[@]} > 0 )); then
      __vi__diff__diff___Include=( '(' "${__vi__diff__diff___Include[@]:1}" ')' )
   fi

   ### GATHER FILE PATHS
   # Path 1 Files
   local -a __vi__diff__diff___Path1Files=()
   if [[ -z $(find "$__vi__diff__diff___Dir1" -maxdepth 0 -type d -empty) ]]; then
      # Generate the list of files to inspect for Dir1
      cd "$__vi__diff__diff___Dir1"
      readarray -t __vi__diff__diff___Path1Files < <(
         find * "${__vi__diff__diff___Prune[@]}" -type f "${__vi__diff__diff___Include[@]}" -print |
         sed 's|^\./||' |
         LC_ALL=C sort
      )
   fi

   # Path 2 Files
   local -a __vi__diff__diff___Path2Files=()
   if [[ -z $(find "$__vi__diff__diff___Dir2" -maxdepth 0 -type d -empty) ]]; then
      # Generate the list of files to inspect for Dir2
      cd "$__vi__diff__diff___Dir2"
      readarray -t __vi__diff__diff___Path2Files < <(
         find * "${__vi__diff__diff___Prune[@]}" -type f "${__vi__diff__diff___Include[@]}" -print |
         sed 's|^\./||' |
         LC_ALL=C sort
      )
   fi

   ### Generate script for each file
   local -A __vi__diff__diff___Script
   local -A __vi__diff__diff___Found

   cd "$__vi__diff__diff___Dir1"
   for __vi__diff__diff___File in "${__vi__diff__diff___Path1Files[@]}"; do
      # If the other side has the file
      if [[ -f $__vi__diff__diff___Dir2/$__vi__diff__diff___File ]]; then
         __vi__diff__diff___Found[$__vi__diff__diff___File]='true'
         if cmp -s "$__vi__diff__diff___File" "$__vi__diff__diff___Dir2/$__vi__diff__diff___File"; then
            if $__vi__diff__diff___Same; then
               __vi__diff__diff___Script[$__vi__diff__diff___File]="echo '$( :highlight: <<<"   <G>$__vi__diff__diff___File</G>" )'"
            fi
         elif $__vi__diff__diff___List; then
            __vi__diff__diff___Script[${__vi__diff__diff___Group:+2}$__vi__diff__diff___File]="echo '$( :highlight: <<<"<b> </b> <B>$__vi__diff__diff___File</B>" )'"
         else
            __vi__diff__diff___Script[$__vi__diff__diff___File]="vi -d '$__vi__diff__diff___Dir1/$__vi__diff__diff___File' '$__vi__diff__diff___Dir2/$__vi__diff__diff___File'"
         fi

      # Else this is a one-sided diff
      elif ! $__vi__diff__diff___Exclude1; then
         if $__vi__diff__diff___List; then
            __vi__diff__diff___Script[${__vi__diff__diff___Group:+1}$__vi__diff__diff___File]="echo '$( :highlight: <<<"<b>-</b> <R>$__vi__diff__diff___File</R>" )'"
         elif $__vi__diff__diff___CreateDirs; then
            __vi__diff__diff___Script[$__vi__diff__diff___File]="mkdir -p '$__vi__diff__diff___Dir2'; vi -d '$__vi__diff__diff___Dir1/$__vi__diff__diff___File' '$__vi__diff__diff___Dir2/$__vi__diff__diff___File'"
         else
            __vi__diff__diff___Script[$__vi__diff__diff___File]="vi -d '$__vi__diff__diff___Dir1/$__vi__diff__diff___File' '$__vi__diff__diff___Dir2/$__vi__diff__diff___File'"
         fi
      fi
   done

   # If there are any files under Dir2 that weren't under Dir1, then these are one-sided diffs
   cd "$__vi__diff__diff___Dir2"
   for __vi__diff__diff___File in "${__vi__diff__diff___Path2Files[@]}"; do
      if [[ ${__vi__diff__diff___Found[$__vi__diff__diff___File]} != true ]] && ! $__vi__diff__diff___Exclude1; then
         if $__vi__diff__diff___List; then
            __vi__diff__diff___Script[${__vi__diff__diff___Group:+3}$__vi__diff__diff___File]="echo '$( :highlight: <<<"<b>+</b> <G>$__vi__diff__diff___File</G>" )'"
         elif $__vi__diff__diff___CreateDirs; then
            __vi__diff__diff___Script[$__vi__diff__diff___File]="mkdir -p '$__vi__diff__diff___Dir1'; vi -d '$__vi__diff__diff___Dir1/$__vi__diff__diff___File' '$__vi__diff__diff___Dir2/$__vi__diff__diff___File'"
         else
            __vi__diff__diff___Script[$__vi__diff__diff___File]="vi -d '$__vi__diff__diff___Dir1/$__vi__diff__diff___File' '$__vi__diff__diff___Dir2/$__vi__diff__diff___File'"
         fi
      fi
   done

   # Sort the files for which differences were found so the output is in a predictable order
   local -a __vi__diff__diff___Keys
   readarray -t __vi__diff__diff___Keys < <(
      printf '%s\n' "${!__vi__diff__diff___Script[@]}" |
      LC_ALL=C sort -f |
      sed '/^$/d'
   )

   # Create a temp file and make provision that this file is cleaned up, even on a premature exit
   trap :vi:diff:ViDiffCleanup EXIT
   local __vi__diff___ScriptFile="$(mktemp)"

   # Generate the script file
   local __vi__diff__diff___Key
   for __vi__diff__diff___Key in "${__vi__diff__diff___Keys[@]}"; do
      printf '%s\n' "${__vi__diff__diff___Script[$__vi__diff__diff___Key]}" >> "$__vi__diff___ScriptFile"
   done

   # Execute the script file: either listing or diffing files
   bash "$__vi__diff___ScriptFile"

   :vi:diff:ViDiffCleanup
}

:vi:diff:ViDiffCleanup()
{
   if [[ -f $__vi__diff___ScriptFile ]]; then
      cd "$_invocationDir"
      rm -f "$__vi__diff___ScriptFile"

      __vi__diff___ScriptFile=
   fi
}
