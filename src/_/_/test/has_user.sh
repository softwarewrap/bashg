#!/bin/bash

+ has_user%HELP()
{
   local (.)_Synopsis='Check if a user exists'
   local (.)_Usage='<user>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
DESCRIPTION:
   Test to see if a user exists

   If the specified <user> exists>

RETURN STATUS:
   0  ^The user exists
   1  ^The user does not exist, or a <user> is not specified

EXAMPLES:
   (+):has_user pat  ^# Returns 0 if the user <B>pat</B> exists; otherwise, 1
EOF
}

+ has_user()
{
   local (.)_User="$1"

   if [[ -n $(.)_User ]]; then
      id &>/dev/null

   else
      return 1                                           # A user must be specified
   fi
}
