#!/bin/bash

:need:require_epel:linux-6()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm'
   fi
}

:need:require_epel:redhat-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

      local -a ___Options=(
         --enable='rhel-*-optional-rpms'
         --enable='rhel-*-extras-rpms'
      )
      subscription-manager repos "${___Options[@]}"
   fi
}

:need:require_epel:centos-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
   fi
}

:need:require_epel:redhat-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'

      local -a ___Options=(
         --enable "codeready-builder-for-rhel-8-$(arch)"
      )
      subscription-manager repos "${___Options[@]}"
      dnf config-manager --set-enabled PowerTools || true
   fi
}

:need:require_epel:centos-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! :need:require_epel:EPELisInstalled; then
      :need:require_epel:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'
   fi
}

:need:require_epel:InstallEPEL()
{
   local __need__require_epel__InstallEPEL___RPM="$1"

   :log: --push 'Installing epel-release'

   if ! yum -y install epel-release; then
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
