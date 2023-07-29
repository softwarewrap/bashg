#!/bin/bash

+ is_project_dir()
{
   local (.)_ProjectDir="$1"

   git -C "$(.)_ProjectDir" rev-parse --show-toplevel &>/dev/null
}
