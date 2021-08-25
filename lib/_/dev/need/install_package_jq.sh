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

   :log: --push 'Installing jq 1.6'

   curl -sfLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
   chmod 755 /usr/local/bin/jq

   :log: --pop
}
