#!/bin/bash

+ matches%HELP()
{
   local (.)_Synopsis='Test if a user matches a specification'
   local (.)_Usage='<entry>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
OPTIONS:
   -s|--show         ^Show the information gathered to stdout

SCRIPTING OPTIONS:
   -u|--user-var     ^Store user information gathered in this associative array parameter
   -g|--group-var    ^Store group information gathered in this associative array parameter

DESCRIPTION:
   Test if a user matches a specification, possibly with a specified UID

   The required specification input is an <entry> of the form:

      <user-name>[/<user-id>][:<group-name>[/<group-id>]]^<K

   Names and IDs above must be valid.

RULES:
   If the <user-name> matches a specification locally, then:

      Return 0^<K
         - If the <user-name> is present locally and the <user-id> is not specified
         - If the <user-name> is present locally and the <user-id> matches the
           UID obtained via <b>getent</b>.

      Return 1^<K
         - If any of the above conditions are not met.

PARAMETERS:
   The associative array <b>\(++:localuser)_</b> parameter API defines the following indices:

      user_name         ^- The provided <user-name>
      user_id           ^- The provided <user-id>
      nss_user_id       ^- The UID obtained via <b>getent</b> and might differ from the <user-id>
      local_name_found  ^- The provided <user-name> exists locally, perhaps with a different UID or GID
      name_found        ^- The provided <user-name> exists anywhere, perhaps with a different UID or GID
      spec_matches      ^- boolean: The specification matches exactly
      matches           ^- boolean: The specification matches somewhere, but perhaps not locally
      status            ^- The return status (see: RETURN STATUS)

RETURN STATUS:
   0  ^Matches specification exactly as a local user
   1  ^Does not match specification
   2  ^Specification is invalid

EXAMPLES:
   $__ (+):matches ftp                       ^local user ftp exists
   $__ (+):matches ftp/14                    ^local user ftp exists with UID=14
   $__ (+):matches ftp/101                   ^local user ftp exists with UID=101
   $__ (+):matches ftp:ftp                   ^local user ftp exists, group ftp exists
   $__ (+):matches ftp:ftp/301               ^local user ftp exists, group ftp exists with GID=301
   $__ (+):matches newuser                   ^local newuser exists
   $__ (+):matches newuser/5001              ^local newuser exists with UID=5001
   $__ (+):matches newuser/5001:team/7301    ^local newuser exists with UID=5001, group team exists with GID=7301

FILES:
   /etc/passwd    ^The password file

SEE ALSO:
   (+):add        ^( :help: --synopsis (+):add )
EOF
}

+ matches()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'su:g:' -l 'show,user-var:,group-var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local -a (.)_GroupVar=()                              # Options to be used with :localgroup:matches
   local (.)_UserVar=                                    # Optional: Store the associative array in this variable
   local (.)_Show=false                                  # Emit to stdout the associative array

   while true ; do
      case "$1" in
      -s|--show)        (.)_Show=true; shift;;

      -u|--user-var)    (.)_UserVar="$2"; shift 2;;
      -g|--group-var)   (.)_GroupVar+=( --group-var "$2" ); shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local (.)_Entry="$1"

   ###########################################################
   # Define Parameters Available After Calling This Function #
   ###########################################################
   ### Ensure these variables are defined with global scope
   # Cannot declare and set global: https://lists.gnu.org/archive/html/bug-bash/2013-09/msg00029.html
   [[ -v (+)_ ]] || local -Ag (+)_                       # Ensure the associative array exists

   (+)_=(                                                # Assign default values
      [user_name]=
      [user_id]=
      [supplementary_groups]=
      [password]=
      [nss_user_id]=
      [nss_group_id]=
      [local_name_found]=false
      [name_found]=false
      [spec_matches]=false
      [matches]=false
      [status]=0
   )

   [[ -z $(.)_UserVar ]] || :array:copy_associative (+)_ "$(.)_UserVar"

   [[ -n $(.)_Entry ]] || return 0                       # If nothing is presented, just return 0

   ### USER NAME AND ID
   local (.)_Remainder=                                  # String left to be parsed

   if [[ $(.)_Entry =~ : ]]; then
      (.)_Remainder="${(.)_Entry#*:}"                    # Save the content after the user information
      (.)_Entry="${(.)_Entry%%:*}"                       # Save the user information
   fi

   if [[ $(.)_Entry =~ / ]]; then                        # Is it necessary to parse the user information?
      (+)_[user_name]="${(.)_Entry%%/*}"                 # Yes: Get the <user-name>
      (+)_[user_id]="${(.)_Entry#*/}"                    # Get the <user-id>

      if [[ -z ${(+)_[user_name]} ]]; then
         (+)_[status]='2'                                # Set the return status
         :error: 2 'Missing user name'                   # The <user-name> must be present
         return
      fi

      if [[ ! ${(+)_[user_id]} =~ ^[0-9]+$ ]]; then
         (+)_[status]='2'                                # Set the return status
         :error: 2 "Invalid user ID: ${(+)_[user_id]}"   # The <user-id> must be a number
         return
      fi
   else
      (+)_[user_name]="$(.)_Entry"                       # With no <user-id>, the <user-name> is just the entry
      (+)_[user_id]=                                     # No required <user-id>
   fi

   ### GROUP NAME AND ID
   if [[ $(.)_Remainder =~ : ]]; then
      (.)_Entry="${(.)_Remainder%%:*}"                   # Save the group information
      (.)_Remainder="${(.)_Remainder#*:}"                # Save the content after the group information
   else
      (.)_Entry="$(.)_Remainder"
      (.)_Remainder=
   fi

   if [[ -n $(.)_Remainder ]]; then
      if [[ $(.)_Remainder =~ : ]]; then
         (+)_[supplementary_groups]="${(.)_Remainder%%:*}"
         (+)_[password]="${(.)_Remainder#*:}"
      else
         (+)_[supplementary_groups]="$(.)_Remainder"
      fi
   fi

   ! (+:localgroup):matches "${(.)_GroupVar[@]}" "$(.)_Entry"
                                                         # Store group information and ignore return code via !

   ### What exists now?
   (+)_[nss_user_id]="$(                                 # Get any existing UID, either from the local /etc/passwd
      { getent passwd "${(+)_[user_name]}" || true; } |  # or from the NSS UID. It might not exist.
      cut -d: -f3                                        # This function ensures this variable is set.
   )"

   (+)_[nss_group_id]="$(                                # Get any existing GID, either from the local /etc/passwd
      { getent passwd "${(+)_[user_name]}" || true; } |  # or from the NSS GID. It might not exist.
      cut -d: -f4                                        # This function ensures this variable is set.
   )"

   ####################
   # Evaluate Matches #
   ####################
   (+)_[local_name_found]=false                          # Presume not in /etc/passwd
   (+)_[name_found]=false                                # Presume not local and not NSS
   (+)_[matches]=false                                   # Presume no user name and UID (if provided) match
   (+)_[status]=1                                        # Presume no match

   ### Test Local User
   if grep -q "^${(+)_[user_name]}:" /etc/passwd; then   # If the entry is not in /etc/passwd, then it doesn't exist
      (+)_[local_name_found]=true                        # A local entry certainly does exist
      (+)_[name_found]=true                              # The user name exists (in this case, locally)

      if [[ -n ${(+)_[user_id]} ]]; then                 # If spec includes UID: that will have to match as well
         if [[ ${(+)_[nss_user_id]} -eq ${(+)_[user_id]} ]]; then
                                                         # Check the NSS UID vs. the Spec UID
            (+)_[matches]=true                           # ... they both match
            (+)_[status]="${(+:localgroup)_[status]}"    # Factor in group status
         fi

      else
         (+)_[matches]=true                              # Spec includes only user name and that does match
         (+)_[status]="${(+:localgroup)_[status]}"       # Matches: no UID match requirement; factor in group status
      fi

      if [[ ${(+)_[status]} -eq 0 ]]; then
         (+)_[spec_matches]=true
      fi
   fi

   ### Test NSS User
   if [[ -n ${(+)_[nss_user_id]} ]]; then                # If both NSS and local UIDs are defined,
      (+)_[name_found]=true                              # The presence of the NSS UID says the user name exists

      if [[ -n ${(+)_[user_id]} ]]; then                 # If spec includes UID: that will have to match as well
         if [[ ${(+)_[nss_user_id]} -eq ${(+)_[user_id]} ]]; then
                                                         # Check the NSS UID vs. the Spec UID
            (+)_[matches]=true                           # ... they both match (but not local: don't change Status)
         fi

      else
         (+)_[matches]=true                              # Spec includes only user name and that does match
      fi
   fi

   if $(.)_Show; then
      :array:dump_associative (+)_ '<h1>User Match Results</h1>'
      :array:dump_associative (+:localgroup)_ '<h1>Group Match Results</h1>'
   fi

   [[ -z $(.)_UserVar ]] || :array:copy_associative (+)_ "$(.)_UserVar"

   return ${(+)_[status]}
}
