#!/bin/bash

- ()
{
   :sudo || :reenter                                     # This function must run as root

   local (.)_Python
   (.)_Python="$( readlink -f /usr/bin/python )"         # Get the real path to python

   if [[ $(.)_Python = /usr/libexec/no-python && -n ${(@)_alias[python]} ]]; then
       alternatives --set python "${(@)_alias[python]}"  # If no-python, then set it to an acceptable version
   fi
}
