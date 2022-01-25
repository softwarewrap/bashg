#!/bin/bash

.dev:need:autofs:()
{
   :sudo || :reenter                                     # This function must run as root

   if ! .dev:service:exists autofs; then
      :log: --push-section 'Installing autofs'

      .dev.dev:autofs:install                            # Install the autofs service

      :log: --pop
   fi

   if [[ ! -s /etc/exports ]]; then
      :log: --push-section 'Creating world-readable exports file' "/etc/exports $FUNCNAME $@"

      echo '/ *(rw,sync,no_root_squash,no_all_squash,no_subtree_check)' >/etc/exports
      exportfs -a

      :log: --pop
   fi

   if ! .dev:service:is_active; then
      :log: --push-section 'Restarting autofs'

      .dev.dev:autofs:restart                            # Restart the autofs service

      :log: --pop
   fi
}
