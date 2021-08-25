#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Overlay directory with another directory'
   local (.)_Usage='<source-dir> <destination-dir>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
OPTIONS:
   -o|--owner <owner>   ^Set the owner when overlaying

DESCRIPTION:
   Overlay a source directory onto a destination directory, possibly setting ownership

EXAMPLES:
   Example here               ^: comment here
EOF
}

+ ()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'owner:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (-)_User="$_whoami"                            # Do not assume any owner change

   while true ; do
      case "$1" in
      --owner) (-)_User="$2"; shift 2;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   local -a (-)_CopyOptions=()
   if [[ $(-)_User != $_whoami && $(-)_User != root ]]; then
      if ! getent passwd "$(-)_User" &>/dev/null; then
         :error: 1 "No such user: $(-)_User"
      fi

      local (.)_Group
      (.)_Group="$( id -n -g "$(-)_User" )"              # Get the corresponding group

      (-)_CopyOptions+=( --owner="$(-)_User" --group="$(.)_Group" )
   fi

   local (-)_Src="$1"
   local (-)_Dst="$2"

   if [[ ! -d $(-)_Src || ! -d $(-)_Dst ]]; then
      :error: 1 "Both source and destination directories must exist"
      return 1
   fi

   (-):Copy
}

- Copy()
{
   :sudo "$(-)_User" || :reenter                        # This function must run as root

   (
      cd "$(-)_Src"
      tar "$(-)_CopyOptions" -cpf - .
   ) |
   (
      cd "$(-)_Dst"
      tar -xpf -
   )
}
