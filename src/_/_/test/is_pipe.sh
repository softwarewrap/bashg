#!/bin/bash

+ is_pipe%HELP()
{
   local (.)_Synopsis='Is true if stdin is coming from a pipe'
   :help: --set "$(.)_Synopsis" --usage '' <<EOF
DESCRIPTION:
   Return 0 if stdin is a pipe; return non-zero otherwise.

EXAMPLES:
   echo 'input' | $__ test:is_pipe; echo \$?    ^ Returns 0
   $__ __is_pipe; echo \$?                      ^ Returns non-zero

SCRIPTING EXAMPLE:
   if __is_pipe; then   ^# If this code is being executed in a pipeline,
      echo 'In a pipe'  ^# ... then emit this message.
   fi                   ^
EOF
}

+ is_pipe()
{
  # Assume file descriptor 0 if not otherwise specified
  local (.)_FD="${1:-0}"

  # /proc/self is the currently-running process
  # /proc/self/fd lists all file descriptors for the currently-running process
  # /proc/self/fd/0 is stdin for the currently-running process
  #
  # /dev/pts consists of pseudo-ttys and indicate that stdin is not a pipe
  # and can be accessed interactively with commands such as read.

  # If the canonical name for /proc/self/fd/0 is not a pseudo-tty, return 0
  ! [[ $(readlink -fm /proc/self/fd/$(.)_FD) =~ ^/dev/pts/[0-9] ]]
}
