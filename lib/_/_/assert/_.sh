#!/bin/bash

@ assert()
{
   local (.)_TestName="$1"
   local (.)_Expect="$2"
   shift 2

   local -g (+)_Out

   local (.)_Tmp
   (.)_Tmp="$( mktemp )"

   "$@" > "$(.)_Tmp"

   (+)_Out="$( cat $(.)_Tmp )"
   rm -f "$(.)_Tmp"

   local (.)_Status=0
   eval "$(.)_Expect"  || (.)_Status=$?

   if (( $(.)_Status == 0 )); then
      :highlight: <<<"<G>PASS</G> $(.)_TestName"
   else
      :highlight: <<<"<R>FAIL</R> $@\n     <b>EXPECT:</b> <B>$(.)_Expect</B>\n     <b>   GOT:</b> <R>$(+)_Out</R>"
   fi
}
