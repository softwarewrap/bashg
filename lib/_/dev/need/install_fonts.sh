#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   cd /usr/share/fonts

   [[ -d lucida && -d msttcore && -d vera ]] || return 0 # Fonts are already installed

   ( cd (+)/@fonts; tar cpf - . ) | tar xpf -
}
