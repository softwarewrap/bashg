#!/bin/bash

:assert()
{
   local __assert_____assert___TestName="$1"
   local __assert_____assert___Expect="$2"
   shift 2

   local -g __assert___Out

   local __assert_____assert___Tmp
   __assert_____assert___Tmp="$( mktemp )"

   "$@" > "$__assert_____assert___Tmp"

   __assert___Out="$( cat $__assert_____assert___Tmp )"
   rm -f "$__assert_____assert___Tmp"

   local __assert_____assert___Status=0
   eval "$__assert_____assert___Expect"  || __assert_____assert___Status=$?

   if (( $__assert_____assert___Status == 0 )); then
      :highlight: <<<"<G>PASS</G> $__assert_____assert___TestName"
   else
      :highlight: <<<"<R>FAIL</R> $@\n     <b>EXPECT:</b> <B>$__assert_____assert___Expect</B>\n     <b>   GOT:</b> <R>$__assert___Out</R>"
   fi
}
