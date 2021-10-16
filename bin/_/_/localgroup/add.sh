#!/bin/bash

:localgroup:add%HELP()
{
   local __localgroup__add__addHELP___Synopsis='Add a local group entry'
   local __localgroup__add__addHELP___Usage=''

   :help: --set "$__localgroup__add__addHELP___Synopsis" --usage "<entry>..." <<EOF
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
   $__ :localgroup:add mygroup        ^Ensure group exists; create if needed with the next available GID
   $__ :localgroup:add mygroup/1234   ^Ensure group exists; create if needed with 1234 as the preferred GID

FILES:
   /etc/group     ^The group file
   /etc/gshadow   ^The group shadow file
EOF
}

:localgroup:add()
{
   :sudo || :reenter                                     # This function must run as root

   local __localgroup__add__add___Options
   __localgroup__add__add___Options=$(getopt -o 'n' -l 'dry-run' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__localgroup__add__add___Options"

   local __localgroup__add__add___Perform=true
   local __localgroup__add__add___Prefix=

   while true ; do
      case "$1" in
      -n|--dry-run)  __localgroup__add__add___Perform=false; __localgroup__add__add___Prefix='NOP: '; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local __localgroup__add__add___Entry                                       # <group-name>[:<group-ID>]

   for __localgroup__add__add___Entry in "$@"; do
      if :localgroup:matches "$__localgroup__add__add___Entry"; then                  # This function defines various parameters
         :log: "${__localgroup__add__add___Prefix}Skipping group that already exists: ${__localgroup___[group_name]}"
         continue
      fi

      grpunconv                                          # Convert /etc/gshadow -> /etc/group; remove /etc/gshadow
      :file:ensure_nl_at_end /etc/group                  # Ensure the file ends with a newline

      ### UPDATE LOCAL GROUP NAME TO HAVE NEW GID
      if grep -q "^${__localgroup___[group_name]}:" /etc/group; then
         :log: "${__localgroup__add__add___Prefix}Updated GID for ${__localgroup___[group_name]} to ${__localgroup___[group_id]}"
         $__localgroup__add__add___Perform || continue                        # If dry run, then do not make changes

         groupmod -g "${__localgroup___[group_id]}" -o "${__localgroup___[group_name]}"

      ### NSS ENTRY TO ADD LOCALLY
      elif [[ -n ${__localgroup___[nss_group_id]} ]]; then
         :log: "${__localgroup__add__add___Prefix}Adding group from network: Group: ${__localgroup___[group_name]}, GID: ${__localgroup___[group_id]}, NSS GID: ${__localgroup___[nss_group_id]}"
         $__localgroup__add__add___Perform || continue                        # If dry run, then do not make changes

         echo "${__localgroup___[group_name]}:!:${__localgroup___[group_id]}:" >>/etc/group

      ### NEW ENTRY
      else
         if [[ -n ${__localgroup___[group_id]} ]]; then
            :log: "${__localgroup__add__add___Prefix}Adding Group: ${__localgroup___[group_name]}, GID: ${__localgroup___[group_id]}"
            $__localgroup__add__add___Perform || continue                     # If dry run, then do not make changes

            groupadd -g "${__localgroup___[group_id]}" -o "${__localgroup___[group_name]}"

         else
            :log: "${__localgroup__add__add___Prefix}Adding Group: ${__localgroup___[group_name]}"
            $__localgroup__add__add___Perform || continue                     # If dry run, then do not make changes

            groupadd "${__localgroup___[group_name]}"
            __localgroup___[group_id]="$( getent group "${__localgroup___[group_name]}" | cut -d: -f3 )"
                                                         # Store the new group ID
         fi
      fi

      grpconv                                            # Convert /etc/group -> /etc/gshadow; recreate /etc/group

      if ! :localgroup:matches "$__localgroup__add__add___Entry"; then
         :error: 2 "Failed to update local group $__localgroup__add__add___Entry"
         return
      fi
   done
}
