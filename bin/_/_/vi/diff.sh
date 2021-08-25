#!/bin/bash

:vi:diff%HELP()
{
   local ___vi__diff__diffHELP___Synopsis='Recursively diff two directories and use vi to view differences'
   local ___vi__diff__diffHELP___Usage='<path1> <path2>'

   :help: --set "$___vi__diff__diffHELP___Synopsis" --usage "$___vi__diff__diffHELP___Usage" <<EOF
OPTIONS:
   -i|--include         ^Include files matching the glob pattern <pat> (can be used multiple times)

   -.|--hidden          ^Exclude files or directories beginning with a dot (.)
   -_|--underscore      ^Exclude files or directories beginning with an underscore (_)
   -p|--prune           ^Exclude common binary formats and files or directories beginning with a dot (.)
   -x|--exclude <pat>   ^Exclude files matching the glob pattern <pat> (can be used multiple times)
   -1|--exclude-1       ^Exclude files that are present on only one side of the directories

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
   local ___vi__diff__diff___Options
   ___vi__diff__diff___Options=$(getopt -o '._pi:x:1nls' -l "hidden,underscore,prune,include:,exclude:,exclude-1,no-dirs,list,same" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___vi__diff__diff___Options"

   local ___vi__diff__diff___Exclude1=false
   local ___vi__diff__diff___CreateDirs=true
   local ___vi__diff__diff___List=false
   local ___vi__diff__diff___Same=false
   local -a ___vi__diff__diff___Include=()
   local -a ___vi__diff__diff___Exclude=()

   while true ; do
      case "$1" in
      -.|--hidden)      ___vi__diff__diff___Exclude+=( -o -name '\.*' ); shift;;
      -_|--underscore)  ___vi__diff__diff___Exclude+=( -o -name '_*' ); shift;;
      -p|--prune)       ___vi__diff__diff___Exclude+=( -o -name '\.*' -o -name '*.idea' -o -name '*.iml' ); shift;;
      -i|--include)     ___vi__diff__diff___Include+=( -o -name "$2" ); shift 2;;
      -x|--exclude)     ___vi__diff__diff___Exclude+=( -o -name "$2" ); shift 2;;
      -1|--exclude-1)   ___vi__diff__diff___Exclude1=true; shift;;
      -n|--no-dirs)     ___vi__diff__diff___CreateDirs=false; shift;;
      -l|--list)        ___vi__diff__diff___List=true; shift;;
      -s|--same)        ___vi__diff__diff___List=true; ___vi__diff__diff___Same=true; shift;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local ___vi__diff__diff___First="$1"
   local ___vi__diff__diff___Second="$2"
   local ___vi__diff__diff___Dir1="$(readlink -fm "$1")"
   local ___vi__diff__diff___Dir2="$(readlink -fm "$2")"

   if ! [[ -d $___vi__diff__diff___Dir1 && -d $___vi__diff__diff___Dir2 ]]; then
      :highlight: <<<'<R>vi diff: an invalid directory was specified</R>'
      return 1
   fi

   # If pruning files and directories, then add arguments for pruning
   local -a ___vi__diff__diff___Prune=()
   if (( ${#___vi__diff__diff___Exclude[@]} > 0 )); then
      ___vi__diff__diff___Prune=( '(' "${___vi__diff__diff___Exclude[@]:1}" ')' -prune -o )
   fi

   if (( ${#___vi__diff__diff___Include[@]} > 0 )); then
      ___vi__diff__diff___Include=( '(' "${___vi__diff__diff___Include[@]:1}" ')' )
   fi

   ### GATHER FILE PATHS
   # Path 1 Files
   local -a ___vi__diff__diff___Path1Files=()
   if [[ -z $(find "$___vi__diff__diff___Dir1" -maxdepth 0 -type d -empty) ]]; then
      # Generate the list of files to inspect for Dir1
      cd "$___vi__diff__diff___Dir1"
      readarray -t ___vi__diff__diff___Path1Files < <(
         find * "${___vi__diff__diff___Prune[@]}" -type f "${___vi__diff__diff___Include[@]}" -print |
         sed 's|^\./||' |
         LC_ALL=C sort
      )
   fi

   # Path 2 Files
   local -a ___vi__diff__diff___Path2Files=()
   if [[ -z $(find "$___vi__diff__diff___Dir2" -maxdepth 0 -type d -empty) ]]; then
      # Generate the list of files to inspect for Dir2
      cd "$___vi__diff__diff___Dir2"
      readarray -t ___vi__diff__diff___Path2Files < <(
         find * "${___vi__diff__diff___Prune[@]}" -type f "${___vi__diff__diff___Include[@]}" -print |
         sed 's|^\./||' |
         LC_ALL=C sort
      )
   fi

   ### Generate script for each file
   local -A ___vi__diff__diff___Script
   local -A ___vi__diff__diff___Found

   cd "$___vi__diff__diff___Dir1"
   for ___vi__diff__diff___File in "${___vi__diff__diff___Path1Files[@]}"; do
      # If the other side has the file
      if [[ -f $___vi__diff__diff___Dir2/$___vi__diff__diff___File ]]; then
         ___vi__diff__diff___Found[$___vi__diff__diff___File]='true'
         if cmp -s "$___vi__diff__diff___File" "$___vi__diff__diff___Dir2/$___vi__diff__diff___File"; then
            if $___vi__diff__diff___Same; then
               ___vi__diff__diff___Script[$___vi__diff__diff___File]="echo '$( :highlight: <<<"   <G>$___vi__diff__diff___File</G>" )'"
            fi
         elif $___vi__diff__diff___List; then
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="echo '$( :highlight: <<<"<b>!=</b> <B>$___vi__diff__diff___File</B>" )'"
         else
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="vi -d '$___vi__diff__diff___Dir1/$___vi__diff__diff___File' '$___vi__diff__diff___Dir2/$___vi__diff__diff___File'"
         fi

      # Else this is a one-sided diff
      elif ! $___vi__diff__diff___Exclude1; then
         if $___vi__diff__diff___List; then
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="echo '$( :highlight: <<<"<b><<</b> <R>$___vi__diff__diff___File</R>" )'"
         elif $___vi__diff__diff___CreateDirs; then
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="mkdir -p '$___vi__diff__diff___Dir2'; vi -d '$___vi__diff__diff___Dir1/$___vi__diff__diff___File' '$___vi__diff__diff___Dir2/$___vi__diff__diff___File'"
         else
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="vi -d '$___vi__diff__diff___Dir1/$___vi__diff__diff___File' '$___vi__diff__diff___Dir2/$___vi__diff__diff___File'"
         fi
      fi
   done

   # If there are any files under Dir2 that weren't under Dir1, then these are one-sided diffs
   cd "$___vi__diff__diff___Dir2"
   for ___vi__diff__diff___File in "${___vi__diff__diff___Path2Files[@]}"; do
      if [[ ${___vi__diff__diff___Found[$___vi__diff__diff___File]} != true ]] && ! $___vi__diff__diff___Exclude1; then
         if $___vi__diff__diff___List; then
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="echo '$( :highlight: <<<"<b>>></b> <R>$___vi__diff__diff___File</R>" )'"
         elif $___vi__diff__diff___CreateDirs; then
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="mkdir -p '$___vi__diff__diff___Dir1'; vi -d '$___vi__diff__diff___Dir1/$___vi__diff__diff___File' '$___vi__diff__diff___Dir2/$___vi__diff__diff___File'"
         else
            ___vi__diff__diff___Script[$___vi__diff__diff___File]="vi -d '$___vi__diff__diff___Dir1/$___vi__diff__diff___File' '$___vi__diff__diff___Dir2/$___vi__diff__diff___File'"
         fi
      fi
   done

   # Sort the files for which differences were found so the output is in a predictable order
   local -a ___vi__diff__diff___Keys
   readarray -t ___vi__diff__diff___Keys < <(
      printf '%s\n' "${!___vi__diff__diff___Script[@]}" |
      LC_ALL=C sort |
      sed '/^$/d'
   )

   # Create a temp file and make provision that this file is cleaned up, even on a premature exit
   trap :vi:diff:ViDiffCleanup EXIT
   local ___vi__diff___ScriptFile="$(mktemp)"

   # Generate the script file
   local ___vi__diff__diff___Key
   for ___vi__diff__diff___Key in "${___vi__diff__diff___Keys[@]}"; do
      printf '%s\n' "${___vi__diff__diff___Script[$___vi__diff__diff___Key]}" >> "$___vi__diff___ScriptFile"
   done

   # Execute the script file: either listing or diffing files
   bash "$___vi__diff___ScriptFile"

   :vi:diff:ViDiffCleanup
}

:vi:diff:ViDiffCleanup()
{
   if [[ -f $___vi__diff___ScriptFile ]]; then
      cd "$_invocationDir"
      rm -f "$___vi__diff___ScriptFile"

      ___vi__diff___ScriptFile=
   fi
}
