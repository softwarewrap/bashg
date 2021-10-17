#!/bin/bash

.dev:env:setup()
{
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

   :: -- disable_services libvirtd                       # Disable after other installations

   :: zsh                                                # Install zsh
   .dev:zsh:configure /install                      # Configure install user for zsh

   :: vim                                                # Install/update vim
   .dev:vim:configure /install                      # Configure install user for vim
}
