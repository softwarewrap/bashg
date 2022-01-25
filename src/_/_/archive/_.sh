#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Copy or move the paths provided to the archive path'
   local (.)_Usage='<path>...'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<'EOF'
OPTIONS:
   -a|--archive-dir <dir>  ^Specify the archive <dir> [default for users: root: /orig, others: $HOME/.orig]
   -m|--move               ^Move instead of copying
   -f|--force              ^Archive even if previously archived
   -q|--quiet              ^Do not emit warning messages
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

+ ()
{
   local (.)_Options
   (.)_Options=$(getopt -o a:mfv0n -l "archive-dir:,move,force,quiet,verbose,no-error,dry-run" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Move=false
   local (.)_Force=false
   local (.)_Quiet=false
   local (.)_Verbose=false
   local (.)_ArchiveDir=
   local (.)_DryRun=false
   local (.)_ErrorIfNotArchived=true

   while true ; do
      case "$1" in
      -a|--archive-dir) (.)_ArchiveDir="$(readlink -fm "$2")"; shift 2;;
      -m|--move)        (.)_Move=true; shift;;
      -f|--force)       (.)_Force=true; shift;;
      -q|--quiet)       (.)_Quiet=true; shift;;
      -v|--verbose)     (.)_Verbose=true; shift;;
      -0|--no-error)    (.)_ErrorIfNotArchived=false; shift;;
      -n|--dry-run)     (.)_DryRun=true; (.)_Verbose=true; shift;;
      --)               shift; break;;
      esac
   done

   # If the user has specified an alternate archive directory, and the user isn't root,
   # then the directory must be a subdirectory of $HOME.
   local (.)_RelativeTo
   if [[ $_whoami = root ]]; then
      [[ -n $(.)_ArchiveDir ]] || (.)_ArchiveDir='/orig'
      (.)_RelativeTo='/'

   else
      if [[ -n $(.)_ArchiveDir && $(.)_ArchiveDir != "$HOME"/* ]]; then
         $(.)_Quiet || :highlight: <<<"<b>The archive directory must be a subdirectory of:</b> <R>$HOME</R>"
         return 1
      fi
      [[ -n $(.)_ArchiveDir ]] || (.)_ArchiveDir="$HOME/.orig"
      (.)_RelativeTo="$HOME"
   fi

   # Set nullglob so that non-matching wildcard expansions are replaced by nothing
   :shopt:save -s nullglob globstar                      # Save shopt options then set nullglob and globstar

   local -a (.)_SourceItems=()                           # The expanded list of arguments provided
   local (.)_SourceItem                                  # A single path item from (.)_SourceItems
   local (.)_Src                                         # The full path of a (.)_SourceItem
   local (.)_SrcDir                                      # The directory in which (.)_SourceItem exists
   local (.)_Dst                                         # The full path of the location to move the $(.)_SourceItem
   local (.)_DstExists                                   # true if $(.)_Dst exists prior to archive
   local (.)_PerformedArchiving=1                        # 0 if paths were moved; otherwise, 1
   local (.)_Copied=                                     # Store items copied for report emitting to stdout

   # Allow wildcards to expand
   readarray -t (.)_SourceItems < <(
      printf '%s\n' "$@" |
      envsubst |
      sed '/^\s*$/d'
   )

   for (.)_SourceItem in ${(.)_SourceItems[@]}; do
      # Ensure the source item exists
      if [[ ! -e $(.)_SourceItem ]]; then
         $(.)_Quiet || :highlight: <<<"<b>No such item:</b> <R>$(.)_SourceItem</R>"
         continue
      fi

      # First make the path to the item canonical
      (.)_Src="$(readlink -f "$(.)_SourceItem")"

      # If non-root, the path must be within the user's HOME directory
      if [[ $_whoami != root && $(.)_Src != "$HOME"/* ]]; then
         $(.)_Quiet || :highlight: <<<"<b>Skipping path not under home directory:</b> <R>$(.)_SourceItem</R>"
         continue
      fi

      # Make the (.)_Src variable canonical relative to either / for root, or $HOME for non-root users
      (.)_Src="$(realpath --relative-to="$(.)_RelativeTo" "$(.)_Src")"

      # Specify the destination
      (.)_Dst="$(.)_ArchiveDir/$(.)_Src"

      [[ -e $(.)_Dst ]] && (.)_DstExists=true || (.)_DstExists=false
      if $(.)_DstExists && ! $(.)_Force; then
         $(.)_Quiet || :highlight: <<<"<b>Not archived because already exists:</b> <R>$(.)_Dst</R>"
         continue
      fi

      $(.)_DryRun || mkdir -p "$(.)_ArchiveDir"

      # Perform local overlay copy
      # Note: in the future, other methods can be implemented (e.g., rsync)
      # that would allow for copying to remote servers.
      if $(.)_Verbose; then
         (.)_Copied+="$(
            (
               cd "$(.)_RelativeTo"
               tar cpf - "$(.)_Src"
            ) |
            (
               tar tpf - |
               sed -e "s|^|   $(.)_SrcDir|" -e 's|$|^|' |
               tr '\n' $'\x01'
            )
         )"
      fi

      if ! $(.)_DryRun; then
         (
            cd "$(.)_RelativeTo"
            tar cpf - "$(.)_Src"
         ) |
         (
            cd "$(.)_ArchiveDir"
            tar xpf -
         )

         if $(.)_Move; then
            rm -rf "$(.)_Src"
         fi
      fi

      (.)_PerformedArchiving=0
   done

   if (($(.)_PerformedArchiving == 0)) && $(.)_Verbose; then
      {
         ! $(.)_DryRun || echo '\n<h1>Dry Run</h1>'
         if $(.)_Move; then
            echo "\n<b>Move:</b>"
         else
            echo "\n<b>Copy:</b>"
         fi
         echo "$(.)_Copied" | tr $'\x01' '\n'
         echo "<b>Into:</b> <blue>$(.)_ArchiveDir</blue>"
      } | :highlight:
   fi

   :shopt:restore

   if $(.)_ErrorIfNotArchived; then
      return $(.)_PerformedArchiving
   else
      return 0
   fi
}
