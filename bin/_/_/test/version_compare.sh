#!/bin/bash

:test:version_compare%HELP()
{
   local ___test__version_compare__version_compareHELP___Synopsis='Compare two version strings'
   local ___test__version_compare__version_compareHELP___Usage='<first> <option> <second>'

   :help: --set "$___test__version_compare__version_compareHELP___Synopsis" --usage "$___test__version_compare__version_compareHELP___Usage" <<EOF
OPTIONS:
   -l|--lt  ^Is less than
   -e|--eq  ^Is equal to
   -g|--gt  ^Is greater than

   --le     ^Is less than or equal to
   --ge     ^Is greater than or equal to

   -q|-t    ^Allowed so that -lt, -le, -eq, -ge, and -gt options work

DESCRIPTION:
   Perform a lexical comparison on two version strings, returning 0 if the requested comparision is true.
   The default comparison is -e.

   The position of the specified options is unimportant. Typically, they are placed between
   the <first> and <second> version strings.

   A missing version string is taken to be the empty string, not an error.
   This allow for the comparision where the empty string is always taken to be the earliest version.

   Note: both single-hyphen and double-hyphen options are provided in consideration of
   option syntax present in the test, [, and [[ ]] commands.

EXAMPLES:
   :test:version_compare 1.2 -ge 2.3   ^<b>false</b>: 1.2 is not >= 2.3
   :test:version_compare 1.2 -e 2.3    ^<b>false</b>: 1.2 is not == 2.3
   :test:version_compare 2.3 --ge 1.2  ^<b>true</b>:  2.3 is >= 1.2
   :test:version_compare 4.5 -e 4.5.0  ^<b>false</b>: 4.5 is not lexically == 4.5.0
EOF
}

:test:version_compare()
{
   local ___test__version_compare__version_compare___Options
   ___test__version_compare__version_compare___Options=$(getopt -o 'legqt' -l 'lt,le,eq,ge,gt' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___test__version_compare__version_compare___Options"

   local ___test__version_compare__version_compare___L=false
   local ___test__version_compare__version_compare___E=false
   local ___test__version_compare__version_compare___G=false

   while true ; do
      case "$1" in
      -l)      ___test__version_compare__version_compare___L=true; shift;;
      -e)      ___test__version_compare__version_compare___E=true; shift;;
      -g)      ___test__version_compare__version_compare___G=true; shift;;
      -q|-t)   shift;;

      --lt)    ___test__version_compare__version_compare___L=true; shift;;
      --le)    ___test__version_compare__version_compare___L=true; ___test__version_compare__version_compare___E=true; shift;;
      --eq)    ___test__version_compare__version_compare___E=true; shift;;
      --ge)    ___test__version_compare__version_compare___G=true; ___test__version_compare__version_compare___E=true; shift;;
      --gt)    ___test__version_compare__version_compare___G=true; shift;;

      --)      shift; break;;
      *)       break;;
      esac
   done

   local ___test__version_compare__version_compare___First="$1"
   local ___test__version_compare__version_compare___Second="$2"

   local -i ___test__version_compare__version_compare___Lower
   ___test__version_compare__version_compare___Lower="$(
      echo -e "$___test__version_compare__version_compare___First\n$___test__version_compare__version_compare___Second" | cat -n | sort -V -k 2,3 | head -n1 | awk '{print $1}'
   )"

   if $___test__version_compare__version_compare___L && [[ $___test__version_compare__version_compare___Lower -eq 1 && $___test__version_compare__version_compare___First != $___test__version_compare__version_compare___Second ]]; then
      return 0
   fi

   if $___test__version_compare__version_compare___E && [[ $___test__version_compare__version_compare___First = $___test__version_compare__version_compare___Second ]]; then
      return 0
   fi

   if $___test__version_compare__version_compare___G && [[ $___test__version_compare__version_compare___Lower -eq 2 && $___test__version_compare__version_compare___First != $___test__version_compare__version_compare___Second ]]; then
      return 0
   fi

   return 1
}
