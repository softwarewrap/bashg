#!/bin/bash

:esc:sed%HELP()
{
   local __esc__sed__sedHELP___Synopsis='Escape string for sed use'
   local __esc__sed__sedHELP___Usage='<string>...'

   :help: --set "$__esc__sed__sedHELP___Synopsis" --usage "$__esc__sed__sedHELP___Usage" <<'EOF'
OPTIONS:
   -n|--nl     ^Escape newlines to the two-character sequence \\n

DESCRIPTION:
   Escape strings for use in <b>sed</b> idioms

   The common use case is with the <b>sed</b> search and replace idiom:

      s/<search>/<replace>/^

   In the above, both <search> and <replace> strings may need to
   be escaped when characters need to be treated literally.

   The following characters are escaped:

   [  ]  \^  $  .  *  ?  +  /  \  (  )  &^<K

   Escaping places a backslash before any of the above characters.

EXAMPLE:
   S='A[conf/db]=${db\^^}'                       ^Contains \^, $, and / that require escaping
   R='A[conf/db]=myhost'                        ^Contains \^, $, and / that require escaping

   :esc:sed "$S"                                ^The escaped search string
   A\[conf\/db\]=\${db\\^\\^}^<G

   :esc:sed "$R"                                ^The escaped replace string
   A\[conf\/db\]=myhost^<G

   echo 'declare A[conf/db]=${db\^^}:1521' |     ^The text to be operated upon by sed
   sed "s/$(:esc:sed "$S")/$(:esc:sed "$R")/"   ^Escapes both the search and replace idioms
   declare A[conf/db]=myhost:1521               ^<GThe result
EOF
}


:esc:sed()
{
   local __esc__sed__sed___Options
   __esc__sed__sed___Options=$(getopt -o 'n' -l 'nl' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__esc__sed__sed___Options"

   local __esc__sed__sed___EscapeNewlines=false
   while true ; do
      case "$1" in
      -n|--nl) __esc__sed__sed___EscapeNewlines=true; shift;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   awk '{ gsub(/[][^$.*?+\/\\()&]/, "\\\\&"); print }' <<<"$@" |
                                                         # Backslash escape any of the indicated characters
   {
      if $__esc__sed__sed___EscapeNewlines; then
         LC_ALL=C sed -- ':a;N;$!ba;s/\n/\\n/g'
      else
         cat
      fi
   }
}
