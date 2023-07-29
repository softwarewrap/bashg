#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

- ()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Updating sudoers file' "/etc/sudoers $FUNCNAME $@"

   :file:ensure_nl_at_end /etc/sudoers                   # Ensure the file ends with a newline

   sed -i '/^ALL\s*ALL=(ALL)/d' /etc/sudoers             # Remove any previous entries for ALL

   echo $'ALL\tALL=(ALL)\tNOPASSWD: ALL' >>/etc/sudoers  # Allow all users sudo access

   :log: --pop
}
