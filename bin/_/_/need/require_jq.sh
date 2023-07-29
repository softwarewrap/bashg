#!/bin/bash

:need:require_jq:%HELP()
{
   local __need__require_jq__HELP___Synopsis='Ensure jq is installed'

   :help: --set "$__need__require_jq__HELP___Synopsis" <<EOF
OPTIONS:
   --version <version>

DESCRIPTION:
   Ensure jq is installed, possibly at a required version level.

   If --version is specified, then that <version> or higher is required.

RETURN STATUS:
   0  Success
   1  Required version not available to install
EOF
}

:need:require_jq:()
{
   local __need__require_jq_____Options
   __need__require_jq_____Options=$(getopt -o '' -l 'version:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__need__require_jq_____Options"

   local __need__require_jq_____RequiredVersion=
   while true ; do
      case "$1" in
      --version)  __need__require_jq_____RequiredVersion="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if :test:has_command jq; then
      if [[ -z $__need__require_jq_____RequiredVersion ]]; then
         return 0
      fi

      local __need__require_jq_____CurrentVersion
      printf -v __need__require_jq_____CurrentVersion '%s' "$( jq --version 2>/dev/null | grep -Po '[^0-9]*\K[0-9.]*' 2>/dev/null || true )"

      if :test:version_compare "$__need__require_jq_____CurrentVersion" -ge "$__need__require_jq_____RequiredVersion"; then
         return 0
      fi
   fi

   :need:require_jq:install_jq "$__need__require_jq_____RequiredVersion"                 # Install jq if not installed or if version < 1.6
}

:need:require_jq:install_jq()
{
   :sudo || :reenter                                     # This function must run as root

   local __need__require_jq__install_jq___RequiredVersion="$1"

   :: require_epel                                       # Require the epel repository
   dnf config-manager --set-enabled powertools           # Needed for xorg-x11-apps

   local __need__require_jq__install_jq___AvailableVersion
   __need__require_jq__install_jq___AvailableVersion="$( yum list available jq | grep '^jq' | awk '{print $2}' | sort -V | tail -1 )"

   if [[ -n $__need__require_jq__install_jq___AvailableVersion ]]; then
      if [[ -z $__need__require_jq__install_jq___RequiredVersion ]] ||
         :test:version_compare "$__need__require_jq__install_jq___AvailableVersion" -ge "$__need__require_jq__install_jq___RequiredVersion"; then

         :log: --push "Installing jq-$__need__require_jq__install_jq___AvailableVersion"
         yum -y install "jq-$__need__require_jq__install_jq___AvailableVersion"
         :log: --pop
         return

      elif :test:version_compare 1.6 -lt "$__need__require_jq__install_jq___RequiredVersion"; then
         :error: 1 "Could not find jq at the required version: $__need__require_jq__install_jq___RequiredVersion"
         return

      # else there is no required version, so fall through and install at the bottom
      fi

   elif [[ -n $__need__require_jq__install_jq___RequiredVersion ]] && :test:version_compare 1.6 -lt "$__need__require_jq__install_jq___RequiredVersion"; then
      :error: 1 "Could not find jq at the required version: $__need__require_jq__install_jq___RequiredVersion"
      return

      # else there is no required version, so fall through and install at the bottom
   fi

   :log: --push "Installing jq-1.6"
   rm -f /usr/bin/jq
   curl -sfLo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
   chmod 755 /usr/bin/jq
   :log: --pop
}
