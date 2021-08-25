#!/bin/bash

+ diff%HELP()
{
   local (.)_Synopsis='Recursively diff two directories and use vi to view differences'
   local (.)_Usage='<path1> <path2>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
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

+ diff()
{
   local (.)_Options
   (.)_Options=$(getopt -o '._pi:x:1nls' -l "hidden,underscore,prune,include:,exclude:,exclude-1,no-dirs,list,same" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Exclude1=false
   local (.)_CreateDirs=true
   local (.)_List=false
   local (.)_Same=false
   local -a (.)_Include=()
   local -a (.)_Exclude=()

   while true ; do
      case "$1" in
      -.|--hidden)      (.)_Exclude+=( -o -name '\.*' ); shift;;
      -_|--underscore)  (.)_Exclude+=( -o -name '_*' ); shift;;
      -p|--prune)       (.)_Exclude+=( -o -name '\.*' -o -name '*.idea' -o -name '*.iml' ); shift;;
      -i|--include)     (.)_Include+=( -o -name "$2" ); shift 2;;
      -x|--exclude)     (.)_Exclude+=( -o -name "$2" ); shift 2;;
      -1|--exclude-1)   (.)_Exclude1=true; shift;;
      -n|--no-dirs)     (.)_CreateDirs=false; shift;;
      -l|--list)        (.)_List=true; shift;;
      -s|--same)        (.)_List=true; (.)_Same=true; shift;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local (.)_First="$1"
   local (.)_Second="$2"
   local (.)_Dir1="$(readlink -fm "$1")"
   local (.)_Dir2="$(readlink -fm "$2")"

   if ! [[ -d $(.)_Dir1 && -d $(.)_Dir2 ]]; then
      :highlight: <<<'<R>vi diff: an invalid directory was specified</R>'
      return 1
   fi

   # If pruning files and directories, then add arguments for pruning
   local -a (.)_Prune=()
   if (( ${#(.)_Exclude[@]} > 0 )); then
      (.)_Prune=( '(' "${(.)_Exclude[@]:1}" ')' -prune -o )
   fi

   if (( ${#(.)_Include[@]} > 0 )); then
      (.)_Include=( '(' "${(.)_Include[@]:1}" ')' )
   fi

   ### GATHER FILE PATHS
   # Path 1 Files
   local -a (.)_Path1Files=()
   if [[ -z $(find "$(.)_Dir1" -maxdepth 0 -type d -empty) ]]; then
      # Generate the list of files to inspect for Dir1
      cd "$(.)_Dir1"
      readarray -t (.)_Path1Files < <(
         find * "${(.)_Prune[@]}" -type f "${(.)_Include[@]}" -print |
         sed 's|^\./||' |
         LC_ALL=C sort
      )
   fi

   # Path 2 Files
   local -a (.)_Path2Files=()
   if [[ -z $(find "$(.)_Dir2" -maxdepth 0 -type d -empty) ]]; then
      # Generate the list of files to inspect for Dir2
      cd "$(.)_Dir2"
      readarray -t (.)_Path2Files < <(
         find * "${(.)_Prune[@]}" -type f "${(.)_Include[@]}" -print |
         sed 's|^\./||' |
         LC_ALL=C sort
      )
   fi

   ### Generate script for each file
   local -A (.)_Script
   local -A (.)_Found

   cd "$(.)_Dir1"
   for (.)_File in "${(.)_Path1Files[@]}"; do
      # If the other side has the file
      if [[ -f $(.)_Dir2/$(.)_File ]]; then
         (.)_Found[$(.)_File]='true'
         if cmp -s "$(.)_File" "$(.)_Dir2/$(.)_File"; then
            if $(.)_Same; then
               (.)_Script[$(.)_File]="echo '$( :highlight: <<<"   <G>$(.)_File</G>" )'"
            fi
         elif $(.)_List; then
            (.)_Script[$(.)_File]="echo '$( :highlight: <<<"<b>!=</b> <B>$(.)_File</B>" )'"
         else
            (.)_Script[$(.)_File]="vi -d '$(.)_Dir1/$(.)_File' '$(.)_Dir2/$(.)_File'"
         fi

      # Else this is a one-sided diff
      elif ! $(.)_Exclude1; then
         if $(.)_List; then
            (.)_Script[$(.)_File]="echo '$( :highlight: <<<"<b><<</b> <R>$(.)_File</R>" )'"
         elif $(.)_CreateDirs; then
            (.)_Script[$(.)_File]="mkdir -p '$(.)_Dir2'; vi -d '$(.)_Dir1/$(.)_File' '$(.)_Dir2/$(.)_File'"
         else
            (.)_Script[$(.)_File]="vi -d '$(.)_Dir1/$(.)_File' '$(.)_Dir2/$(.)_File'"
         fi
      fi
   done

   # If there are any files under Dir2 that weren't under Dir1, then these are one-sided diffs
   cd "$(.)_Dir2"
   for (.)_File in "${(.)_Path2Files[@]}"; do
      if [[ ${(.)_Found[$(.)_File]} != true ]] && ! $(.)_Exclude1; then
         if $(.)_List; then
            (.)_Script[$(.)_File]="echo '$( :highlight: <<<"<b>>></b> <R>$(.)_File</R>" )'"
         elif $(.)_CreateDirs; then
            (.)_Script[$(.)_File]="mkdir -p '$(.)_Dir1'; vi -d '$(.)_Dir1/$(.)_File' '$(.)_Dir2/$(.)_File'"
         else
            (.)_Script[$(.)_File]="vi -d '$(.)_Dir1/$(.)_File' '$(.)_Dir2/$(.)_File'"
         fi
      fi
   done

   # Sort the files for which differences were found so the output is in a predictable order
   local -a (.)_Keys
   readarray -t (.)_Keys < <(
      printf '%s\n' "${!(.)_Script[@]}" |
      LC_ALL=C sort |
      sed '/^$/d'
   )

   # Create a temp file and make provision that this file is cleaned up, even on a premature exit
   trap (-):ViDiffCleanup EXIT
   local (-)_ScriptFile="$(mktemp)"

   # Generate the script file
   local (.)_Key
   for (.)_Key in "${(.)_Keys[@]}"; do
      printf '%s\n' "${(.)_Script[$(.)_Key]}" >> "$(-)_ScriptFile"
   done

   # Execute the script file: either listing or diffing files
   bash "$(-)_ScriptFile"

   (-):ViDiffCleanup
}

- ViDiffCleanup()
{
   if [[ -f $(-)_ScriptFile ]]; then
      cd "$_invocationDir"
      rm -f "$(-)_ScriptFile"

      (-)_ScriptFile=
   fi
}
