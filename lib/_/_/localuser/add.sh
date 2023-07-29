#!/bin/bash

+ add%HELP()
{
   local (.)_Synopsis='Add a local password entry'
   local (.)_Usage=''

   :help: --set "$(.)_Synopsis" --usage "<entry>..." <<EOF
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
   $__ (+):add myuser:mygroup                 ^Simplist case: only the required user and group are specified
   $__ (+):add myuser/123:mygroup/1234        ^A user ID and a group ID are specified
   $__ (+):add myuser:mygroup:sup1,sup2       ^Supplementary groups are specified
   $__ (+):add myuser:mygroup::My/Passwd:4u   ^No supplementary groups; password contains / and :

FILES:
   /etc/group     ^The group file
   /etc/gshadow   ^The group shadow file

SEE ALSO:
   (+):add     ^$( :help: --synopsis (+):add )
EOF
}

+ add()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o 'f:ec:n' -l 'file:,encrypted,crypt-method:,dry-run,show' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local -a (.)_Files=()
   local (.)_Encrypted=false
   local (.)_CryptMethod=
   local (-)_Perform=true
   local (-)_Prefix=
   local -a (-)_GroupOptions=()
   local -a (.)_MatchesArgs=( --user-var (-)_U --group-var (-)_G )

   while true ; do
      case "$1" in
      -f|--file)           (.)_Files+=( "$2" ); shift 2;;
      -e|--encrypted)      (.)_Encrypted=true; shift;;
      -c|--crypt-method)   (.)_CryptMethod="$2"; shift 2;;
      -n|--dry-run)        (-)_Perform=false; (-)_Prefix='NOP: '; (-)_GroupOptions+=( --dry-run ); shift;;
      --show)              (.)_MatchesArgs+=( --show ); shift;;
      --)                  shift; break;;
      *)                   break;;
      esac
   done

   local -a (.)_Entries=()

   ###########################################
   # Read <entry> Strings from Input Sources #
   ###########################################
   ### FUNCTION ARGUMENTS
   for (.)_Entry in "$@"; do
      (.)_Entries+=( "$(.)_Entry" )
   done

   ### FILES
   local (.)_File
   for (.)_File in "${(.)_Files[@]}"; do
      if [[ -f $(.)_File ]]; then
         readarray -t -O ${#(.)_Entries[@]} (.)_Entries < <(
            sed -r '/^\s*(#.*)?$/d' "$(.)_File" |        # Discard any blank lines
            sed '$a\'                                    # Ensure the output ends with a newline
         )
      fi
   done

   ### STANDARD INPUT
   if :test:has_stdin; then
      readarray -t -O ${#(.)_Entries[@]} (.)_Entries < <(
         sed -r '/^\s*(#.*)?$/d' |                       # Discard any blank lines
         sed '$a\'                                       # Ensure the output ends with a newline
      )
   fi

   #######################
   # Iterate and Process #
   #######################
   local (.)_Entry
   for (.)_Entry in "${(.)_Entries[@]}"; do
      ! :localuser:matches "${(.)_MatchesArgs[@]}" "$(.)_Entry"

      [[ ${(-)_U[status]} -ne 2 && ${(-)_G[status]} -ne 2 ]] || continue

      (-):Process
   done
}

- Process()
{

   if ! $(-)_Perform; then
      if [[ ! -v (-)_Header ]]; then
         echo 'USERNAME    /USERID   GRPNAME     /GRPID    SUPPGRPS       PASSWORD'
         echo '===================   ===================   ============   ========'
         local -g (-)_Header=true
      fi

      local -a (.)_FormatArgs=(
         '%-12s/%-6s   %-12s/%-6s   %-12s   %-s\n'
         "${(-)_U[user_name]}"
         "${(-)_U[user_id]}"
         "${(-)_G[group_name]}"
         "${(-)_G[group_id]}"
         "${(-)_U[supplementary_groups]}"
         "${(-)_U[password]:+set}"
      )

      printf "${(.)_FormatArgs[@]}"
   fi

   (-):ProcessGroupAdd
   (-):ProcessUserAdd
   (-):ProcessSupplementaryGroups
   (-):ProcessPassword
}

- ProcessGroupAdd()
{
   ! ${(-)_G[spec_matches]} || return 0                  # Just return if the group spec matches

   ### UPDATE LOCAL GROUP NAME TO HAVE NEW GID
   if grep -q "^${(-)_G[group_name]}:" /etc/group; then
      if [[ -n ${(-)_G[group_name]} && ${(-)_G[group_id]} ]]; then
         :log: "${(-)_Prefix}Updating group: ${(-)_G[group_name]}, GID: ${(-)_G[nss_group_id]} -> ${(-)_G[group_id]}"
         $(-)_Perform || return 0                        # If dry run, then do not make changes

         groupmod -g "${(-)_G[group_id]}" -o "${(-)_G[group_name]}"
      fi

   ### EXPLICIT ENTRY TO ADD GROUP LOCALLY
   elif [[ -n ${(-)_G[group_name]} && ${(-)_G[group_id]} ]]; then
      :log: "${(-)_Prefix}Adding group: ${(-)_G[group_name]}, GID: ${(-)_G[group_id]}"
      $(-)_Perform || return 0                           # If dry run, then do not make changes

      groupadd -g "${(-)_G[group_id]}" -o "${(-)_G[group_name]}"

   ### NSS ENTRY TO ADD GROUP LOCALLY
   elif [[ -n ${(-)_G[group_name]} && ${(-)_G[nss_group_id]} ]]; then
      :log: "${(-)_Prefix}Adding group: ${(-)_G[group_name]}, GID: ${(-)_G[nss_group_id]}"
      $(-)_Perform || return 0                           # If dry run, then do not make changes

      groupadd -g "${(-)_G[group_id]}" -o "${(-)_G[nss_group_name]}"

      (-)_G[group_id]="${(-)_G[nss_group_id]}"           # Update with new GID

   elif [[ -n ${(-)_U[nss_group_id]} ]]; then
      (-)_G[group_name]="$( getent group "${(-)_U[nss_group_id]}" | cut -d: -f1 )"
      (-)_G[group_id]="${(-)_U[nss_group_id]}"           # Use the NSS GID

   else
      :error: 2 "Incomplete specification for user ${(-)_U[user_name]}: Both <group-name> and <group-ID> are required"
      return
   fi

   (-)_G[nss_group_id]="${(-)_G[group_id]}"              # Update with new GID
   (-)_G[spec_matches]=true                              # Spec now matches
}

- ProcessUserAdd()
{
   ! ${(-)_U[spec_matches]} || return 0                  # If the group matches the spec, then just return 0

   ### UPDATE LOCAL USER NAME TO HAVE NEW UID/GID
   if grep -q "^${(-)_U[user_name]}:" /etc/passwd; then
      :log: "${(-)_Prefix}Updated user entry for ${(-)_U[user_name]} to ${(-)_U[user_id]}/${(-)_G[group_id]}"
      $(-)_Perform || return 0                           # If dry run, then do not make changes

      usermod -u "${(-)_U[user_id]}" -g "${(-)_G[group_id]}" -o "${(-)_U[user_name]}"

      if [[ -d /home/${(-)_U[user_name]} ]]; then
         :log: "${(-)_Prefix}Fixing permissions on files under /home/${(-)_U[user_name]}"
         chown -R "${(-)_U[user_name]}:${(-)_G[group_name]}" "/home/${(-)_U[user_name]}"
      fi

   ### EXPLICIT ENTRY TO ADD USER LOCALLY
   elif [[ -n ${(-)_U[user_id]} && -n ${(-)_G[group_id]} ]]; then
      :log: "${(-)_Prefix}Adding User: ${(-)_U[user_name]}, UID: ${(-)_U[user_id]}, GID: ${(-)_G[group_id]}"
      $(-)_Perform || return 0                           # If dry run, then do not make changes

      local -a (.)_AddOptions=(
         -u "${(-)_U[user_id]}"
         -g "${(-)_G[group_id]}"
         -o
         -d "/home/${(-)_U[user_name]}"
         -m
         -p '!!'
         -s /bin/bash
      )

      useradd "${(.)_AddOptions[@]}" "${(-)_U[user_name]}"

   ### ADD NSS USER LOCALLY
   elif [[ -n ${(-)_U[nss_user_id]} && -n ${(-)_U[nss_group_id]} ]]; then
      :log: "${(-)_Prefix}Adding User from NSS: ${(-)_U[user_name]}, UID: ${(-)_U[nss_user_id]}, GID: ${(-)_G[nss_group_id]}"
      $(-)_Perform || return 0                           # If dry run, then do not make changes

      pwunconv
      :file:ensure_nl_at_end /etc/passwd                 # Ensure the file ends with a newline
      echo "${(-)_U[user_name]}::${(-)_U[nss_user_id]}:${(-)_U[nss_group_id]}::/home/${(-)_U[user_name]}:/bin/bash" >>/etc/passwd
      pwconv                                             # Convert /etc/passwd to /etc/shadow

      if [[ ! -d /home/${(-)_U[user_name]} ]]; then
         cp -rp /etc/skel "/home/${(-)_U[user_name]}"
      fi
      chown -R "${(-)_U[user_name]}:${(-)_G[group_name]}" "/home/${(-)_U[user_name]}"

      if [[ -z ${(-)_U[password]} ]]; then
         :log: "Warning: No password has been assigned to user ${(-)_U[user_name]}"
      fi

   ### ADD NSS GROUP FOR USER WITH NO GROUP SPEC
   elif [[ -n ${(-)_G[nss_group_id]} ]]; then
      :log: "${(-)_Prefix}Adding User ${(-)_U[user_name]} with GID from NSS: ${(-)_G[nss_group_id]}"
      $(-)_Perform || return 0                           # If dry run, then do not make changes

      local -a (.)_AddOptions=(
         -g "${(-)_G[nss_group_id]}"
         -d "/home/${(-)_U[user_name]}"
         -m
         -p '!!'
         -s /bin/bash
      )

      useradd "${(.)_AddOptions[@]}" "${(-)_U[user_name]}"

      (-)_U[user_id]="$( grep "^${(-)_U[user_name]}:" /etc/passwd | cut -d: -f3 )"

      :log: "Assigned UID: ${(-)_U[user_id]}"

   else
      $(-)_Perform || return 0                           # If dry run, then do not make changes

      :error: 2 "Failed to add user: ${(-)_U[user_name]}"
      return
   fi

   if [[ -f /etc/shadow ]] &&
      grep -q "${(-)_U[user_name]}" /etc/shadow &&
      [[ -z $( grep "${(-)_U[user_name]}" /etc/shadow | cut -d: -f2 ) ]]; then

      :log: "No password set for ${(-)_U[user_name]}: locking (disabling) the password field"

      usermod -p '!!' "${(-)_U[user_name]}"
   fi

   (-)_U[nss_user_id]="${(-)_U[user_id]}"                # Update with new UID
   (-)_U[spec_matches]=true                              # Spec now matches
}

- ProcessSupplementaryGroups()
{
   [[ -n ${(-)_U[supplementary_groups]} ]] || return 0

   :log: "${(-)_Prefix}Check Supplementary Groups: ${(-)_U[supplementary_groups]}"
   $(-)_Perform || return 0                              # If dry run, then do not make changes

   usermod -a -G "${(-)_U[supplementary_groups]}" "${(-)_U[user_name]}"
}

- ProcessPassword()
{
   [[ -n ${(-)_U[password]} ]] || return 0

   :log: "${(-)_Prefix}Update password: ${(-)_U[password]}"
   $(-)_Perform || return 0                              # If dry run, then do not make changes

   chpasswd <<<"${(-)_U[user_name]}:${(-)_U[password]}"
}
