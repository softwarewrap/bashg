#!/bin/bash

:archive:%HELP()
{
   local __archive_____HELP___Synopsis='Copy or move the paths provided to the archive path'
   local __archive_____HELP___Usage='<path>...'

   :help: --set "$__archive_____HELP___Synopsis" --usage "$__archive_____HELP___Usage" <<'EOF'
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
   local __archive________Options
   __archive________Options=$(getopt -o a:mfv0n -l "archive-dir:,move,force,verbose,no-error,dry-run" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__archive________Options"

   local __archive________Move=false
   local __archive________Force=false
   local __archive________Verbose=false
   local __archive________ArchiveDir=
   local __archive________DryRun=false
   local __archive________ErrorIfNotArchived=true

   while true ; do
      case "$1" in
      -a|--archive-dir) __archive________ArchiveDir="$(readlink -fm "$2")"; shift 2;;
      -m|--move)        __archive________Move=true; shift;;
      -f|--force)       __archive________Force=true; shift;;
      -v|--verbose)     __archive________Verbose=true; shift;;
      -0|--no-error)    __archive________ErrorIfNotArchived=false; shift;;
      -n|--dry-run)     __archive________DryRun=true; __archive________Verbose=true; shift;;
      --)               shift; break;;
      esac
   done

   # If the user has specified an alternate archive directory, and the user isn't root,
   # then the directory must be a subdirectory of $HOME.
   local __archive________RelativeTo
   if [[ $_whoami = root ]]; then
      [[ -n $__archive________ArchiveDir ]] || __archive________ArchiveDir='/orig'
      __archive________RelativeTo='/'

   else
      if [[ -n $__archive________ArchiveDir && $__archive________ArchiveDir != "$HOME"/* ]]; then
         :highlight: <<<"<b>The archive directory must be a subdirectory of:</b> <R>$HOME</R>"
         return 1
      fi
      [[ -n $__archive________ArchiveDir ]] || __archive________ArchiveDir="$HOME/.orig"
      __archive________RelativeTo="$HOME"
   fi

   # Set nullglob so that non-matching wildcard expansions are replaced by nothing
   :shopt:save -s nullglob globstar                      # Save shopt options then set nullglob and globstar

   local -a __archive________SourceItems=()                           # The expanded list of arguments provided
   local __archive________SourceItem                                  # A single path item from __archive________SourceItems
   local __archive________Src                                         # The full path of a __archive________SourceItem
   local __archive________SrcDir                                      # The directory in which __archive________SourceItem exists
   local __archive________Dst                                         # The full path of the location to move the $__archive________SourceItem
   local __archive________DstExists                                   # true if $__archive________Dst exists prior to archive
   local __archive________PerformedArchiving=1                        # 0 if paths were moved; otherwise, 1
   local __archive________Copied=                                     # Store items copied for report emitting to stdout

   # Allow wildcards to expand
   readarray -t __archive________SourceItems < <(
      printf '%s\n' "$@" |
      envsubst |
      sed '/^\s*$/d'
   )

   for __archive________SourceItem in ${__archive________SourceItems[@]}; do
      # Ensure the source item exists
      if [[ ! -e $__archive________SourceItem ]]; then
         :highlight: <<<"<b>No such item:</b> <R>$__archive________SourceItem</R>"
         continue
      fi

      # First make the path to the item canonical
      __archive________Src="$(readlink -f "$__archive________SourceItem")"

      # If non-root, the path must be within the user's HOME directory
      if [[ $_whoami != root && $__archive________Src != "$HOME"/* ]]; then
         :highlight: <<<"<b>Skipping path not under home directory:</b> <R>$__archive________SourceItem</R>"
         continue
      fi

      # Make the __archive________Src variable canonical relative to either / for root, or $HOME for non-root users
      __archive________Src="$(realpath --relative-to="$__archive________RelativeTo" "$__archive________Src")"

      # Specify the destination
      __archive________Dst="$__archive________ArchiveDir/$__archive________Src"

      [[ -e $__archive________Dst ]] && __archive________DstExists=true || __archive________DstExists=false
      if $__archive________DstExists && ! $__archive________Force; then
         :highlight: <<<"<b>Not archived because already exists:</b> <R>$__archive________Dst</R>"
         continue
      fi

      $__archive________DryRun || mkdir -p "$__archive________ArchiveDir"

      # Perform local overlay copy
      # Note: in the future, other methods can be implemented (e.g., rsync)
      # that would allow for copying to remote servers.
      if $__archive________Verbose; then
         __archive________Copied+="$(
            (
               cd "$__archive________RelativeTo"
               tar cpf - "$__archive________Src"
            ) |
            (
               tar tpf - |
               sed -e "s|^|   $__archive________SrcDir|" -e 's|$|^|' |
               tr '\n' $'\x01'
            )
         )"
      fi

      if ! $__archive________DryRun; then
         (
            cd "$__archive________RelativeTo"
            tar cpf - "$__archive________Src"
         ) |
         (
            cd "$__archive________ArchiveDir"
            tar xpf -
         )

         if $__archive________Move; then
            rm -rf "$__archive________Src"
         fi
      fi

      __archive________PerformedArchiving=0
   done

   if (($__archive________PerformedArchiving == 0)) && $__archive________Verbose; then
      {
         ! $__archive________DryRun || echo '\n<h1>Dry Run</h1>'
         if $__archive________Move; then
            echo "\n<b>Move:</b>"
         else
            echo "\n<b>Copy:</b>"
         fi
         echo "$__archive________Copied" | tr $'\x01' '\n'
         echo "<b>Into:</b> <blue>$__archive________ArchiveDir</blue>"
      } | :highlight:
   fi

   :shopt:restore

   if $__archive________ErrorIfNotArchived; then
      return $__archive________PerformedArchiving
   else
      return 0
   fi
}
