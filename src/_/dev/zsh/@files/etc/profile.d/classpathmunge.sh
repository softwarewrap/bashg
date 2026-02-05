#!/bin/bash

+ classpathmunge%HELP()
{
   local (.)_Synopsis='Update the CLASSPATH environment variable'

   :help: --set "$(.)_Synopsis" --usage '[OPTIONS] <path>...' <<EOF
DESCRIPTION:
   Add a path to or remove a path from the CLASSPATH environment variable.
   With no options specified, the provide paths are added to the end of the CLASSPATH variable.
   This function is used only in scripting applications and has no effect for standalone execution.

OPTIONS:
   -a|--after^
      Add the <path> to the end of the CLASSPATH variable.
      If multiple paths are provided, they will appear in the order that was given.

   -b|--before^
      Add the <path> to the beginning of the CLASSPATH variable. [default]
      If multiple paths are provided, they will appear in the order that was given.

   -r|--remove^
      Remove any matching <path> entries from the CLASSPATH variable.
EOF
}

+ classpathmunge()
{
   echo "IN $FUNCNAME with $# $@"

   local (.)_Options
   (.)_Options=$(getopt -o 'abr' -l 'after,before,remove' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Action='After'

   while true ; do
      case "$1" in
      -a|--after)    (.)_Action=After; shift;;
      -b|--before)   (.)_Action=Before; shift;;
      -r|--remove)   (.)_Action=Remove; shift;;

      -h|--help)     $FUNCNAME%HELP; return 0;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local -gx CLASSPATH                                   # Ensure CLASSPATH is marked for export
   CLASSPATH="$( (-):Trim "$CLASSPATH" )"                # Ensure the variable has no leading/trailing : chars

   "(-):$(.)_Action" "$@"
}

- After()
{
   local (.)_Path


   for (.)_Path in "$@"; do
      (.)_Path="$( (-):Trim "$(.)_Path" )"               # Remove any leading or trailing : from the (.)_Path var

      if [[ ! :$CLASSPATH: =~ :$(.)_Path: ]]; then
         CLASSPATH="$CLASSPATH:$(.)_Path"
      fi
   done
}

- Before()
{
   local (.)_Path

   local -i (.)_I
   for (( (.)_I=$#; (.)_I>0; (.)_I-- )); do              # Iterate in reverse to preserve the desired order
      (.)_Path="$( (-):Trim "${!(.)_I}" )"               # Remove any leading or trailing : from the (.)_Path var

      if [[ ! :$CLASSPATH: =~ :$(.)_Path: ]]; then
         CLASSPATH="$(.)_Path:$CLASSPATH"
      fi
   done
}

- Remove()
{
   local (.)_Path

   for (.)_Path in "$@"; do
      (.)_Path="$( (-):Trim "$(.)_Path" )"               # Remove any leading or trailing : from the (.)_Path var

      if [[ :$CLASSPATH: =~ :$(.)_Path: ]]; then
         CLASSPATH=$(echo ":$CLASSPATH:" | sed -e "s#:$(.)_Path:#:#g" -e 's/^:*//' -e 's/:*$//')
      fi
   done
}

- Trim()
{
   sed -e 's|^:*||' -e 's|:*$||' -e 's|::*|:|g' <<<"$1"
}

+ classpathmunge%TEST()
{
   CLASSPATH="::a:b:c::d:e::"

   (+):classpathmunge p
   (+):classpathmunge --before q
   (+):classpathmunge --after r
   (+):classpathmunge --remove b

   local (.)_Expect='q:a:c:d:e:p:r'

   if [[ $CLASSPATH = $(.)_Expect ]]; then
      echo "PASS: CLASSPATH = $CLASSPATH"

   else
      echo "FAIL: CLASSPATH = $CLASSPATH, Expected: $(.)_Expect"
   fi
}
