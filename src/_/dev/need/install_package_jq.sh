#!/bin/bash

- ()
{
   if :test:has_command jq; then
      local (.)_Version
      printf -v (.)_Version '%s' "$( jq --version 2>/dev/null | grep -Po '[^0-9]*\K[0-9.]*' 2>/dev/null || true )"

      if :test:version_compare "$(.)_Version" -ge 1.6; then
         return 0
      fi
   fi

   (-):install_jq                                        # Install jq if not installed or if version < 1.6
}

- install_jq()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_AvailableVersion
   (.)_AvailableVersion="$( yum list available jq | grep '^jq' | awk '{print $2}' | sort -V | tail -1 )"

   if [[ -n $(.)_AvailableVersion ]] && :test:version_compare 1.6-2.el7 -ge 1.6; then
      :log: --push "Installing jq-$(.)_AvailableVersion"

      yum -y install "jq-$(.)_AvailableVersion"

      :log: --pop

   else
      rm -f /usr/bin/jq
      curl -sfLo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
      chmod 755 /usr/bin/jq

      :log: --pop
   fi
}
