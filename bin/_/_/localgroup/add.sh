#!/bin/bash

:localgroup:add%HELP()
{
   local ___localgroup__add__addHELP___Synopsis='Add a local group entry'
   local ___localgroup__add__addHELP___Usage=''

   :help: --set "$___localgroup__add__addHELP___Synopsis" --usage "<entry>..." <<EOF
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

   local ___localgroup__add__add___Options
   ___localgroup__add__add___Options=$(getopt -o 'n' -l 'dry-run' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___localgroup__add__add___Options"

   local ___localgroup__add__add___Perform=true
   local ___localgroup__add__add___Prefix=

   while true ; do
      case "$1" in
      -n|--dry-run)  ___localgroup__add__add___Perform=false; ___localgroup__add__add___Prefix='NOP: '; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local ___localgroup__add__add___Entry                                       # <group-name>[:<group-ID>]

   for ___localgroup__add__add___Entry in "$@"; do
      if :localgroup:matches "$___localgroup__add__add___Entry"; then                  # This function defines various parameters
         :log: "${___localgroup__add__add___Prefix}Skipping group that already exists: ${___localgroup___[group_name]}"
         continue
      fi

      grpunconv                                          # Convert /etc/gshadow -> /etc/group; remove /etc/gshadow
      :file:ensure_nl_at_end /etc/group                  # Ensure the file ends with a newline

      ### UPDATE LOCAL GROUP NAME TO HAVE NEW GID
      if grep -q "^${___localgroup___[group_name]}:" /etc/group; then
         :log: "${___localgroup__add__add___Prefix}Updated GID for ${___localgroup___[group_name]} to ${___localgroup___[group_id]}"
         $___localgroup__add__add___Perform || continue                        # If dry run, then do not make changes

         groupmod -g "${___localgroup___[group_id]}" -o "${___localgroup___[group_name]}"

      ### NSS ENTRY TO ADD LOCALLY
      elif [[ -n ${___localgroup___[nss_group_id]} ]]; then
         :log: "${___localgroup__add__add___Prefix}Adding group from network: Group: ${___localgroup___[group_name]}, GID: ${___localgroup___[group_id]}, NSS GID: ${___localgroup___[nss_group_id]}"
         $___localgroup__add__add___Perform || continue                        # If dry run, then do not make changes

         echo "${___localgroup___[group_name]}:!:${___localgroup___[group_id]}:" >>/etc/group

      ### NEW ENTRY
      else
         if [[ -n ${___localgroup___[group_id]} ]]; then
            :log: "${___localgroup__add__add___Prefix}Adding Group: ${___localgroup___[group_name]}, GID: ${___localgroup___[group_id]}"
            $___localgroup__add__add___Perform || continue                     # If dry run, then do not make changes

            groupadd -g "${___localgroup___[group_id]}" -o "${___localgroup___[group_name]}"

         else
            :log: "${___localgroup__add__add___Prefix}Adding Group: ${___localgroup___[group_name]}"
            $___localgroup__add__add___Perform || continue                     # If dry run, then do not make changes

            groupadd "${___localgroup___[group_name]}"
            ___localgroup___[group_id]="$( getent group "${___localgroup___[group_name]}" | cut -d: -f3 )"
                                                         # Store the new group ID
         fi
      fi

      grpconv                                            # Convert /etc/group -> /etc/gshadow; recreate /etc/group

      if ! :localgroup:matches "$___localgroup__add__add___Entry"; then
         :error: 2 "Failed to update local group $___localgroup__add__add___Entry"
         return
      fi
   done
}
