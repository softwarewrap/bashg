#!/bin/bash

:get:os%HELP()
{
   local ___get__os__osHELP___Synopsis='Get a canonical OS/Version indicator'
   local ___get__os__osHELP___Usage='[<OPTIONS>]'

   :help: --set "$___get__os__osHELP___Synopsis" --usage "$___get__os__osHELP___Usage" <<EOF
OPTIONS:
   --var <var>    ^Save information in this associative array

DESCRIPTION:
   Store distro name and version information to an associative array or emit to stdout

   This information is useful in determining choices that need to be made based on
   the operating system distro, version, and machine architecture.

   If --var is specified then the results are stored in the <var> associative array.
   The indices include:

      ARRAY INDEX             EXAMPLE^<B
      ===========             =======^<B
      distro-full-version     ^<K^>Gredhat-7.8-x86_64
      distro-minor-version    ^<K^>Gredhat-7.8
      distro-major-version    ^<K^>Gredhat-7
      distro                  ^<K^>Gredhat

      full-version            ^<K^>G7.8-x86_64
      minor-version           ^<K^>G7.8
      major-version           ^<K^>G7
      arch                    ^<K^>Gx86_64

      is-linux                ^<K^>Gtrue (for redhat and centos)

   If the --var option is not specified, then distro name and version information is emitted to stdout.

EXAMPLES:
   :get:os --var _os       ^The system variable is defined in this way
   :get:os                 ^Emit to stdout the distro name and version information
EOF
}

:get:os()
{
   local ___get__os__os___Options
   ___get__os__os___Options=$(getopt -o '' -l 'var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___get__os__os___Options"

   local ___get__os___Var='___get__os__os___UnspecifiedVar'                    # Associative array to store os information
   local ___get__os__os___Emit=true                                   # By default, emit to stdout

   while true ; do
      case "$1" in
      --var)         ___get__os___Var="$2"
                     ___get__os__os___Emit=false; shift 2;;           # Store result to the indicated variable

      --)            shift; break;;
      *)             break;;
      esac
   done

   unset "$___get__os___Var"                                      # Always unset to ensure contents are clean
   local -Ag "$___get__os___Var"                                  # Declare associative array variable to store os info

   local ___get__os__os___OS                                          # Inspection is done via a kernel name handler
   ___get__os__os___OS="$( uname -s )"                                # Get the kernel name

   if :test:has_func ":get:os:$___get__os__os___OS"; then                 # If a handler exists, then run it
      ":get:os:$___get__os__os___OS"

   else
      :error: 1 "Unsupported OS: $___get__os__os___OS"                # Otherwise, error exit
   fi

   if $___get__os__os___Emit; then                                    # If no variable has been specified, emit to stdout
      :array:dump_associative "$___get__os___Var" '<B>Operating System Information</B>'
   fi
}

:get:os:Linux()
{
   local ___get__os__Linux___Version
   local ___get__os__Linux___Arch

   ___get__os__Linux___Arch="$( arch )"                                  # Machine hardware name
   printf -v "$___get__os___Var[is-linux]" '%s' 'true'            # redhat and centos are linux

   # REDHAT
   if [[ -f /etc/redhat-release && ! -h /etc/redhat-release ]]; then
      ___get__os__Linux___Version="$( grep -Po '.*release \K[0-9]*(.[0-9]*)?' /etc/redhat-release )"

      # Hierarchical distro names                                                      # EXAMPLE
      printf -v "$___get__os___Var[distro-full-version]"  '%s' "redhat-$___get__os__Linux___Version-$___get__os__Linux___Arch"  # redhat-7.8-x86_64
      printf -v "$___get__os___Var[distro-minor-version]" '%s' "redhat-$___get__os__Linux___Version"            # redhat-7.8
      printf -v "$___get__os___Var[distro-major-version]" '%s' "redhat-${___get__os__Linux___Version%%.*}"      # redhat-7
      printf -v "$___get__os___Var[distro]"               '%s' 'redhat'                         # redhat

   # CENTOS
   elif [[ -f /etc/centos-release && ! -h /etc/centos-release ]]; then
      ___get__os__Linux___Version="$( grep -Po '.*release \K[0-9]*(.[0-9]*)?' /etc/centos-release )"

      # Hierarchical distro names                                                      # EXAMPLE
      printf -v "$___get__os___Var[distro-full-version]"  '%s' "centos-$___get__os__Linux___Version-$___get__os__Linux___Arch"  # centos-7.8-x86_64
      printf -v "$___get__os___Var[distro-minor-version]" '%s' "centos-$___get__os__Linux___Version"            # centos-7.8
      printf -v "$___get__os___Var[distro-major-version]" '%s' "centos-${___get__os__Linux___Version%%.*}"      # centos-7
      printf -v "$___get__os___Var[distro]"               '%s' 'centos'                         # centos

   else
      :error: 1 'Could not determine operating system version'
   fi

   # Component names
   printf -v "$___get__os___Var[full-version]"         '%s' "$___get__os__Linux___Version-$___get__os__Linux___Arch"            # 7.8-x86_64
   printf -v "$___get__os___Var[minor-version]"        '%s' "$___get__os__Linux___Version"                      # 7.8
   printf -v "$___get__os___Var[major-version]"        '%s' "${___get__os__Linux___Version%.*}"                 # 7
   printf -v "$___get__os___Var[arch]"                 '%s' "$___get__os__Linux___Arch"                         # x86_64
}
