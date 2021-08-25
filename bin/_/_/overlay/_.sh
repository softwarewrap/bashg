#!/bin/bash

:overlay:%HELP()
{
   local ___overlay_____HELP___Synopsis='Overlay directory with another directory'
   local ___overlay_____HELP___Usage='<source-dir> <destination-dir>'

   :help: --set "$___overlay_____HELP___Synopsis" --usage "$___overlay_____HELP___Usage" <<EOF
OPTIONS:
   -o|--owner <owner>   ^Set the owner when overlaying

DESCRIPTION:
   Overlay a source directory onto a destination directory, possibly setting ownership

EXAMPLES:
   Example here               ^: comment here
EOF
}

:overlay:()
{
   local ___overlay________Options
   ___overlay________Options=$(getopt -o '' -l 'owner:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___overlay________Options"

   local ___overlay______User="$_whoami"                            # Do not assume any owner change

   while true ; do
      case "$1" in
      --owner) ___overlay______User="$2"; shift 2;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   local -a ___overlay______CopyOptions=()
   if [[ $___overlay______User != $_whoami && $___overlay______User != root ]]; then
      if ! getent passwd "$___overlay______User" &>/dev/null; then
         :error: 1 "No such user: $___overlay______User"
      fi

      local ___overlay________Group
      ___overlay________Group="$( id -n -g "$___overlay______User" )"              # Get the corresponding group

      ___overlay______CopyOptions+=( --owner="$___overlay______User" --group="$___overlay________Group" )
   fi

   local ___overlay______Src="$1"
   local ___overlay______Dst="$2"

   if [[ ! -d $___overlay______Src || ! -d $___overlay______Dst ]]; then
      :error: 1 "Both source and destination directories must exist"
      return 1
   fi

   :overlay:_:Copy
}

:overlay:_:Copy()
{
   :sudo "$___overlay______User" || :reenter                        # This function must run as root

   (
      cd "$___overlay______Src"
      tar "$___overlay______CopyOptions" -cpf - .
   ) |
   (
      cd "$___overlay______Dst"
      tar -xpf -
   )
}
