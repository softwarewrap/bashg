#!/bin/bash

:test:has_user%HELP()
{
   local __test__has_user__has_userHELP___Synopsis='Check if a user exists'
   local __test__has_user__has_userHELP___Usage='<user>'

   :help: --set "$__test__has_user__has_userHELP___Synopsis" --usage "$__test__has_user__has_userHELP___Usage" <<EOF
DESCRIPTION:
   Test to see if a user exists

   If the specified <user> exists>

RETURN STATUS:
   0  ^The user exists
   1  ^The user does not exist, or a <user> is not specified

EXAMPLES:
   :test:has_user pat  ^# Returns 0 if the user <B>pat</B> exists; otherwise, 1
EOF
}

:test:has_user()
{
   local __test__has_user__has_user___User="$1"

   if [[ -n $__test__has_user__has_user___User ]]; then
      id &>/dev/null

   else
      return 1                                           # A user must be specified
   fi
}
