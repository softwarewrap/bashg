#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   cd /usr/share/fonts

   if [[ -d lucida && -d msttcore && -d vera ]]; then
      return 0                                           # Fonts are already installed
   fi

   :log: --push-section 'Installing font files' "$FUNCNAME $@"

   ( cd (+:env)/@fonts; tar cpf - . ) | tar xpf -

   :log: --pop
}
