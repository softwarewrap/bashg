#!/bin/bash

.dev:need:mount_all:()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Mounting files:' '/etc/fstab' "$FUNCNAME $@"

   local _dev__need__mount_all_____Before
   local _dev__need__mount_all_____After
   _dev__need__mount_all_____Before="$(mktemp)"
   _dev__need__mount_all_____After="$(mktemp)"

   mount 2>/dev/null | sort -f > "$_dev__need__mount_all_____Before"
   mount -a >&/dev/null
   mount 2>/dev/null | sort -f > "$_dev__need__mount_all_____After"

   if ! cmp --silent "$_dev__need__mount_all_____Before" "$_dev__need__mount_all_____After"; then
   :log: "Mount differences corrected:"
      diff "$_dev__need__mount_all_____Before" "$_dev__need__mount_all_____After"
   fi

   rm -f "$_dev__need__mount_all_____Before" "$_dev__need__mount_all_____After"

   :log: --pop
}
