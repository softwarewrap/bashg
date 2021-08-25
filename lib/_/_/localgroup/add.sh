#!/bin/bash

+ add%HELP()
{
   local (.)_Synopsis='Add a local group entry'
   local (.)_Usage=''

   :help: --set "$(.)_Synopsis" --usage "<entry>..." <<EOF
OPTIONS:
   -n|--dry-run                  ^Show what would be done, but do not actually make changes

DESCRIPTION:
   Add a local /etc/group entry from getent or from a specified configuration

   An <entry> is of the form:

      <group-name>[/<group-ID>]^<K

   Names and IDs above must be valid.

RULES:
   If <group-name> is already present in the local /etc/group, no action is taken.

   If <group-name> is already present in the local /etc/group, no action is taken.
   This is the only circumstance in which it is possible that a requested <group-ID> might
   be different from that of the existing <group-name>.

   If <group-name> is available via <B>getent group</B>, then that group entry is added
   to the local group file as long as any <group-id> matches the Name Service Switch (NSS)
   group ID (the network group ID).

   Otherwise, if <group-name> is not already available, then create it.
   If a <group-ID> is specified and if that ID is already used,
   then that ID is still assigned as a duplicate.

   NOTE: In the present version of this function, no error checking is performed on the values presented.

   If --dry-run is specified, then validate the inputs and show what would be done,
   but do not actually perform any additions.

EXAMPLES:
   $__ (+):add mygroup        ^Ensure group exists; create if needed with the next available GID
   $__ (+):add mygroup/1234   ^Ensure group exists; create if needed with 1234 as the preferred GID

FILES:
   /etc/group     ^The group file
   /etc/gshadow   ^The group shadow file
EOF
}

+ add()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o 'n' -l 'dry-run' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Perform=true
   local (.)_Prefix=

   while true ; do
      case "$1" in
      -n|--dry-run)  (.)_Perform=false; (.)_Prefix='NOP: '; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local (.)_Entry                                       # <group-name>[:<group-ID>]

   for (.)_Entry in "$@"; do
      if (+):matches "$(.)_Entry"; then                  # This function defines various parameters
         :log: "${(.)_Prefix}Skipping group that already exists: ${(+)_[group_name]}"
         continue
      fi

      grpunconv                                          # Convert /etc/gshadow -> /etc/group; remove /etc/gshadow
      :file:ensure_nl_at_end /etc/group                  # Ensure the file ends with a newline

      ### UPDATE LOCAL GROUP NAME TO HAVE NEW GID
      if grep -q "^${(+)_[group_name]}:" /etc/group; then
         :log: "${(.)_Prefix}Updated GID for ${(+)_[group_name]} to ${(+)_[group_id]}"
         $(.)_Perform || continue                        # If dry run, then do not make changes

         groupmod -g "${(+)_[group_id]}" -o "${(+)_[group_name]}"

      ### NSS ENTRY TO ADD LOCALLY
      elif [[ -n ${(+)_[nss_group_id]} ]]; then
         :log: "${(.)_Prefix}Adding group from network: Group: ${(+)_[group_name]}, GID: ${(+)_[group_id]}, NSS GID: ${(+)_[nss_group_id]}"
         $(.)_Perform || continue                        # If dry run, then do not make changes

         echo "${(+)_[group_name]}:!:${(+)_[group_id]}:" >>/etc/group

      ### NEW ENTRY
      else
         if [[ -n ${(+)_[group_id]} ]]; then
            :log: "${(.)_Prefix}Adding Group: ${(+)_[group_name]}, GID: ${(+)_[group_id]}"
            $(.)_Perform || continue                     # If dry run, then do not make changes

            groupadd -g "${(+)_[group_id]}" -o "${(+)_[group_name]}"

         else
            :log: "${(.)_Prefix}Adding Group: ${(+)_[group_name]}"
            $(.)_Perform || continue                     # If dry run, then do not make changes

            groupadd "${(+)_[group_name]}"
            (+)_[group_id]="$( getent group "${(+)_[group_name]}" | cut -d: -f3 )"
                                                         # Store the new group ID
         fi
      fi

      grpconv                                            # Convert /etc/group -> /etc/gshadow; recreate /etc/group

      if ! (+):matches "$(.)_Entry"; then
         :error: 2 "Failed to update local group $(.)_Entry"
         return
      fi
   done
}
