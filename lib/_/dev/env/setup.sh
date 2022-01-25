#!/bin/bash

+ setup%HELP()
{
   local (.)_Synopsis='Setup a Linux environment'

   :help: --set "$(.)_Synopsis" <<EOF
OPTIONS:
   -h|--hypervisor>     ^The environment is a hypervisor, not a VM
   -p|--port <port>     ^Set the SSH Port to <port> [default: 22]

DESCRIPTION:
   Setup a Linux environment: a VM or a hypervisor

   If the --hypervisor option is specified, then additions specific to hypervisors
   are added. In particular, this includes libvirtd.

   If the --port option is specified, then the SSH port is set to <port>.
EOF
}

+ setup()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Options
   (.)_Options=$(getopt -o 'hp:' -l 'hypervisor,port:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_IsAHypervisor=false
   local (.)_Port=22

   while true ; do
      case "$1" in
      -h|--hypervisor)  (.)_IsAHypervisor=true; shift;;
      -p|--port)        (.)_Port="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   if [[ ! $(.)_Port =~ ^[0-9]+$ ]]; then
      :error: 1 "Invalid SSH port: $(.)_Port"
      return
   fi

   :: sudoers                                            # Update /etc/sudoers to allow sudo access
   :: python                                             # Ensure python is not no-python
   :: clean_yum                                          # Clean the yum and rpm caches
   :: disable_selinux                                    # Ensure that SELinux is disabled
   :: -- require_jq --version 1.6                        # Version 1.5 (default) has vulnerabilities; get 1.6
   :: -- disable_services postfix firewalld              # Disable these systemd services
   :: resolv_conf                                        # Make resolv.conf static
   :: set_timezone                                       # Set the timezone to the default
   :: iptables                                           # Ensure iptables is installed and flush rules
   :: tune_sysctl                                        # Tune sysctl; add swap file if needed; remove IPv6
   :: tune_limits                                        # Tune /etc/security/limits.conf parameters
   :: xvfb                                               # Install virtual framebuffer for X11
   :: mount_all                                          # Ensure that all defined mounts are mounted
   :: os_packages                                        # Install extra OS packages
   :: disable_user_list                                  # Disable login page listing user names
   :: install_fonts                                      # Install fonts (e.g., for use by vnc)
   :: autofs                                             # Install the auto-mount daemon

   if ! $(.)_IsAHypervisor; then
      :: -- disable_services libvirtd                    # Disable after other installations
   fi

   :: zsh                                                # Install zsh
   :: vim                                                # Install/update vim

   (++:ssh):config --port "$(.)_Port"
}
