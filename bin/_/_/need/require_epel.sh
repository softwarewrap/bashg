#!/bin/bash

:need:require_epel:redhat-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :log: --push-section 'Require EPEL on RHEL 7' "$FUNCNAME $@"

      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

      local -a ___Options=(
         --enable='rhel-*-optional-rpms'
         --enable='rhel-*-extras-rpms'
      )
      subscription-manager repos "${___Options[@]}"

      :log: --pop
   fi
}

:need:require_epel:centos-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :log: --push-section 'Require EPEL on CentOS 7' "$FUNCNAME $@"

      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

      :log: --pop
   fi
}

:need:require_epel:redhat-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :log: --push-section 'Require EPEL on RHEL 8' "$FUNCNAME $@"

      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'

      local -a ___Options=(
         --enable "codeready-builder-for-rhel-8-$(arch)-rpms"
      )
      subscription-manager repos "${___Options[@]}"
      dnf config-manager --set-enabled PowerTools 2>/dev/null || true

      :log: --pop
   fi
}

:need:require_epel:centos-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :log: --push-section 'Require EPEL on CentOS 8' "$FUNCNAME $@"

      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'

      :log: --pop
   fi
}

:need:require_epel:InstallEPEL()
{
   local __need__require_epel__InstallEPEL___RPM="$1"

   :log: --push 'Installing epel-release'

   # Try an alternative approach if the epel-release package doesn't exist or if the installation fails
   if ! :yum:package_exists epel-release || ! yum -y install epel-release 2>/dev/null; then
      :log: 'Trying alternative approach to installing epel repository'

      yum -y install "$__need__require_epel__InstallEPEL___RPM" &>/dev/null

      if ! :need:require_epel:EPELisInstalled; then
         :error: 1 'Could not install the EPEL repository'
      fi
   fi

   :log: --pop
}

:need:require_epel:EPELisInstalled()
{
   grep -hPo '^\[[^]]*\]' /etc/yum.repos.d/*.repo |      # Get all repo directives
   sed 's/^.\(.*\).$/\1/' |                              # Remove the brackets
   grep -q '^epel$'                                      # See if any of them is 'epel'
}
