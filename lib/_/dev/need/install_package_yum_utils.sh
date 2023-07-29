#!/bin/bash

- ()
{
   if ! :test:has_package yum-utils; then
      :log: --push 'Installing yum-utils'

      yum -y install yum-utils

      :log: --pop
   fi
}
