#!/bin/bash

- %HELP()
{
   local (.)_Synopsis='Ensure jq is installed'

   :help: --set "$(.)_Synopsis" <<EOF
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

- ()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'version:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_RequiredVersion=
   while true ; do
      case "$1" in
      --version)  (.)_RequiredVersion="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if :test:has_command jq; then
      if [[ -z $(.)_RequiredVersion ]]; then
         return 0
      fi

      local (.)_CurrentVersion
      printf -v (.)_CurrentVersion '%s' "$( jq --version 2>/dev/null | grep -Po '[^0-9]*\K[0-9.]*' 2>/dev/null || true )"

      if :test:version_compare "$(.)_CurrentVersion" -ge "$(.)_RequiredVersion"; then
         return 0
      fi
   fi

   (-):install_jq "$(.)_RequiredVersion"                 # Install jq if not installed or if version < 1.6
}

- install_jq()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_RequiredVersion="$1"

   :: require_epel                                       # Require the epel repository

   local (.)_AvailableVersion
   (.)_AvailableVersion="$( yum list available jq | grep '^jq' | awk '{print $2}' | sort -V | tail -1 )"

   if [[ -n $(.)_AvailableVersion ]]; then
      if [[ -z $(.)_RequiredVersion ]] ||
         :test:version_compare "$(.)_AvailableVersion" -ge "$(.)_RequiredVersion"; then

         :log: --push "Installing jq-$(.)_AvailableVersion"
         yum -y install "jq-$(.)_AvailableVersion"
         :log: --pop
         return

      elif :test:version_compare 1.6 -lt "$(.)_RequiredVersion"; then
         :error: 1 "Could not find jq at the required version: $(.)_RequiredVersion"
         return

      # else there is no required version, so fall through and install at the bottom
      fi

   elif [[ -n $(.)_RequiredVersion ]] && :test:version_compare 1.6 -lt "$(.)_RequiredVersion"; then
      :error: 1 "Could not find jq at the required version: $(.)_RequiredVersion"
      return

      # else there is no required version, so fall through and install at the bottom
   fi

   :log: --push "Installing jq-1.6"
   rm -f /usr/bin/jq
   curl -sfLo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
   chmod 755 /usr/bin/jq
   :log: --pop
}
