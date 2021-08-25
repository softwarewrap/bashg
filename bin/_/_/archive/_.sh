#!/bin/bash

:archive:%HELP()
{
   local ___archive_____HELP___Synopsis='Copy or move the paths provided to the archive path'
   local ___archive_____HELP___Usage='<path>...'

   :help: --set "$___archive_____HELP___Synopsis" --usage "$___archive_____HELP___Usage" <<'EOF'
OPTIONS:
   -a|--archive-dir <dir>  ^Specify the archive <dir> [default for users: root: /orig, others: $HOME/.orig]
   -m|--move               ^Move instead of copying
   -f|--force              ^Archive even if previously archived
   -v|--verbose            ^Indicate actions taken
   -0|--no-error           ^Return 0 even if archiving was not performed

   -n|--dry-run            ^Do nothing (dry run only implies --verbose)

DESCRIPTION:
   Copy or move a <path> items (files or directories) to the archive directory.

   Late expansion is supported and includes exported parameter expansion and
   wildcard expansion. This typically happens within quoted strings.

EXAMPLES:
   cd /etc/httpd/conf
   $__ :archive: httpd.conf         ^If user is root: Copy httpd.conf to /orig/etc/httpd/conf/httpd.conf
   $__ :archive: -mv ~/README.txt   ^If user is not root:  Move ~/README.txt to ~/.orig/README.txt

   D=~/data                         ^Assume a.json and b.json exist in this directory
   $__ :archive: '$D/*.json'        ^If user is not root: copy ~/data/a.json and ~/data/b.json to ~/.orig/data
EOF
}

:archive:()
{
   local ___archive________Options
   ___archive________Options=$(getopt -o a:mfv0n -l "archive-dir:,move,force,verbose,no-error,dry-run" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___archive________Options"

   local ___archive________Move=false
   local ___archive________Force=false
   local ___archive________Verbose=false
   local ___archive________ArchiveDir=
   local ___archive________DryRun=false
   local ___archive________ErrorIfNotArchived=true

   while true ; do
      case "$1" in
      -a|--archive-dir) ___archive________ArchiveDir="$(readlink -fm "$2")"; shift 2;;
      -m|--move)        ___archive________Move=true; shift;;
      -f|--force)       ___archive________Force=true; shift;;
      -v|--verbose)     ___archive________Verbose=true; shift;;
      -0|--no-error)    ___archive________ErrorIfNotArchived=false; shift;;
      -n|--dry-run)     ___archive________DryRun=true; ___archive________Verbose=true; shift;;
      --)               shift; break;;
      esac
   done

   # If the user has specified an alternate archive directory, and the user isn't root,
   # then the directory must be a subdirectory of $HOME.
   local ___archive________RelativeTo
   if [[ $_whoami = root ]]; then
      [[ -n $___archive________ArchiveDir ]] || ___archive________ArchiveDir='/orig'
      ___archive________RelativeTo='/'

   else
      if [[ -n $___archive________ArchiveDir && $___archive________ArchiveDir != "$HOME"/* ]]; then
         :highlight: <<<"<b>The archive directory must be a subdirectory of:</b> <R>$HOME</R>"
         return 1
      fi
      [[ -n $___archive________ArchiveDir ]] || ___archive________ArchiveDir="$HOME/.orig"
      ___archive________RelativeTo="$HOME"
   fi

   # Set nullglob so that non-matching wildcard expansions are replaced by nothing
   :shopt:save -s nullglob globstar                      # Save shopt options then set nullglob and globstar

   local -a ___archive________SourceItems=()                           # The expanded list of arguments provided
   local ___archive________SourceItem                                  # A single path item from ___archive________SourceItems
   local ___archive________Src                                         # The full path of a ___archive________SourceItem
   local ___archive________SrcDir                                      # The directory in which ___archive________SourceItem exists
   local ___archive________Dst                                         # The full path of the location to move the $___archive________SourceItem
   local ___archive________DstExists                                   # true if $___archive________Dst exists prior to archive
   local ___archive________PerformedArchiving=1                        # 0 if paths were moved; otherwise, 1
   local ___archive________Copied=                                     # Store items copied for report emitting to stdout

   # Allow wildcards to expand
   readarray -t ___archive________SourceItems < <(
      printf '%s\n' "$@" |
      envsubst |
      sed '/^\s*$/d'
   )

   for ___archive________SourceItem in ${___archive________SourceItems[@]}; do
      # Ensure the source item exists
      if [[ ! -e $___archive________SourceItem ]]; then
         :highlight: <<<"<b>No such item:</b> <R>$___archive________SourceItem</R>"
         continue
      fi

      # First make the path to the item canonical
      ___archive________Src="$(readlink -f "$___archive________SourceItem")"

      # If non-root, the path must be within the user's HOME directory
      if [[ $_whoami != root && $___archive________Src != "$HOME"/* ]]; then
         :highlight: <<<"<b>Skipping path not under home directory:</b> <R>$___archive________SourceItem</R>"
         continue
      fi

      # Make the ___archive________Src variable canonical relative to either / for root, or $HOME for non-root users
      ___archive________Src="$(realpath --relative-to="$___archive________RelativeTo" "$___archive________Src")"

      # Specify the destination
      ___archive________Dst="$___archive________ArchiveDir/$___archive________Src"

      [[ -e $___archive________Dst ]] && ___archive________DstExists=true || ___archive________DstExists=false
      if $___archive________DstExists && ! $___archive________Force; then
         :highlight: <<<"<b>Not archived because already exists:</b> <R>$___archive________Dst</R>"
         continue
      fi

      $___archive________DryRun || mkdir -p "$___archive________ArchiveDir"

      # Perform local overlay copy
      # Note: in the future, other methods can be implemented (e.g., rsync)
      # that would allow for copying to remote servers.
      if $___archive________Verbose; then
         ___archive________Copied+="$(
            (
               cd "$___archive________RelativeTo"
               tar cpf - "$___archive________Src"
            ) |
            (
               tar tpf - |
               sed -e "s|^|   $___archive________SrcDir|" -e 's|$|^|' |
               tr '\n' $'\x01'
            )
         )"
      fi

      if ! $___archive________DryRun; then
         (
            cd "$___archive________RelativeTo"
            tar cpf - "$___archive________Src"
         ) |
         (
            cd "$___archive________ArchiveDir"
            tar xpf -
         )

         if $___archive________Move; then
            rm -rf "$___archive________Src"
         fi
      fi

      ___archive________PerformedArchiving=0
   done

   if (($___archive________PerformedArchiving == 0)) && $___archive________Verbose; then
      {
         ! $___archive________DryRun || echo '\n<h1>Dry Run</h1>'
         if $___archive________Move; then
            echo "\n<b>Move:</b>"
         else
            echo "\n<b>Copy:</b>"
         fi
         echo "$___archive________Copied" | tr $'\x01' '\n'
         echo "<b>Into:</b> <blue>$___archive________ArchiveDir</blue>"
      } | :highlight:
   fi

   :shopt:restore

   if $___archive________ErrorIfNotArchived; then
      return $___archive________PerformedArchiving
   else
      return 0
   fi
}
