#!/bin/bash

:localuser:matches%HELP()
{
   local ___localuser__matches__matchesHELP___Synopsis='Test if a user matches a specification'
   local ___localuser__matches__matchesHELP___Usage='<entry>'

   :help: --set "$___localuser__matches__matchesHELP___Synopsis" --usage "$___localuser__matches__matchesHELP___Usage" <<EOF
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
   The associative array <b>(++:localuser)_</b> parameter API defines the following indices:

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
   $__ :localuser:matches ftp                       ^local user ftp exists
   $__ :localuser:matches ftp/14                    ^local user ftp exists with UID=14
   $__ :localuser:matches ftp/101                   ^local user ftp exists with UID=101
   $__ :localuser:matches ftp:ftp                   ^local user ftp exists, group ftp exists
   $__ :localuser:matches ftp:ftp/301               ^local user ftp exists, group ftp exists with GID=301
   $__ :localuser:matches newuser                   ^local newuser exists
   $__ :localuser:matches newuser/5001              ^local newuser exists with UID=5001
   $__ :localuser:matches newuser/5001:team/7301    ^local newuser exists with UID=5001, group team exists with GID=7301

FILES:
   /etc/passwd    ^The password file

SEE ALSO:
   :localuser:add        ^( :help: --synopsis :localuser:add )
EOF
}

:localuser:matches()
{
   local ___localuser__matches__matches___Options
   ___localuser__matches__matches___Options=$(getopt -o 'su:g:' -l 'show,user-var:,group-var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___localuser__matches__matches___Options"

   local -a ___localuser__matches__matches___GroupVar=()                              # Options to be used with :localgroup:matches
   local ___localuser__matches__matches___UserVar=                                    # Optional: Store the associative array in this variable
   local ___localuser__matches__matches___Show=false                                  # Emit to stdout the associative array

   while true ; do
      case "$1" in
      -s|--show)        ___localuser__matches__matches___Show=true; shift;;

      -u|--user-var)    ___localuser__matches__matches___UserVar="$2"; shift 2;;
      -g|--group-var)   ___localuser__matches__matches___GroupVar+=( --group-var "$2" ); shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local ___localuser__matches__matches___Entry="$1"

   ###########################################################
   # Define Parameters Available After Calling This Function #
   ###########################################################
   ### Ensure these variables are defined with global scope
   # Cannot declare and set global: https://lists.gnu.org/archive/html/bug-bash/2013-09/msg00029.html
   [[ -v ___localuser___ ]] || local -Ag ___localuser___                       # Ensure the associative array exists

   ___localuser___=(                                                # Assign default values
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

   [[ -z $___localuser__matches__matches___UserVar ]] || :array:copy_associative ___localuser___ "$___localuser__matches__matches___UserVar"

   [[ -n $___localuser__matches__matches___Entry ]] || return 0                       # If nothing is presented, just return 0

   ### USER NAME AND ID
   local ___localuser__matches__matches___Remainder=                                  # String left to be parsed

   if [[ $___localuser__matches__matches___Entry =~ : ]]; then
      ___localuser__matches__matches___Remainder="${___localuser__matches__matches___Entry#*:}"                    # Save the content after the user information
      ___localuser__matches__matches___Entry="${___localuser__matches__matches___Entry%%:*}"                       # Save the user information
   fi

   if [[ $___localuser__matches__matches___Entry =~ / ]]; then                        # Is it necessary to parse the user information?
      ___localuser___[user_name]="${___localuser__matches__matches___Entry%%/*}"                 # Yes: Get the <user-name>
      ___localuser___[user_id]="${___localuser__matches__matches___Entry#*/}"                    # Get the <user-id>

      if [[ -z ${___localuser___[user_name]} ]]; then
         ___localuser___[status]='2'                                # Set the return status
         :error: 2 'Missing user name'                   # The <user-name> must be present
         return
      fi

      if [[ ! ${___localuser___[user_id]} =~ ^[0-9]+$ ]]; then
         ___localuser___[status]='2'                                # Set the return status
         :error: 2 "Invalid user ID: ${___localuser___[user_id]}"   # The <user-id> must be a number
         return
      fi
   else
      ___localuser___[user_name]="$___localuser__matches__matches___Entry"                       # With no <user-id>, the <user-name> is just the entry
      ___localuser___[user_id]=                                     # No required <user-id>
   fi

   ### GROUP NAME AND ID
   if [[ $___localuser__matches__matches___Remainder =~ : ]]; then
      ___localuser__matches__matches___Entry="${___localuser__matches__matches___Remainder%%:*}"                   # Save the group information
      ___localuser__matches__matches___Remainder="${___localuser__matches__matches___Remainder#*:}"                # Save the content after the group information
   else
      ___localuser__matches__matches___Entry="$___localuser__matches__matches___Remainder"
      ___localuser__matches__matches___Remainder=
   fi

   if [[ -n $___localuser__matches__matches___Remainder ]]; then
      if [[ $___localuser__matches__matches___Remainder =~ : ]]; then
         ___localuser___[supplementary_groups]="${___localuser__matches__matches___Remainder%%:*}"
         ___localuser___[password]="${___localuser__matches__matches___Remainder#*:}"
      else
         ___localuser___[supplementary_groups]="$___localuser__matches__matches___Remainder"
      fi
   fi

   ! :localgroup:matches "${___localuser__matches__matches___GroupVar[@]}" "$___localuser__matches__matches___Entry"
                                                         # Store group information and ignore return code via !

   ### What exists now?
   ___localuser___[nss_user_id]="$(                                 # Get any existing UID, either from the local /etc/passwd
      { getent passwd "${___localuser___[user_name]}" || true; } |  # or from the NSS UID. It might not exist.
      cut -d: -f3                                        # This function ensures this variable is set.
   )"

   ___localuser___[nss_group_id]="$(                                # Get any existing GID, either from the local /etc/passwd
      { getent passwd "${___localuser___[user_name]}" || true; } |  # or from the NSS GID. It might not exist.
      cut -d: -f4                                        # This function ensures this variable is set.
   )"

   ####################
   # Evaluate Matches #
   ####################
   ___localuser___[local_name_found]=false                          # Presume not in /etc/passwd
   ___localuser___[name_found]=false                                # Presume not local and not NSS
   ___localuser___[matches]=false                                   # Presume no user name and UID (if provided) match
   ___localuser___[status]=1                                        # Presume no match

   ### Test Local User
   if grep -q "^${___localuser___[user_name]}:" /etc/passwd; then   # If the entry is not in /etc/passwd, then it doesn't exist
      ___localuser___[local_name_found]=true                        # A local entry certainly does exist
      ___localuser___[name_found]=true                              # The user name exists (in this case, locally)

      if [[ -n ${___localuser___[user_id]} ]]; then                 # If spec includes UID: that will have to match as well
         if [[ ${___localuser___[nss_user_id]} -eq ${___localuser___[user_id]} ]]; then
                                                         # Check the NSS UID vs. the Spec UID
            ___localuser___[matches]=true                           # ... they both match
            ___localuser___[status]="${___localgroup___[status]}"    # Factor in group status
         fi

      else
         ___localuser___[matches]=true                              # Spec includes only user name and that does match
         ___localuser___[status]="${___localgroup___[status]}"       # Matches: no UID match requirement; factor in group status
      fi

      if [[ ${___localuser___[status]} -eq 0 ]]; then
         ___localuser___[spec_matches]=true
      fi
   fi

   ### Test NSS User
   if [[ -n ${___localuser___[nss_user_id]} ]]; then                # If both NSS and local UIDs are defined,
      ___localuser___[name_found]=true                              # The presence of the NSS UID says the user name exists

      if [[ -n ${___localuser___[user_id]} ]]; then                 # If spec includes UID: that will have to match as well
         if [[ ${___localuser___[nss_user_id]} -eq ${___localuser___[user_id]} ]]; then
                                                         # Check the NSS UID vs. the Spec UID
            ___localuser___[matches]=true                           # ... they both match (but not local: don't change Status)
         fi

      else
         ___localuser___[matches]=true                              # Spec includes only user name and that does match
      fi
   fi

   if $___localuser__matches__matches___Show; then
      :array:dump_associative ___localuser___ '<h1>User Match Results</h1>'
      :array:dump_associative ___localgroup___ '<h1>Group Match Results</h1>'
   fi

   [[ -z $___localuser__matches__matches___UserVar ]] || :array:copy_associative ___localuser___ "$___localuser__matches__matches___UserVar"

   return ${___localuser___[status]}
}
