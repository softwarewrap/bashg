#!/bin/bash

::init()
{
   local -g __program                                    # Full path to this script (for re-execution)
   local -g __                                           # Basename of this script
   local -g __base_dir                                   # Directory containing this script
   local -g __invocation_dir                             # The directory from which the script was invoked
   local -g __entry                                      # The entry function name

   __program="$(readlink -f "$BASH_SOURCE")"             # Get the canonical path to this script
   __="$(basename "$__program")"                         # Get the script basename
   __base_dir="$(dirname "$__program")"                  # base directory: where this script lives
   __invocation_dir="$(readlink -f .)"                   # Get the directory from which this script was called
   __entry="${FUNCNAME[1]}"                              # Get the entry function name

   set -o errexit                                        # Fail on any error
   set -o pipefail                                       # Fail on any pipe error
   set -o errtrace                                       # Enable error tracing
}
