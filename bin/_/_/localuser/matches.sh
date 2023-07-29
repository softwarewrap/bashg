#!/bin/bash

:localuser:matches%HELP()
{
   local __localuser__matches__matchesHELP___Synopsis='Test if a user matches a specification'
   local __localuser__matches__matchesHELP___Usage='<entry>'

   :help: --set "$__localuser__matches__matchesHELP___Synopsis" --usage "$__localuser__matches__matchesHELP___Usage" <<EOF
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
   local __localuser__matches__matches___Options
   __localuser__matches__matches___Options=$(getopt -o 'su:g:' -l 'show,user-var:,group-var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__localuser__matches__matches___Options"

   local -a __localuser__matches__matches___GroupVar=()                              # Options to be used with :localgroup:matches
   local __localuser__matches__matches___UserVar=                                    # Optional: Store the associative array in this variable
   local __localuser__matches__matches___Show=false                                  # Emit to stdout the associative array

   while true ; do
      case "$1" in
      -s|--show)        __localuser__matches__matches___Show=true; shift;;

      -u|--user-var)    __localuser__matches__matches___UserVar="$2"; shift 2;;
      -g|--group-var)   __localuser__matches__matches___GroupVar+=( --group-var "$2" ); shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local __localuser__matches__matches___Entry="$1"

   ###########################################################
   # Define Parameters Available After Calling This Function #
   ###########################################################
   ### Ensure these variables are defined with global scope
   # Cannot declare and set global: https://lists.gnu.org/archive/html/bug-bash/2013-09/msg00029.html
   [[ -v __localuser___ ]] || local -Ag __localuser___                       # Ensure the associative array exists

   __localuser___=(                                                # Assign default values
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

   [[ -z $__localuser__matches__matches___UserVar ]] || :array:copy_associative __localuser___ "$__localuser__matches__matches___UserVar"

   [[ -n $__localuser__matches__matches___Entry ]] || return 0                       # If nothing is presented, just return 0

   ### USER NAME AND ID
   local __localuser__matches__matches___Remainder=                                  # String left to be parsed

   if [[ $__localuser__matches__matches___Entry =~ : ]]; then
      __localuser__matches__matches___Remainder="${__localuser__matches__matches___Entry#*:}"                    # Save the content after the user information
      __localuser__matches__matches___Entry="${__localuser__matches__matches___Entry%%:*}"                       # Save the user information
   fi

   if [[ $__localuser__matches__matches___Entry =~ / ]]; then                        # Is it necessary to parse the user information?
      __localuser___[user_name]="${__localuser__matches__matches___Entry%%/*}"                 # Yes: Get the <user-name>
      __localuser___[user_id]="${__localuser__matches__matches___Entry#*/}"                    # Get the <user-id>

      if [[ -z ${__localuser___[user_name]} ]]; then
         __localuser___[status]='2'                                # Set the return status
         :error: 2 'Missing user name'                   # The <user-name> must be present
         return
      fi

      if [[ ! ${__localuser___[user_id]} =~ ^[0-9]+$ ]]; then
         __localuser___[status]='2'                                # Set the return status
         :error: 2 "Invalid user ID: ${__localuser___[user_id]}"   # The <user-id> must be a number
         return
      fi
   else
      __localuser___[user_name]="$__localuser__matches__matches___Entry"                       # With no <user-id>, the <user-name> is just the entry
      __localuser___[user_id]=                                     # No required <user-id>
   fi

   ### GROUP NAME AND ID
   if [[ $__localuser__matches__matches___Remainder =~ : ]]; then
      __localuser__matches__matches___Entry="${__localuser__matches__matches___Remainder%%:*}"                   # Save the group information
      __localuser__matches__matches___Remainder="${__localuser__matches__matches___Remainder#*:}"                # Save the content after the group information
   else
      __localuser__matches__matches___Entry="$__localuser__matches__matches___Remainder"
      __localuser__matches__matches___Remainder=
   fi

   if [[ -n $__localuser__matches__matches___Remainder ]]; then
      if [[ $__localuser__matches__matches___Remainder =~ : ]]; then
         __localuser___[supplementary_groups]="${__localuser__matches__matches___Remainder%%:*}"
         __localuser___[password]="${__localuser__matches__matches___Remainder#*:}"
      else
         __localuser___[supplementary_groups]="$__localuser__matches__matches___Remainder"
      fi
   fi

   ! :localgroup:matches "${__localuser__matches__matches___GroupVar[@]}" "$__localuser__matches__matches___Entry"
                                                         # Store group information and ignore return code via !

   ### What exists now?
   __localuser___[nss_user_id]="$(                                 # Get any existing UID, either from the local /etc/passwd
      { getent passwd "${__localuser___[user_name]}" || true; } |  # or from the NSS UID. It might not exist.
      cut -d: -f3                                        # This function ensures this variable is set.
   )"

   __localuser___[nss_group_id]="$(                                # Get any existing GID, either from the local /etc/passwd
      { getent passwd "${__localuser___[user_name]}" || true; } |  # or from the NSS GID. It might not exist.
      cut -d: -f4                                        # This function ensures this variable is set.
   )"

   ####################
   # Evaluate Matches #
   ####################
   __localuser___[local_name_found]=false                          # Presume not in /etc/passwd
   __localuser___[name_found]=false                                # Presume not local and not NSS
   __localuser___[matches]=false                                   # Presume no user name and UID (if provided) match
   __localuser___[status]=1                                        # Presume no match

   ### Test Local User
   if grep -q "^${__localuser___[user_name]}:" /etc/passwd; then   # If the entry is not in /etc/passwd, then it doesn't exist
      __localuser___[local_name_found]=true                        # A local entry certainly does exist
      __localuser___[name_found]=true                              # The user name exists (in this case, locally)

      if [[ -n ${__localuser___[user_id]} ]]; then                 # If spec includes UID: that will have to match as well
         if [[ ${__localuser___[nss_user_id]} -eq ${__localuser___[user_id]} ]]; then
                                                         # Check the NSS UID vs. the Spec UID
            __localuser___[matches]=true                           # ... they both match
            __localuser___[status]="${__localgroup___[status]}"    # Factor in group status
         fi

      else
         __localuser___[matches]=true                              # Spec includes only user name and that does match
         __localuser___[status]="${__localgroup___[status]}"       # Matches: no UID match requirement; factor in group status
      fi

      if [[ ${__localuser___[status]} -eq 0 ]]; then
         __localuser___[spec_matches]=true
      fi
   fi

   ### Test NSS User
   if [[ -n ${__localuser___[nss_user_id]} ]]; then                # If both NSS and local UIDs are defined,
      __localuser___[name_found]=true                              # The presence of the NSS UID says the user name exists

      if [[ -n ${__localuser___[user_id]} ]]; then                 # If spec includes UID: that will have to match as well
         if [[ ${__localuser___[nss_user_id]} -eq ${__localuser___[user_id]} ]]; then
                                                         # Check the NSS UID vs. the Spec UID
            __localuser___[matches]=true                           # ... they both match (but not local: don't change Status)
         fi

      else
         __localuser___[matches]=true                              # Spec includes only user name and that does match
      fi
   fi

   if $__localuser__matches__matches___Show; then
      :array:dump_associative __localuser___ '<h1>User Match Results</h1>'
      :array:dump_associative __localgroup___ '<h1>Group Match Results</h1>'
   fi

   [[ -z $__localuser__matches__matches___UserVar ]] || :array:copy_associative __localuser___ "$__localuser__matches__matches___UserVar"

   return ${__localuser___[status]}
}
