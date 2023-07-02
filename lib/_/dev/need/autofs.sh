#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   if ! (+:service):exists autofs; then
      :log: --push-section 'Installing autofs'

      (+:.dev:autofs):install                            # Install the autofs service

      :log: --pop
   fi

   if [[ ! -s /etc/exports ]]; then
      :log: --push-section 'Creating world-readable exports file' "/etc/exports $FUNCNAME $@"

      echo '/ *(rw,sync,no_root_squash,no_all_squash,no_subtree_check)' >/etc/exports
      exportfs -a

      :log: --pop
   fi

   if ! (++:service):is_active; then
      :log: --push-section 'Restarting autofs'

      (+:.dev:autofs):restart                            # Restart the autofs service

      :log: --pop
   fi
}
