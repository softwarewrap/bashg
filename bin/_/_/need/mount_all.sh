#!/bin/bash

:need:mount_all:()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Mounting files:' '/etc/fstab' "$FUNCNAME $@"

   local ___need__mount_all_____Before
   local ___need__mount_all_____After
   ___need__mount_all_____Before="$(mktemp)"
   ___need__mount_all_____After="$(mktemp)"

   mount 2>/dev/null | sort -f > "$___need__mount_all_____Before"
   mount -a >&/dev/null
   mount 2>/dev/null | sort -f > "$___need__mount_all_____After"

   if ! cmp --silent "$___need__mount_all_____Before" "$___need__mount_all_____After"; then
   :log: "Mount differences corrected:"
      diff "$___need__mount_all_____Before" "$___need__mount_all_____After"
   fi

   rm -f "$___need__mount_all_____Before" "$___need__mount_all_____After"

   :log: --pop
}
