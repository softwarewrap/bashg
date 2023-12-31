#!/bin/bash

- linux-8()
{
   :sudo || :reenter                                     # This function must run as root

   if [[ -n $( yum repolist --disabled --quiet | tail -n +2 | grep '^powertools\s' ) ]]; then
      :log: --push-section 'Require PowerTools on Linux 8' "$FUNCNAME $@"

      dnf config-manager --set-enabled powertools

      :log: --pop
   fi
}

- linux()
{
   true "$FUNCNAME"
}
