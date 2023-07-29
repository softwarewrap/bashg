#!/bin/bash

.dev:need:python:()
{
   :sudo || :reenter                                     # This function must run as root

   local _dev__need__python_____Python
   _dev__need__python_____Python="$( readlink -f /usr/bin/python )"         # Get the real path to python

   if [[ $_dev__need__python_____Python = /usr/libexec/no-python && -n ${_dev___alias[python]} ]]; then
       alternatives --set python "${_dev___alias[python]}"  # If no-python, then set it to an acceptable version
   fi
}
