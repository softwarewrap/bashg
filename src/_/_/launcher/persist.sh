#!/bin/bash

+ persist%HELP()
{
   local (.)_Synopsis='Persist variables'
   local (.)_Usage='<variable>...'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
DESCRIPTION:
   Persist variables so they exist when <B>:sudo [<user>] || :reenter</B> is used.

   The idiom shown above requires the framework to call $__ as the altered user.
   Variables are not available to the reentered function unless they are persisted
   by using this function.

   Notes:
      This function must be called before invoking the above idiom.

      Ensure that variables are <b>set</b> before persisting them.
      String and integer variables must be assigned a value, even if empty) to be set.
      Arrays, either positional or associative, are set just by declaring them.

      For example:

         local \(+)_Var=                           ^# Set to empty string
         local \(+)_Var='string'                   ^# Set to explicit string

         local -i \(+)_Var=                        ^# Set to 0 (the empty behavior for -i)
         local -i \(+)_Var=37                      ^# Set to explicit number

         local -A \(+)_Var                         ^# Set associative array; assignment is not required
         local -A \(+)_Var=([key]=value [k2]=v2)   ^# Set associative array to explicit values

         local -a \(+)_Var                         ^# Set positional array; assignment is not required
         local -a \(+)_Var=(1 "two")               ^# Set positional array to explicit values

EXAMPLE:
   + persist%TEST()^
   {^
      local -g \(+)_Var1='Charles'                 ^# String declaration
      local -ag \(+)_Var2=(37 'Wedgewood')         ^# Positiional array declaration

      \(++:launcher):persist \(+)_Var1 \(+)_Var2     ^# Persist variables into/out of :sudo || :reenter

      \(-):alter_user_function^
   }

   - alter_user_function()^
   {^
      :sudo "\$@" || :reenter^

      echo "User: \$_whoami"                       ^# Expect: <b>User: root</b>
      echo "Var1: \$\(+)_Var1"                      ^# Expect: <b>Var1: Charles</b>
      echo "Var2: \${\(+)_Var2[@]}"                 ^# Expect: <b>Var2: 37 Wedgewood</b>
   }^

   The above example can be run by doing:

      <B>$__ (++:launcher):persist%TEST</B>
EOF
}

+ persist()
{
   local (.)_Var
   for (.)_Var in "$@"; do
      eval _entry_vars[$(.)_Var]=
   done
}

+ persist%TEST()
{
   local -g (+)_Var1='Charles'                           # String declaration
   local -ag (+)_Var2=(37 'Wedgewood')                   # Positiional array declaration

   (++:launcher):persist (+)_Var1 (+)_Var2               # Persist variables into/out of :sudo || :reenter

   (-):alter_user_function
}

- alter_user_function()
{
   :sudo "$@" || :reenter

   echo "User: $_whoami"                                 # Expect: User: root
   echo "Var1: $(+)_Var1"                                # Expect: Var1: Charles
   echo "Var2: ${(+)_Var2[@]}"                           # Expect: Var2: 37 Wedgewood
}
