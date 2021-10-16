#!/bin/bash

:localgroup:matches%HELP()
{
   local __localgroup__matches__matchesHELP___Synopsis='Test if a group matches a specification'
   local __localgroup__matches__matchesHELP___Usage='<entry>'

   :help: --set "$__localgroup__matches__matchesHELP___Synopsis" --usage "$__localgroup__matches__matchesHELP___Usage" <<EOF
OPTIONS:
   -s|--show         ^Show the information gathered to stdout

SCRIPTING OPTIONS:
   -g|--group-var    ^Store group information gathered in this associative array parameter

DESCRIPTION:
   Test if a group matches a specification, possibly with a specified GID

   The required input is an <entry> of the form:

      <group-name>[/<group-ID>]^<K

   Names and IDs above must be valid.

RULES:
   If the <group-name> matches a specification locally, then:

      Return 0^<K
         - If the <group-name> is present locally and the <group-ID> is not specified
         - If the <group-name> is present locally and the <group-ID> matches the
           GID obtained via <b>getent</b>.

      Return 1^<K
         - If any of the above conditions are not met.

PARAMETERS:
   The associative array <b>(++:localgroup)_</b> parameter API defines the following indices:

      group_name        ^- The provided <group-name>
      group_id          ^- The provided <group-ID>
      nss_group_id      ^- The GID obtained via <b>getent</b> and might differ from the <group-ID>
      local_name_found  ^- boolean: The provided <group-name> exists locally, perhaps with a different GID
      name_found        ^- boolean: The provided <group-name> exists anywhere, perhaps with a different GID
      spec_matches      ^- boolean: The specification matches exactly
      matches           ^- boolean: The specification matches somewhere, but perhaps not locally
      status            ^- The return status (see: RETURN STATUS)

RETURN STATUS:
   0  ^Matches specification exactly as a local group
   1  ^Does not match specification
   2  ^Specification is invalid

EXAMPLES:
   $__ :localgroup:matches users         ^Test if the users group matches with any GID
   $__ :localgroup:matches users/100     ^Test if the users group matches with the GID of 100 (typically true)
   $__ :localgroup:matches users/101     ^Test if the users group matches with the GID of 101 (typically false)
   $__ :localgroup:matches newgrp        ^Test if the newgrp matches with any GID
   $__ :localgroup:matches newgrp/5001   ^Test if the newgrp matches with the GID of 5001

FILES:
   /etc/group     ^The group file

SEE ALSO:
   :localgroup:add        ^$( :help: --synopsis :localgroup:add )
EOF
}

:localgroup:matches()
{
   local __localgroup__matches__matches___Options
   __localgroup__matches__matches___Options=$(getopt -o 'sg:' -l 'show,group-var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__localgroup__matches__matches___Options"

   local __localgroup__matches__matches___GroupVar=                                   # Optional: Store the associative array in this variable
   local __localgroup__matches__matches___Show=false                                  # Emit to stdout the associative array

   while true ; do
      case "$1" in
      -s|--show)        __localgroup__matches__matches___Show=true; shift;;

      -g|--group-var)   __localgroup__matches__matches___GroupVar="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local __localgroup__matches__matches___Entry="$1"

   ###########################################################
   # Define Parameters Available After Calling This Function #
   ###########################################################
   ### Ensure these variables are defined with global scope
   # Cannot declare and set global: https://lists.gnu.org/archive/html/bug-bash/2013-09/msg00029.html
   [[ -v __localgroup___ ]] || local -Ag __localgroup___                       # Ensure the associative array exists

   __localgroup___=(                                                # Assign default values
      [group_name]=
      [group_id]=
      [nss_group_id]=
      [local_name_found]=false
      [name_found]=false
      [spec_matches]=false
      [matches]=false
      [status]=0
   )

   [[ -z $__localgroup__matches__matches___GroupVar ]] || :array:copy_associative __localgroup___ "$__localgroup__matches__matches___GroupVar"

   [[ -n $__localgroup__matches__matches___Entry ]] || return 0                       # If nothing is presented, just return 0

   ### GROUP NAME AND ID
   if [[ $__localgroup__matches__matches___Entry =~ / ]]; then
      __localgroup___[group_name]="${__localgroup__matches__matches___Entry%%/*}"                # <group-name> is extracted from the <entry>
      __localgroup___[group_id]="${__localgroup__matches__matches___Entry#*/}"                   # Get the <group-ID>

      if [[ ! ${__localgroup___[group_id]} =~ ^[0-9]+$ ]]; then
         __localgroup___[status]='2'
         :error: 2 "Invalid group ID: ${__localgroup___[group_id]}" # The <group-ID> must be a number
         return
      fi
   else
      __localgroup___[group_name]="$__localgroup__matches__matches___Entry"                      # With no <group-ID>, the <group-name> is just the entry
      __localgroup___[group_id]=                                    # No required <group-ID>
   fi

   ### What exists now?
   __localgroup___[nss_group_id]="$(                                # Get any existing GID, either from the local /etc/group
      { getent group "${__localgroup___[group_name]}" || true; } |  # or from the NSS GID. It might not exist.
      cut -d: -f3                                        # This function ensures this variable is set.
   )"

   ####################
   # Evaluate Matches #
   ####################
   __localgroup___[local_name_found]=false                          # Presume not in /etc/group
   __localgroup___[name_found]=false                                # Presume not local and not NSS
   __localgroup___[matches]=false                                   # Presume no group name and GID (if provided) match
   __localgroup___[status]=1                                        # Presume no match

   ### Test Local Group
   if grep -q "^${__localgroup___[group_name]}:" /etc/group; then   # If the entry is in /etc/group, then a match is possible
      __localgroup___[local_name_found]=true                        # A local entry certainly does exist
      __localgroup___[name_found]=true                              # The group name exists (in this case, locally)

      if [[ -n ${__localgroup___[group_id]} ]]; then                # If spec includes GID: that will have to match as well
         if [[ ${__localgroup___[nss_group_id]} -eq ${__localgroup___[group_id]} ]]; then
                                                         # Check the NSS GID vs. the Spec GID
            __localgroup___[spec_matches]=true                      # The specification matches exactly
            __localgroup___[matches]=true                           # ... they both match
            __localgroup___[status]=0                               # ... so, we're going to return 0
         fi

      else
         __localgroup___[spec_matches]=true                         # The specification matches exactly
         __localgroup___[matches]=true                              # Spec includes only group name and that does match
         __localgroup___[status]=0                                  # Matches: no GID match requirement
      fi
   fi

   ### Test NSS Group
   if [[ -n ${__localgroup___[nss_group_id]} ]]; then               # If both NSS and local GIDs are defined,
      __localgroup___[name_found]=true                              # The presence of the NSS GID says the group name exists

      if [[ -n ${__localgroup___[group_id]} ]]; then                # If spec includes GID: that will have to match as well
         if [[ ${__localgroup___[nss_group_id]} -eq ${__localgroup___[group_id]} ]]; then
                                                         # Check the NSS GID vs. the Spec GID
            __localgroup___[matches]=true                           # ... they both match (but not local: don't change Status)
         fi

      else
         __localgroup___[matches]=true                              # Spec includes only group name and that does match
      fi
   fi

   if $__localgroup__matches__matches___Show; then
      :array:dump_associative __localgroup___ '<h1>Group Match Results</h1>'
   fi

   [[ -z $__localgroup__matches__matches___GroupVar ]] || :array:copy_associative __localgroup___ "$__localgroup__matches__matches___GroupVar"

   return ${__localgroup___[status]}
}
