#!/bin/bash

@ return()
{
   _return="${1:-$?}"                                    # Get the status of the most recently-executed fg pipeline

   if [[ ! $_return =~ ^[0-9]+$ && $1 -ge 0 && $1 -le 255 ]]; then
      if [[ -v $_return && ${!_return} =~ ^[0-9]+$ && $1 -ge 0 && $1 -le 255 ]]; then
         _return="${!_return}"                           # Get the value from the variable

      else
         :error: 1 "Numeric argument or variable containing a numeric argument is required"
         _return=1
      fi
   fi

   return $_return
}
