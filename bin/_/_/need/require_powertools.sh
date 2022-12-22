#!/bin/bash

:need:require_powertools:linux-8()
{
   :sudo || :reenter                                     # This function must run as root

   if [[ -n $( yum repolist --disabled --quiet | tail -n +2 | grep '^powertools\s' ) ]]; then
      :log: --push-section 'Require PowerTools on Linux 8' "$FUNCNAME $@"

      dnf config-manager --set-enabled powertools
   fi
}

:need:require_powertools:linux()
{
   true "$FUNCNAME"
}
