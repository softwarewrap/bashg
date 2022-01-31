#!/bin/bash

:yum:package_exists()
{
   :sudo || :reenter                                     # This function must run as root

   yum list all "$@" &>/dev/null
}
