#!/bin/bash

:git:is_project_dir()
{
   local __git__is_project_dir__is_project_dir___ProjectDir="$1"

   git -C "$__git__is_project_dir__is_project_dir___ProjectDir" rev-parse --show-toplevel &>/dev/null
}
