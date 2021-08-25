#!/bin/bash

:ssh:config%HELP()
{
   local ___ssh__config__configHELP___Synopsis='Configure /etc/ssh/sshd_config'

   :help: --set "$___ssh__config__configHELP___Synopsis" <<EOF
OPTIONS:
   -p|--port <port>        ^Set port to <port> [default: 22]
   -d|--disable-password   ^Disable password authentication

DESCRIPTION:
   Configure the sshd_config file. This consists of:

      - Removing comments, blank lines, and reducing tabs to spaces
      - Changing the following entrys:

            AddressFamily inet^
            PasswordAuthentication <yes|no>^
            Port <port>^

   <R>Important:</R> If --disable-password is specified, then it is critical that
   access to the server via ssh certificate be configured before applying
   this change; otherwise, it will not be possible to login.

   This command automatically saves the original to the archive directory.

$(:text:align <<<"
FILES:
   /etc/ssh/sshd_config ^|The updated configuration file
   /orig/etc/ssh/sshd_config ^|The archived (original) configuration file")

SEE ALSO:
   :archive:   ^$(:help: --synopsis :archive:)
EOF
}


:ssh:config()
{
   :sudo || :reenter                                     # This function must run as root

   local ___ssh__config__config___Options
   ___ssh__config__config___Options=$(getopt -o p:d -l "port:,disable-password" -n "${FUNCNAME[0]}" -- "$@") || return 1
   eval set -- "$___ssh__config__config___Options"

   local ___ssh__config__config___Port='22'
   local ___ssh__config__config___Password='yes'
   while true ; do
      case "$1" in
      -p|--port)              ___ssh__config__config___Port="$2"; shift 2;;
      -n|--disable-password)  ___ssh__config__config___Password=no; shift;;
      --)                     shift; break;;
      esac
   done

   # Ensure the entry is a valid port
   if [[ ! $___ssh__config__config___Port =~ ^[1-9][0-9]*$ ]]; then
      :error: 1 "Not a port: $___ssh__config__config___Port"
   fi

   if (( $___ssh__config__config___Port > 65535 )); then
      :error: 2 "Port is not in range: $___ssh__config__config___Port"
   fi

   if :archive: /etc/ssh/sshd_config; then
      sed -i \
            -e '/^#/d' \
            -e '/^$/d' \
            -e 's/\s*#.*//' \
            -e '/^AddressFamily /d' \
            -e '/^PasswordAuthentication /d' \
            -e '/^Port /d' \
            -e 's/\t\+/ /g' \
            -e 's/\s\+/ /g' \
         /etc/ssh/sshd_config

      cat >> /etc/ssh/sshd_config <<EOF
AddressFamily inet
PasswordAuthentication $___ssh__config__config___Password
Port $___ssh__config__config___Port
EOF

      local ___ssh__config__config___Tmp
      ___ssh__config__config___Tmp="$(mktemp)"                                # Transform file to temporary file
      sed 's/\s/\t/' /etc/ssh/sshd_config |              # Replace separator between key and value with a tab
      expand -40 |                                       # and expand to form columns
      sort -f -o "$___ssh__config__config___Tmp"                              # and produce a sorted set of directives

      rm -f /etc/ssh/sshd_config                         # Remove the original file
      mv "$___ssh__config__config___Tmp" /etc/ssh/sshd_config                 # Install the updated ssh configuration file

      systemctl restart sshd.service

      if :test:has_command firewall-cmd && [[ $(firewall-cmd --state 2>&1) =~ ^running$ ]]; then
         firewall-cmd --permanent --add-service=ssh
         firewall-cmd --permanent --add-port=$___ssh__config__config___Port/tcp
         firewall-cmd --reload
      fi
   fi
}
