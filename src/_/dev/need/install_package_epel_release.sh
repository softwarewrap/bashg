#!/bin/bash

- linux-6()
{
   :sudo || :reenter                                     # This function must run as root

   if ! (-):EPELisInstalled; then
      (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm'
   fi
}

- redhat-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! (-):EPELisInstalled; then
      (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

      local -a (.)_Options=(
         --enable='rhel-*-optional-rpms'
         --enable='rhel-*-extras-rpms'
      )
      subscription-manager repos "${(.)_Options[@]}"
   fi
}

- centos-7()
{
   :sudo || :reenter                                     # This function must run as root

   if ! (-):EPELisInstalled; then
      (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
   fi
}

- redhat-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! (-):EPELisInstalled; then
      (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'

      local -a (.)_Options=(
         --enable "codeready-builder-for-rhel-8-$(arch)"
      )
      subscription-manager repos "${(.)_Options[@]}"
      dnf config-manager --set-enabled PowerTools || true
   fi
}

- centos-8()
{
   :sudo || :reenter                                     # This function must run as root

   if ! (-):EPELisInstalled; then
      (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'
   fi
}

- InstallEPEL()
{
   local (.)_RPM="$1"

   :log: --push 'Installing epel-release'

   if ! yum -y install epel-release; then
      :log: 'Trying alternative approach to installing epel repository'

      yum -y install "$(.)_RPM" &>/dev/null

      if ! (-):EPELisInstalled; then
         :error: 1 'Could not install the EPEL repository'
      fi
   fi

   :log: --pop
}

- EPELisInstalled()
{
   grep -hPo '^\[[^]]*\]' /etc/yum.repos.d/*.repo |      # Get all repo directives
   sed 's/^.\(.*\).$/\1/' |                              # Remove the brackets
   grep -q '^epel$'                                      # See if any of them is 'epel'
}
