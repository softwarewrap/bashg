#!/bin/bash

:localgroup:matches%HELP()
{
   local ___localgroup__matches__matchesHELP___Synopsis='Test if a group matches a specification'
   local ___localgroup__matches__matchesHELP___Usage='<entry>'

   :help: --set "$___localgroup__matches__matchesHELP___Synopsis" --usage "$___localgroup__matches__matchesHELP___Usage" <<EOF
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
   local ___localgroup__matches__matches___Options
   ___localgroup__matches__matches___Options=$(getopt -o 'sg:' -l 'show,group-var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___localgroup__matches__matches___Options"

   local ___localgroup__matches__matches___GroupVar=                                   # Optional: Store the associative array in this variable
   local ___localgroup__matches__matches___Show=false                                  # Emit to stdout the associative array

   while true ; do
      case "$1" in
      -s|--show)        ___localgroup__matches__matches___Show=true; shift;;

      -g|--group-var)   ___localgroup__matches__matches___GroupVar="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   local ___localgroup__matches__matches___Entry="$1"

   ###########################################################
   # Define Parameters Available After Calling This Function #
   ###########################################################
   ### Ensure these variables are defined with global scope
   # Cannot declare and set global: https://lists.gnu.org/archive/html/bug-bash/2013-09/msg00029.html
   [[ -v ___localgroup___ ]] || local -Ag ___localgroup___                       # Ensure the associative array exists

   ___localgroup___=(                                                # Assign default values
      [group_name]=
      [group_id]=
      [nss_group_id]=
      [local_name_found]=false
      [name_found]=false
      [spec_matches]=false
      [matches]=false
      [status]=0
   )

   [[ -z $___localgroup__matches__matches___GroupVar ]] || :array:copy_associative ___localgroup___ "$___localgroup__matches__matches___GroupVar"

   [[ -n $___localgroup__matches__matches___Entry ]] || return 0                       # If nothing is presented, just return 0

   ### GROUP NAME AND ID
   if [[ $___localgroup__matches__matches___Entry =~ / ]]; then
      ___localgroup___[group_name]="${___localgroup__matches__matches___Entry%%/*}"                # <group-name> is extracted from the <entry>
      ___localgroup___[group_id]="${___localgroup__matches__matches___Entry#*/}"                   # Get the <group-ID>

      if [[ ! ${___localgroup___[group_id]} =~ ^[0-9]+$ ]]; then
         ___localgroup___[status]='2'
         :error: 2 "Invalid group ID: ${___localgroup___[group_id]}" # The <group-ID> must be a number
         return
      fi
   else
      ___localgroup___[group_name]="$___localgroup__matches__matches___Entry"                      # With no <group-ID>, the <group-name> is just the entry
      ___localgroup___[group_id]=                                    # No required <group-ID>
   fi

   ### What exists now?
   ___localgroup___[nss_group_id]="$(                                # Get any existing GID, either from the local /etc/group
      { getent group "${___localgroup___[group_name]}" || true; } |  # or from the NSS GID. It might not exist.
      cut -d: -f3                                        # This function ensures this variable is set.
   )"

   ####################
   # Evaluate Matches #
   ####################
   ___localgroup___[local_name_found]=false                          # Presume not in /etc/group
   ___localgroup___[name_found]=false                                # Presume not local and not NSS
   ___localgroup___[matches]=false                                   # Presume no group name and GID (if provided) match
   ___localgroup___[status]=1                                        # Presume no match

   ### Test Local Group
   if grep -q "^${___localgroup___[group_name]}:" /etc/group; then   # If the entry is in /etc/group, then a match is possible
      ___localgroup___[local_name_found]=true                        # A local entry certainly does exist
      ___localgroup___[name_found]=true                              # The group name exists (in this case, locally)

      if [[ -n ${___localgroup___[group_id]} ]]; then                # If spec includes GID: that will have to match as well
         if [[ ${___localgroup___[nss_group_id]} -eq ${___localgroup___[group_id]} ]]; then
                                                         # Check the NSS GID vs. the Spec GID
            ___localgroup___[spec_matches]=true                      # The specification matches exactly
            ___localgroup___[matches]=true                           # ... they both match
            ___localgroup___[status]=0                               # ... so, we're going to return 0
         fi

      else
         ___localgroup___[spec_matches]=true                         # The specification matches exactly
         ___localgroup___[matches]=true                              # Spec includes only group name and that does match
         ___localgroup___[status]=0                                  # Matches: no GID match requirement
      fi
   fi

   ### Test NSS Group
   if [[ -n ${___localgroup___[nss_group_id]} ]]; then               # If both NSS and local GIDs are defined,
      ___localgroup___[name_found]=true                              # The presence of the NSS GID says the group name exists

      if [[ -n ${___localgroup___[group_id]} ]]; then                # If spec includes GID: that will have to match as well
         if [[ ${___localgroup___[nss_group_id]} -eq ${___localgroup___[group_id]} ]]; then
                                                         # Check the NSS GID vs. the Spec GID
            ___localgroup___[matches]=true                           # ... they both match (but not local: don't change Status)
         fi

      else
         ___localgroup___[matches]=true                              # Spec includes only group name and that does match
      fi
   fi

   if $___localgroup__matches__matches___Show; then
      :array:dump_associative ___localgroup___ '<h1>Group Match Results</h1>'
   fi

   [[ -z $___localgroup__matches__matches___GroupVar ]] || :array:copy_associative ___localgroup___ "$___localgroup__matches__matches___GroupVar"

   return ${___localgroup___[status]}
}
