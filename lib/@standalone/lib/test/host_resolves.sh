#!/bin/bash

:test:host_resolves()
{
   local __test__host_resolves__host_resolves___Host="$1"

   host "$__test__host_resolves__host_resolves___Host" &>/dev/null
}
