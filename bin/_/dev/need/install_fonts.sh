#!/bin/bash

.dev:need:install_fonts:()
{
   :sudo || :reenter                                     # This function must run as root

   cd /usr/share/fonts

   [[ -d lucida && -d msttcore && -d vera ]] || return 0 # Fonts are already installed

   ( cd "$_lib_dir/_/dev/env"/@fonts; tar cpf - . ) | tar xpf -
}
