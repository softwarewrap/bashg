#!/bin/bash

+ version_compare%HELP()
{
   local (.)_Synopsis='Compare two version strings'
   local (.)_Usage='<first> <option> <second>'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
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

+ version_compare()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'legqt' -l 'lt,le,eq,ge,gt' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_L=false
   local (.)_E=false
   local (.)_G=false

   while true ; do
      case "$1" in
      -l)      (.)_L=true; shift;;
      -e)      (.)_E=true; shift;;
      -g)      (.)_G=true; shift;;
      -q|-t)   shift;;

      --lt)    (.)_L=true; shift;;
      --le)    (.)_L=true; (.)_E=true; shift;;
      --eq)    (.)_E=true; shift;;
      --ge)    (.)_G=true; (.)_E=true; shift;;
      --gt)    (.)_G=true; shift;;

      --)      shift; break;;
      *)       break;;
      esac
   done

   local (.)_First="$1"
   local (.)_Second="$2"

   local -i (.)_Lower
   (.)_Lower="$(
      echo -e "$(.)_First\n$(.)_Second" | cat -n | sort -V -k 2,3 | head -n1 | awk '{print $1}'
   )"

   if $(.)_L && [[ $(.)_Lower -eq 1 && $(.)_First != $(.)_Second ]]; then
      return 0
   fi

   if $(.)_E && [[ $(.)_First = $(.)_Second ]]; then
      return 0
   fi

   if $(.)_G && [[ $(.)_Lower -eq 2 && $(.)_First != $(.)_Second ]]; then
      return 0
   fi

   return 1
}
