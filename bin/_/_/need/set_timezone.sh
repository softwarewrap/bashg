#!/bin/bash

:need:set_timezone:linux-6()
{
   :sudo || :reenter                                     # This function must run as root

   local ___Timezone="${1:-America/New_York}"           # The default timezone

   rm -f /etc/localtime
   ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
}

:need:set_timezone:linux-7()
{
   :sudo || :reenter                                     # This function must run as root

   local ___Timezone="${1:-America/New_York}"           # The default timezone

   local ___CurrentTimezone
   ___CurrentTimezone="$(
      timedatectl |
      { grep 'Time zone' || true; } |
      sed 's|.*Time zone: \([^ ]*\) .*|\1|'
   )"

   [[ $___Timezone != $___CurrentTimezone ]] || return 0

   :log: --push-section "Requesting timezone: $___Timezone" "$FUNCNAME $@"

   if timedatectl list-timezones | grep "^$___Timezone$" &>/dev/null; then
      timedatectl set-timezone "$___Timezone"           # Change the timezone
      timedatectl status                                 # Show timezone status information

   else
      :error: 1 "Unrecognized timezone: $___Timezone"
   fi

   :log: --pop
}
