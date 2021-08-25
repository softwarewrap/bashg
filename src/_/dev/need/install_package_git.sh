#!/bin/bash

- centos()
{
   local (.)_NeedToInstallGit=false

   if :test:has_command git; then
      local (.)_Version
      printf -v (.)_Version '%s' "$( git --version 2>/dev/null | grep -Po '[^0-9]*\K[0-9.]*' 2>/dev/null || true )"

      :test:version_compare "$(.)_Version" -ge 2.7.6 || (.)_NeedToInstallGit=true

   else
      (.)_NeedToInstallGit=true
   fi

   if $(.)_NeedToInstallGit; then
      (-):install_git_centos
   fi
}

- redhat()
{
   if [[ ! ":$PATH:" =~ ':/opt/rh/rh-git227/root/usr/bin:' && -f /etc/profile.d/scl.sh ]]; then
      source /etc/profile.d/scl.sh                       # Reload to update PATH and other environment variables
   fi

   local (.)_NeedToInstallGit=false

   if :test:has_command git; then
      local (.)_Version
      printf -v (.)_Version '%s' "$( git --version 2>/dev/null | grep -Po '[^0-9]*\K[0-9.]*' 2>/dev/null || true )"

      :test:version_compare "$(.)_Version" -ge 2.7.6 || (.)_NeedToInstallGit=true

   else
      (.)_NeedToInstallGit=true
   fi

   if $(.)_NeedToInstallGit; then
      (-):install_git_redhat
   fi

   if [[ ! ":$PATH:" =~ ':/opt/rh/rh-git227/root/usr/bin:' ]]; then
      source /etc/profile.d/scl.sh                       # Reload to update PATH and other environment variables
   fi
}

- install_git_centos()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push 'Installing git from endpoint-repo'

   yum -y install https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.9-1.x86_64.rpm || true
   yum -y install git || true

   :log: --pop
}

- install_git_redhat()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push 'Installing rh-git227'

   yum -y install rh-git227 || true

   :file:ensure_nl_at_end /etc/profile.d/scl.sh          # Ensure file exists and ready to insert at beginning of line

   # Add source to file if not already present
   if ! grep -q '^source /opt/rh/rh-git227/enable' /etc/profile.d/scl.sh; then
      echo 'source /opt/rh/rh-git227/enable' >>/etc/profile.d/scl.sh
      chmod 755 /etc/profile.d/scl.sh
   fi

   :log: --pop
}
