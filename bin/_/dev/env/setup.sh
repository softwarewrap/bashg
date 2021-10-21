#!/bin/bash

.dev:env:setup%HELP()
{
   local _dev__env__setup__setupHELP___Synopsis='Setup a Linux environment'

   :help: --set "$_dev__env__setup__setupHELP___Synopsis" <<EOF
OPTIONS:
   -h|--hypervisor>     ^The environment is a hypervisor, not a VM

DESCRIPTION:
   Setup a Linux environment: a VM or a hypervisor

   If the --hypervisor option is specified, then additions specific to hypervisors
   are added. In particular, this includes libvirtd.
EOF
}

.dev:env:setup()
{
   local _dev__env__setup__setup___Options
   _dev__env__setup__setup___Options=$(getopt -o 'h' -l 'hypervisor' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__env__setup__setup___Options"

   local _dev__env__setup__setup___IsAHypervisor=true
   while true ; do
      case "$1" in
      -h|--hypervisor)  _dev__env__setup__setup___IsAHypervisor=true; shift;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   :: sudoers                                            # Update /etc/sudoers to allow sudo access
   :: disable_selinux                                    # Ensure that SELinux is disabled
   :: -- disable_services NetworkManager postfix firewalld
                                                         # Disable these systemd services
   :: clean_yum                                          # Clean the yum and rpm caches
   :: set_timezone                                       # Set the timezone to the default
   :: iptables                                           # Ensure iptables is installed and flush rules
   :: tune_sysctl                                        # Tune sysctl; add swap file if needed; remove IPv6
   :: tune_limits                                        # Tune /etc/security/limits.conf parameters
   :: rsh                                                # Install rsh
   :: xvfb                                               # Install virtual framebuffer for X11
   :: mount_all                                          # Ensure that all defined mounts are mounted
   :: os_packages                                        # Install extra OS packages
   :: disable_user_list                                  # Disable login page listing user names
   :: install_fonts                                      # Install fonts (e.g., for use by vnc)

   if ! $_dev__env__setup__setup___IsAHypervisor; then
      :: -- disable_services libvirtd                    # Disable after other installations
   fi

   :: zsh                                                # Install zsh
   :: vim                                                # Install/update vim

   .dev:env:netfilter -u                            # Configure iptables rules
}
