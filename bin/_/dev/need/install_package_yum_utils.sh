#!/bin/bash

_dev:need:install_package_yum_utils:()
{
   if ! :test:has_package yum-utils; then
      :log: --push 'Installing yum-utils'

      yum -y install yum-utils

      :log: --pop
   fi
}
