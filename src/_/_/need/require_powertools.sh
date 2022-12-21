#!/bin/bash

- linux-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! (-):PowerToolsisInstalled; then
      :log: --push-section 'Require PowerTools on Linux 8' "$FUNCNAME $@"

      dnf config-manager --set-enabled powertools
   fi
}

- linux()
{
   true "$FUNCNAME"
}

- PowerToolsisInstalled()
{
   grep -hPo '^\[[^]]*\]' /etc/yum.repos.d/*.repo |      # Get all repo directives
   sed 's/^.\(.*\).$/\1/' |                              # Remove the brackets
   grep -q '^powertools$'                                # See if any of them is 'powertools'
}
