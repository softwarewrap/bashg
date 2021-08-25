#!/bin/bash

_dev:need:install_package_jq:()
{
   if :test:has_command jq; then
      local _dev__need__install_package_jq_____Version
      printf -v _dev__need__install_package_jq_____Version '%s' "$( jq --version 2>/dev/null | grep -Po '[^0-9]*\K[0-9.]*' 2>/dev/null || true )"

      if :test:version_compare "$_dev__need__install_package_jq_____Version" -ge 1.6; then
         return 0
      fi
   fi

   _dev:need:install_package_jq:install_jq                                        # Install jq if not installed or if version < 1.6
}

_dev:need:install_package_jq:install_jq()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push 'Installing jq 1.6'

   curl -sfLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
   chmod 755 /usr/local/bin/jq

   :log: --pop
}
