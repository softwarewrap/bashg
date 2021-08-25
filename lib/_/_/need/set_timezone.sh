#!/bin/bash

- linux-6()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Timezone="${1:-America/New_York}"           # The default timezone

   rm -f /etc/localtime
   ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
}

- linux-7()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Timezone="${1:-America/New_York}"           # The default timezone

   local (.)_CurrentTimezone
   (.)_CurrentTimezone="$(
      timedatectl |
      { grep 'Time zone' || true; } |
      sed 's|.*Time zone: \([^ ]*\) .*|\1|'
   )"

   [[ $(.)_Timezone != $(.)_CurrentTimezone ]] || return 0

   :log: --push "Requesting timezone: $(.)_Timezone"

   if timedatectl list-timezones | grep "^$(.)_Timezone$" &>/dev/null; then
      timedatectl set-timezone "$(.)_Timezone"           # Change the timezone
      timedatectl status                                 # Show timezone status information

   else
      :error: 1 "Unrecognized timezone: $(.)_Timezone"
   fi

   :log: --pop
}
