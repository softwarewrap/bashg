#!/bin/bash

+ config%HELP()
{
   local (.)_Synopsis='Configure /etc/ssh/sshd_config'

   :help: --set "$(.)_Synopsis" <<EOF
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


+ config()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o p:d -l "port:,disable-password" -n "${FUNCNAME[0]}" -- "$@") || return 1
   eval set -- "$(.)_Options"

   local (.)_Port='22'
   local (.)_Password='yes'
   while true ; do
      case "$1" in
      -p|--port)              (.)_Port="$2"; shift 2;;
      -n|--disable-password)  (.)_Password=no; shift;;
      --)                     shift; break;;
      esac
   done

   # Ensure the entry is a valid port
   if [[ ! $(.)_Port =~ ^[1-9][0-9]*$ ]]; then
      :error: 1 "Not a port: $(.)_Port"
   fi

   if (( $(.)_Port > 65535 )); then
      :error: 2 "Port is not in range: $(.)_Port"
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
PasswordAuthentication $(.)_Password
Port $(.)_Port
EOF

      local (.)_Tmp
      (.)_Tmp="$(mktemp)"                                # Transform file to temporary file
      sed 's/\s/\t/' /etc/ssh/sshd_config |              # Replace separator between key and value with a tab
      expand -40 |                                       # and expand to form columns
      sort -f -o "$(.)_Tmp"                              # and produce a sorted set of directives

      rm -f /etc/ssh/sshd_config                         # Remove the original file
      mv "$(.)_Tmp" /etc/ssh/sshd_config                 # Install the updated ssh configuration file

      systemctl restart sshd.service

      if :test:has_command firewall-cmd && [[ $(firewall-cmd --state 2>&1) =~ ^running$ ]]; then
         firewall-cmd --permanent --add-service=ssh
         firewall-cmd --permanent --add-port=$(.)_Port/tcp
         firewall-cmd --reload
      fi
   fi
}
