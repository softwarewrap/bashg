#!/bin/bash

- linux-9()
{
   :sudo || :reenter                                     # This function must run as root

   ! (-):EPELisInstalled || return 0

   :log: --push-section 'Require EPEL on Linux 9' "$FUNCNAME $@"

   dnf config-manager --set-enabled crb

   local -a (.)_Packages=(
      https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
      https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm
   )

   dnf -y install "${(.)_Packages[@]}"

   :log: --pop
}

- redhat-8()
{
   :sudo || :reenter                                     # This function must run as root

   ! (-):EPELisInstalled || return 0

   :log: --push-section 'Require EPEL on RHEL 8' "$FUNCNAME $@"

   (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'

   local -a (.)_Options=(
      --enable "codeready-builder-for-rhel-8-$(arch)-rpms"
   )
   subscription-manager repos "${(.)_Options[@]}"
   dnf config-manager --set-enabled PowerTools 2>/dev/null || true

   :log: --pop
}

- linux-8()
{
   :sudo || :reenter                                     # This function must run as root

   ! (-):EPELisInstalled || return 0

   :log: --push-section 'Require EPEL on Linux 8' "$FUNCNAME $@"

   (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm'

   :log: --pop
}

- redhat-7()
{
   :sudo || :reenter                                     # This function must run as root

   ! (-):EPELisInstalled || return 0

   :log: --push-section 'Require EPEL on RHEL 7' "$FUNCNAME $@"

   (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

   local -a (.)_Options=(
      --enable='rhel-*-optional-rpms'
      --enable='rhel-*-extras-rpms'
   )
   subscription-manager repos "${(.)_Options[@]}"

   :log: --pop
}

- linux-7()
{
   :sudo || :reenter                                     # This function must run as root

   ! (-):EPELisInstalled || return 0

   :log: --push-section 'Require EPEL on Linux 7' "$FUNCNAME $@"

   (-):InstallEPEL 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

   :log: --pop
}

- InstallEPEL()
{
   local (.)_RPM="$1"

   :log: --push 'Installing epel-release'

   # Try an alternative approach if the epel-release package doesn't exist or if the installation fails
   if ! (+:yum):package_exists epel-release || ! yum -y install epel-release 2>/dev/null; then
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
