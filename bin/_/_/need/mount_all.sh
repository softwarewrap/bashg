#!/bin/bash

:need:mount_all:()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Mounting files:' '/etc/fstab' "$FUNCNAME $@"

   local __need__mount_all_____Before
   local __need__mount_all_____After
   __need__mount_all_____Before="$(mktemp)"
   __need__mount_all_____After="$(mktemp)"

   mount 2>/dev/null | sort -f > "$__need__mount_all_____Before"
   mount -a >&/dev/null
   mount 2>/dev/null | sort -f > "$__need__mount_all_____After"

   if ! cmp --silent "$__need__mount_all_____Before" "$__need__mount_all_____After"; then
   :log: "Mount differences corrected:"
      diff "$__need__mount_all_____Before" "$__need__mount_all_____After"
   fi

   rm -f "$__need__mount_all_____Before" "$__need__mount_all_____After"

   :log: --pop
}
