#!/bin/bash

@ sudo%STARTUP-0()
{
   local -g _RunAs=                                      # The user to run as
}

@ sudo%HELP()
{
   local (.)_Synopsis='Check or elevate permissions'
   local (.)_Usage='[<user> [<command> [<args>]]]'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
DESCRIPTION:
   Check if privilege elevation is required or run a command with privilege elevation

CHECK/REENTER:
   If no arguments are provided, then <user> is taken to be <B>root</B>.

   If <user> is defined without specifying a <command>, then it <R>must</R> be used as follows:

      :sudo [<user>] || :reenter^

   The above is normally the first line in a function that needs privilege elevation.

   If the user is already the specified <user>, then control flows to the next command.

   If the user is not the specified <user>, then the function is reentered as the specified user.
   This is done by re-entering $__ with parameters that have been added to the <B>_entry_vars</B>
   associative array variable as keys (the value can be the empty string and is not presently used).

SINGLE COMMAND:
   If a <command> and possibly <args> are specified, then the command is run as the
   indicated user.

   The <command> can either be a function understood by $__ or an external command.
   A function match is checked first, then an external command.
   An error is returned if neither exists.

RETURN STATUS:
   0  Success
   1  No such user
   2  Sudo elevation is not available
   3  No such command

EXAMPLES:
   :sudo || :reenter             ^Run the function that follows as root (normally the first line)
   :sudo tom || :reenter         ^Run the function that follows as <B>tom</B> (normally the first line)
   :sudo tom whoami              ^Run an external command with no arguments
   :sudo tom :git:reset main     ^Run an internal function and arguments <B>:git:reset main</B> as the user <B>tom</B>
EOF
}

@ sudo()
{
   if (( $# <= 1 )); then
      _RunAs="${1:-root}"                                # Works in tandem with: || _reenter
      return 1                                           # Required to trigger the || handling
   fi

   _RunAs="$1"                                           # Store the user to run as
   shift                                                 # And shift it off of the stack, leaving <command> [<args>]

   if ! id "$_RunAs" &>/dev/null; then                   # Ensure that the user exists
      :error: 1 "No such user: $_RunAs"
      return
   fi

   if [[ $_RunAs = $_whoami ]]; then
      "$@"                                               # Run the command as is: no privilege elevation needed

   elif :test:can_sudo; then                             # If sudo access is available
      if :test:has_func "$1"; then
         (+:launcher)_Config[reenter]="$1"               # Set the reenter function
         shift                                           # ... and remove it from the positional array

         :reenter                                        # Reenter as _RunAs and call the indicated function w/args

      elif :test:has_command "$1"; then
         sudo -u "$_RunAs" "$@"                          # ... then run the requested command

      else
         :error: 3 "No such command: $1"
         return
      fi

   else
      :error 2 'Sudo elevation is not available'
      return
   fi
}
