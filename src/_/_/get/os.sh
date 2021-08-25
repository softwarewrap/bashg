#!/bin/bash

+ os%HELP()
{
   local (.)_Synopsis='Get a canonical OS/Version indicator'
   local (.)_Usage='[<OPTIONS>]'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
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

+ os()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (-)_Var='(.)_UnspecifiedVar'                    # Associative array to store os information
   local (.)_Emit=true                                   # By default, emit to stdout

   while true ; do
      case "$1" in
      --var)         (-)_Var="$2"
                     (.)_Emit=false; shift 2;;           # Store result to the indicated variable

      --)            shift; break;;
      *)             break;;
      esac
   done

   unset "$(-)_Var"                                      # Always unset to ensure contents are clean
   local -Ag "$(-)_Var"                                  # Declare associative array variable to store os info

   local (.)_OS                                          # Inspection is done via a kernel name handler
   (.)_OS="$( uname -s )"                                # Get the kernel name

   if :test:has_func "(-):$(.)_OS"; then                 # If a handler exists, then run it
      "(-):$(.)_OS"

   else
      :error: 1 "Unsupported OS: $(.)_OS"                # Otherwise, error exit
   fi

   if $(.)_Emit; then                                    # If no variable has been specified, emit to stdout
      :array:dump_associative "$(-)_Var" '<B>Operating System Information</B>'
   fi
}

- Linux()
{
   local (.)_Version
   local (.)_Arch

   (.)_Arch="$( arch )"                                  # Machine hardware name
   printf -v "$(-)_Var[is-linux]" '%s' 'true'            # redhat and centos are linux

   # REDHAT
   if [[ -f /etc/redhat-release && ! -h /etc/redhat-release ]]; then
      (.)_Version="$( grep -Po '.*release \K[0-9]*(.[0-9]*)?' /etc/redhat-release )"

      # Hierarchical distro names                                                      # EXAMPLE
      printf -v "$(-)_Var[distro-full-version]"  '%s' "redhat-$(.)_Version-$(.)_Arch"  # redhat-7.8-x86_64
      printf -v "$(-)_Var[distro-minor-version]" '%s' "redhat-$(.)_Version"            # redhat-7.8
      printf -v "$(-)_Var[distro-major-version]" '%s' "redhat-${(.)_Version%%.*}"      # redhat-7
      printf -v "$(-)_Var[distro]"               '%s' 'redhat'                         # redhat

   # CENTOS
   elif [[ -f /etc/centos-release && ! -h /etc/centos-release ]]; then
      (.)_Version="$( grep -Po '.*release \K[0-9]*(.[0-9]*)?' /etc/centos-release )"

      # Hierarchical distro names                                                      # EXAMPLE
      printf -v "$(-)_Var[distro-full-version]"  '%s' "centos-$(.)_Version-$(.)_Arch"  # centos-7.8-x86_64
      printf -v "$(-)_Var[distro-minor-version]" '%s' "centos-$(.)_Version"            # centos-7.8
      printf -v "$(-)_Var[distro-major-version]" '%s' "centos-${(.)_Version%%.*}"      # centos-7
      printf -v "$(-)_Var[distro]"               '%s' 'centos'                         # centos

   else
      :error: 1 'Could not determine operating system version'
   fi

   # Component names
   printf -v "$(-)_Var[full-version]"         '%s' "$(.)_Version-$(.)_Arch"            # 7.8-x86_64
   printf -v "$(-)_Var[minor-version]"        '%s' "$(.)_Version"                      # 7.8
   printf -v "$(-)_Var[major-version]"        '%s' "${(.)_Version%.*}"                 # 7
   printf -v "$(-)_Var[arch]"                 '%s' "$(.)_Arch"                         # x86_64
}
