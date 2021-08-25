#!/bin/bash

:localuser:add%HELP()
{
   local ___localuser__add__addHELP___Synopsis='Add a local password entry'
   local ___localuser__add__addHELP___Usage=''

   :help: --set "$___localuser__add__addHELP___Synopsis" --usage "<entry>..." <<EOF
OPTIONS:
   -f|--file <file>              ^Read one <entry> per line from the specified <file>
   -e|--encrypted                ^Any passwords provided are taken to be already encrypted
   -c|--crypt-method <method>    ^Use the specified method to encrypt any passwords provided
   -n|--dry-run                  ^Show what would be done, but do not actually make changes

   --show                        ^Show user and group matching data

DESCRIPTION:
   Add a local /etc/passwd entry from getent or from a specified configuration

   Read <entry> strings from the following sources in the order shown below:

      1. Read from function arguments, where each argument is a full <entry> string.
      2. Read from a <file>, if specified, one <entry> per line.
         Multiple uses of --file are permitted and are read in the order presented.
      3. Read from stdin, one <entry> per line.

   An <entry> is of the form:

      <user-name>[/<user-ID>]:<group-name>[/<group-ID>][:[<supplementary-group-names>][:<password>]]

   All names above must be valid names. Optional sections are enclosed by the <b>[ ]</b> characters.

RULES:
   If <user-name> is already in /etc/passwd, no action is taken.

   If <user-name> is available via <B>getent passwd</B>, then that passwd entry is added
   to the local passwd file.

   If <user-name> is not available, then newly create it.

   If a <group-name> is specified and if that name is not used locally, then that group name is created.

   If when creating a group name, <group-ID> is specified and that ID is not used locally,
   then that ID is assigned to the <group-name>; otherwise, the next available iD is assigned.

   If <supplementary-group-names> are provided as a comma-separated list of group names,
   the user will become a member of the listed supplementary group names.

   If <password> is provided, then it is taken to be all characters until the end of line.
   If --encrypted is specified, then the supplied passwords are taken to be in encrypted form.
   If --crypt-method is specified, then <method> is used to encrypt the passwords.
   The available methods are <b>DES</b>, <b>MD5</b>, <b>NONE</b>, and <b>SHA256</b> or <b>SHA512</b> if your libc support these methods.
   If the <password> begins with one or more spaces, then this is taken to indicate that the password
   is encrypted and the password begins with the first non-space character. This allows mixing encrypted
   and non-encrypted passwords in the input sources.

   Notes:
      - If either the <supplementary-group-names> or a <password> is wanted, the colon delimiter is required.
      - While the colon is a delimiter for fields before the password field, once in the password
        field, it is not a delimter so can be a part of a password.
      - In the present version of this function, minimal error checking is performed on the values presented.

   If --dry-run is specified, then validate the inputs and show what would be done,
   but do not actually perform any additions.

EXAMPLES:
   $__ :localuser:add myuser:mygroup                 ^Simplist case: only the required user and group are specified
   $__ :localuser:add myuser/123:mygroup/1234        ^A user ID and a group ID are specified
   $__ :localuser:add myuser:mygroup:sup1,sup2       ^Supplementary groups are specified
   $__ :localuser:add myuser:mygroup::My/Passwd:4u   ^No supplementary groups; password contains / and :

FILES:
   /etc/group     ^The group file
   /etc/gshadow   ^The group shadow file

SEE ALSO:
   :localuser:add     ^$( :help: --synopsis :localuser:add )
EOF
}

:localuser:add()
{
   :sudo || :reenter                                     # This function must run as root

   local ___localuser__add__add___Options
   ___localuser__add__add___Options=$(getopt -o 'f:ec:n' -l 'file:,encrypted,crypt-method:,dry-run,show' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___localuser__add__add___Options"

   local -a ___localuser__add__add___Files=()
   local ___localuser__add__add___Encrypted=false
   local ___localuser__add__add___CryptMethod=
   local ___localuser__add___Perform=true
   local ___localuser__add___Prefix=
   local -a ___localuser__add___GroupOptions=()
   local -a ___localuser__add__add___MatchesArgs=( --user-var ___localuser__add___U --group-var ___localuser__add___G )

   while true ; do
      case "$1" in
      -f|--file)           ___localuser__add__add___Files+=( "$2" ); shift 2;;
      -e|--encrypted)      ___localuser__add__add___Encrypted=true; shift;;
      -c|--crypt-method)   ___localuser__add__add___CryptMethod="$2"; shift 2;;
      -n|--dry-run)        ___localuser__add___Perform=false; ___localuser__add___Prefix='NOP: '; ___localuser__add___GroupOptions+=( --dry-run ); shift;;
      --show)              ___localuser__add__add___MatchesArgs+=( --show ); shift;;
      --)                  shift; break;;
      *)                   break;;
      esac
   done

   local -a ___localuser__add__add___Entries=()

   ###########################################
   # Read <entry> Strings from Input Sources #
   ###########################################
   ### FUNCTION ARGUMENTS
   for ___localuser__add__add___Entry in "$@"; do
      ___localuser__add__add___Entries+=( "$___localuser__add__add___Entry" )
   done

   ### FILES
   local ___localuser__add__add___File
   for ___localuser__add__add___File in "${___localuser__add__add___Files[@]}"; do
      if [[ -f $___localuser__add__add___File ]]; then
         readarray -t -O ${#___localuser__add__add___Entries[@]} ___localuser__add__add___Entries < <(
            sed -r '/^\s*(#.*)?$/d' "$___localuser__add__add___File" |        # Discard any blank lines
            sed '$a\'                                    # Ensure the output ends with a newline
         )
      fi
   done

   ### STANDARD INPUT
   if :test:has_stdin; then
      readarray -t -O ${#___localuser__add__add___Entries[@]} ___localuser__add__add___Entries < <(
         sed -r '/^\s*(#.*)?$/d' |                       # Discard any blank lines
         sed '$a\'                                       # Ensure the output ends with a newline
      )
   fi

   #######################
   # Iterate and Process #
   #######################
   local ___localuser__add__add___Entry
   for ___localuser__add__add___Entry in "${___localuser__add__add___Entries[@]}"; do
      ! :localuser:matches "${___localuser__add__add___MatchesArgs[@]}" "$___localuser__add__add___Entry"

      [[ ${___localuser__add___U[status]} -ne 2 && ${___localuser__add___G[status]} -ne 2 ]] || continue

      :localuser:add:Process
   done
}

:localuser:add:Process()
{

   if ! $___localuser__add___Perform; then
      if [[ ! -v ___localuser__add___Header ]]; then
         echo 'USERNAME    /USERID   GRPNAME     /GRPID    SUPPGRPS       PASSWORD'
         echo '===================   ===================   ============   ========'
         local -g ___localuser__add___Header=true
      fi

      local -a ___localuser__add__Process___FormatArgs=(
         '%-12s/%-6s   %-12s/%-6s   %-12s   %-s\n'
         "${___localuser__add___U[user_name]}"
         "${___localuser__add___U[user_id]}"
         "${___localuser__add___G[group_name]}"
         "${___localuser__add___G[group_id]}"
         "${___localuser__add___U[supplementary_groups]}"
         "${___localuser__add___U[password]:+set}"
      )

      printf "${___localuser__add__Process___FormatArgs[@]}"
   fi

   :localuser:add:ProcessGroupAdd
   :localuser:add:ProcessUserAdd
   :localuser:add:ProcessSupplementaryGroups
   :localuser:add:ProcessPassword
}

:localuser:add:ProcessGroupAdd()
{
   ! ${___localuser__add___G[spec_matches]} || return 0                  # Just return if the group spec matches

   ### UPDATE LOCAL GROUP NAME TO HAVE NEW GID
   if grep -q "^${___localuser__add___G[group_name]}:" /etc/group; then
      if [[ -n ${___localuser__add___G[group_name]} && ${___localuser__add___G[group_id]} ]]; then
         :log: "${___localuser__add___Prefix}Updating group: ${___localuser__add___G[group_name]}, GID: ${___localuser__add___G[nss_group_id]} -> ${___localuser__add___G[group_id]}"
         $___localuser__add___Perform || return 0                        # If dry run, then do not make changes

         groupmod -g "${___localuser__add___G[group_id]}" -o "${___localuser__add___G[group_name]}"
      fi

   ### EXPLICIT ENTRY TO ADD GROUP LOCALLY
   elif [[ -n ${___localuser__add___G[group_name]} && ${___localuser__add___G[group_id]} ]]; then
      :log: "${___localuser__add___Prefix}Adding group: ${___localuser__add___G[group_name]}, GID: ${___localuser__add___G[group_id]}"
      $___localuser__add___Perform || return 0                           # If dry run, then do not make changes

      groupadd -g "${___localuser__add___G[group_id]}" -o "${___localuser__add___G[group_name]}"

   ### NSS ENTRY TO ADD GROUP LOCALLY
   elif [[ -n ${___localuser__add___G[group_name]} && ${___localuser__add___G[nss_group_id]} ]]; then
      :log: "${___localuser__add___Prefix}Adding group: ${___localuser__add___G[group_name]}, GID: ${___localuser__add___G[nss_group_id]}"
      $___localuser__add___Perform || return 0                           # If dry run, then do not make changes

      groupadd -g "${___localuser__add___G[group_id]}" -o "${___localuser__add___G[nss_group_name]}"

      ___localuser__add___G[group_id]="${___localuser__add___G[nss_group_id]}"           # Update with new GID

   elif [[ -n ${___localuser__add___U[nss_group_id]} ]]; then
      ___localuser__add___G[group_name]="$( getent group "${___localuser__add___U[nss_group_id]}" | cut -d: -f1 )"
      ___localuser__add___G[group_id]="${___localuser__add___U[nss_group_id]}"           # Use the NSS GID

   else
      :error: 2 "Incomplete specification for user ${___localuser__add___U[user_name]}: Both <group-name> and <group-ID> are required"
      return
   fi

   ___localuser__add___G[nss_group_id]="${___localuser__add___G[group_id]}"              # Update with new GID
   ___localuser__add___G[spec_matches]=true                              # Spec now matches
}

:localuser:add:ProcessUserAdd()
{
   ! ${___localuser__add___U[spec_matches]} || return 0                  # If the group matches the spec, then just return 0

   ### UPDATE LOCAL USER NAME TO HAVE NEW UID/GID
   if grep -q "^${___localuser__add___U[user_name]}:" /etc/passwd; then
      :log: "${___localuser__add___Prefix}Updated user entry for ${___localuser__add___U[user_name]} to ${___localuser__add___U[user_id]}/${___localuser__add___G[group_id]}"
      $___localuser__add___Perform || return 0                           # If dry run, then do not make changes

      usermod -u "${___localuser__add___U[user_id]}" -g "${___localuser__add___G[group_id]}" -o "${___localuser__add___U[user_name]}"

      if [[ -d /home/${___localuser__add___U[user_name]} ]]; then
         :log: "${___localuser__add___Prefix}Fixing permissions on files under /home/${___localuser__add___U[user_name]}"
         chown -R "${___localuser__add___U[user_name]}:${___localuser__add___G[group_name]}" "/home/${___localuser__add___U[user_name]}"
      fi

   ### EXPLICIT ENTRY TO ADD USER LOCALLY
   elif [[ -n ${___localuser__add___U[user_id]} && -n ${___localuser__add___G[group_id]} ]]; then
      :log: "${___localuser__add___Prefix}Adding User: ${___localuser__add___U[user_name]}, UID: ${___localuser__add___U[user_id]}, GID: ${___localuser__add___G[group_id]}"
      $___localuser__add___Perform || return 0                           # If dry run, then do not make changes

      local -a ___localuser__add__ProcessUserAdd___AddOptions=(
         -u "${___localuser__add___U[user_id]}"
         -g "${___localuser__add___G[group_id]}"
         -o
         -d "/home/${___localuser__add___U[user_name]}"
         -m
         -s /bin/bash
      )

      useradd "${___localuser__add__ProcessUserAdd___AddOptions[@]}" "${___localuser__add___U[user_name]}"

   ### ADD NSS USER LOCALLY
   elif [[ -n ${___localuser__add___U[nss_user_id]} && -n ${___localuser__add___U[nss_group_id]} ]]; then
      :log: "${___localuser__add___Prefix}Adding User from NSS: ${___localuser__add___U[user_name]}, UID: ${___localuser__add___U[nss_user_id]}, GID: ${___localuser__add___G[nss_group_id]}"
      $___localuser__add___Perform || return 0                           # If dry run, then do not make changes

      pwunconv
      :file:ensure_nl_at_end /etc/passwd                 # Ensure the file ends with a newline
      echo "${___localuser__add___U[user_name]}::${___localuser__add___U[nss_user_id]}:${___localuser__add___U[nss_group_id]}::/home/${___localuser__add___U[user_name]}:/bin/bash" >>/etc/passwd
      pwconv                                             # Convert /etc/passwd to /etc/shadow

      if [[ ! -d /home/${___localuser__add___U[user_name]} ]]; then
         cp -rp /etc/skel "/home/${___localuser__add___U[user_name]}"
      fi
      chown -R "${___localuser__add___U[user_name]}:${___localuser__add___G[group_name]}" "/home/${___localuser__add___U[user_name]}"

      if [[ -z ${___localuser__add___U[password]} ]]; then
         :log: "Warning: No password has been assigned to user ${___localuser__add___U[user_name]}"
      fi

   ### ADD NSS GROUP FOR USER WITH NO GROUP SPEC
   elif [[ -n ${___localuser__add___G[nss_group_id]} ]]; then
      :log: "${___localuser__add___Prefix}Adding User ${___localuser__add___U[user_name]} with GID from NSS: ${___localuser__add___G[nss_group_id]}"
      $___localuser__add___Perform || return 0                           # If dry run, then do not make changes

      local -a ___localuser__add__ProcessUserAdd___AddOptions=(
         -g "${___localuser__add___G[nss_group_id]}"
         -d "/home/${___localuser__add___U[user_name]}"
         -m
         -s /bin/bash
      )

      useradd "${___localuser__add__ProcessUserAdd___AddOptions[@]}" "${___localuser__add___U[user_name]}"

      ___localuser__add___U[user_id]="$( grep "^${___localuser__add___U[user_name]}:" /etc/passwd | cut -d: -f3 )"

      :log: "Assigned UID: ${___localuser__add___U[user_id]}"

   else
      $___localuser__add___Perform || return 0                           # If dry run, then do not make changes

      :error: 2 "Failed to add user: ${___localuser__add___U[user_name]}"
      return
   fi

   ___localuser__add___U[nss_user_id]="${___localuser__add___U[user_id]}"                # Update with new UID
   ___localuser__add___U[spec_matches]=true                              # Spec now matches
}

:localuser:add:ProcessSupplementaryGroups()
{
   [[ -n ${___localuser__add___U[supplementary_groups]} ]] || return 0

   :log: "${___localuser__add___Prefix}Check Supplementary Groups: ${___localuser__add___U[supplementary_groups]}"
   $___localuser__add___Perform || return 0                              # If dry run, then do not make changes

   usermod -a -G "${___localuser__add___U[supplementary_groups]}" "${___localuser__add___U[user_name]}"
}

:localuser:add:ProcessPassword()
{
   [[ -n ${___localuser__add___U[password]} ]] || return 0

   :log: "${___localuser__add___Prefix}Update password: ${___localuser__add___U[password]}"
   $___localuser__add___Perform || return 0                              # If dry run, then do not make changes

   chpasswd <<<"${___localuser__add___U[user_name]}:${___localuser__add___U[password]}"
}
