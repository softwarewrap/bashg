#!/bin/bash

_dev:need:install_package_epel_release:linux-6()
{
   :sudo || :reenter                                     # This function must run as root

   if ! _dev:need:install_package_epel_release:EPELisInstalled; then
      _dev:need:install_package_epel_release:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm'
   fi
}

_dev:need:install_package_epel_release:redhat-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! _dev:need:install_package_epel_release:EPELisInstalled; then
      _dev:need:install_package_epel_release:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

      local -a ___Options=(
         --enable='rhel-*-optional-rpms'
         --enable='rhel-*-extras-rpms'
      )
      subscription-manager repos "${___Options[@]}"
   fi
}

_dev:need:install_package_epel_release:centos-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! _dev:need:install_package_epel_release:EPELisInstalled; then
      _dev:need:install_package_epel_release:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
   fi
}

_dev:need:install_package_epel_release:redhat-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! _dev:need:install_package_epel_release:EPELisInstalled; then
      _dev:need:install_package_epel_release:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'

      local -a ___Options=(
         --enable "codeready-builder-for-rhel-8-$(arch)"
      )
      subscription-manager repos "${___Options[@]}"
      dnf config-manager --set-enabled PowerTools || true
   fi
}

_dev:need:install_package_epel_release:centos-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! _dev:need:install_package_epel_release:EPELisInstalled; then
      _dev:need:install_package_epel_release:InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'
   fi
}

_dev:need:install_package_epel_release:InstallEPEL()
{
   local _dev__need__install_package_epel_release__InstallEPEL___RPM="$1"

   :log: --push 'Installing epel-release'

   if ! yum -y install epel-release; then
      :log: 'Trying alternative approach to installing epel repository'

      yum -y install "$_dev__need__install_package_epel_release__InstallEPEL___RPM" &>/dev/null

      if ! _dev:need:install_package_epel_release:EPELisInstalled; then
         :error: 1 'Could not install the EPEL repository'
      fi
   fi

   :log: --pop
}

_dev:need:install_package_epel_release:EPELisInstalled()
{
   grep -hPo '^\[[^]]*\]' /etc/yum.repos.d/*.repo |      # Get all repo directives
   sed 's/^.\(.*\).$/\1/' |                              # Remove the brackets
   grep -q '^epel$'                                      # See if any of them is 'epel'
}
