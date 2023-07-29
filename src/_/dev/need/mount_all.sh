#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Mounting files:' '/etc/fstab' "$FUNCNAME $@"

   local (.)_Before
   local (.)_After
   (.)_Before="$(mktemp)"
   (.)_After="$(mktemp)"

   mount 2>/dev/null | sort -f > "$(.)_Before"
   mount -a >&/dev/null
   mount 2>/dev/null | sort -f > "$(.)_After"

   if ! cmp --silent "$(.)_Before" "$(.)_After"; then
   :log: "Mount differences corrected:"
      diff "$(.)_Before" "$(.)_After"
   fi

   rm -f "$(.)_Before" "$(.)_After"

   :log: --pop
}
