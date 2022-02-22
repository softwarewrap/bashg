#!/bin/bash

+ host_resolves()
{
   local (.)_Host="$1"

   host "$(.)_Host" &>/dev/null
}
