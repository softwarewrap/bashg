#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

- ()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Updating security limits' "$FUNCNAME $@"

   :file:ensure_nl_at_end /etc/security/limits.conf      # Ensure file ends with a newline

   :log: 'Updating /etc/security/limits.conf'

   :archive: --no-error /etc/security/limits.conf        # Archive the original version

   cat > /etc/security/limits.conf <<EOF
# /etc/security/limits.conf
#
#Each line describes a limit for a user in the form:
#
#<domain>        <type>  <item>  <value>
#
#Where:
#<domain> can be:
#        - an user name
#        - a group name, with @group syntax
#        - the wildcard *, for default entry
#        - the wildcard %, can be also used with %group syntax,
#                 for maxlogin limit
#
#<type> can have the two values:
#        - "soft" for enforcing the soft limits
#        - "hard" for enforcing hard limits
#
#<item> can be one of the following:
#        - core - limits the core file size (KB)
#        - data - max data size (KB)
#        - fsize - maximum filesize (KB)
#        - memlock - max locked-in-memory address space (KB)
#        - nofile - max number of open files
#        - rss - max resident set size (KB)
#        - stack - max stack size (KB)
#        - cpu - max CPU time (MIN)
#        - nproc - max number of processes
#        - as - address space limit (KB)
#        - maxlogins - max number of logins for this user
#        - maxsyslogins - max number of logins on the system
#        - priority - the priority to run user process with
#        - locks - max number of file locks the user can hold
#        - sigpending - max number of pending signals
#        - msgqueue - max memory used by POSIX message queues (bytes)
#        - nice - max nice priority allowed to raise to values: [-20, 19]
#        - rtprio - max realtime priority
#
#<domain>      <type>  <item>         <value>
#

# SOFT LIMITS
*                soft    nofile          20480
*                soft    nproc           4096
*                soft    stack           20480

# HARD LIMITS
*                hard    nofile          1048576
*                hard    nproc           unlimited
*                hard    stack           unlimited

# End of file
EOF

   :log: 'Updating /etc/security/limits.d/20-nproc.conf'

   :archive: --no-error /etc/security/limits.d/20-nproc.conf
                                                         # Archive the original version

   cat > /etc/security/limits.d/20-nproc.conf <<EOF
# Default limit for number of user's processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning.

*          soft    nproc     unlimited
root       soft    nproc     unlimited
EOF

   :log: --pop
}
