#!/bin/bash

::%STARTUP-0()
{
   local -Ag ___FuncNameMap                             # Define only once: cache for found functions
}

::%HELP()
{
   local ___Synopsis='Use indirection to execute functions'
   local ___Usage='[<OPTIONS>] <name>...'

   :help: --set "$___Synopsis" --usage "$___Usage" <<EOF
OPTIONS:
   -s|--search <prefix>    ^Add a function search <prefix> (optional and can be used more than once)
   -0|--no-error           ^It is not an error if no function match is found
   --has-func              ^Return 0 if any <name> is found; otherwise, return 1
   --show                  ^Only emit the function name to stdout that would be executed

DESCRIPTION:
   Search for and execute functions within a list of search paths

   SEARCH PATH:^<G
   1. The --search <prefix> items are searched first.

   2. Next, the <B>(++:launcher)_Config[SearchPath]</B> associative array element, if present,
   is a space-separated string of <prefix> values to be used when searching for function-name matching.

   3. Finally, the system <B>:need:</B> path prefix is searched for commonly-needed functionality.

   Typically, <B>SearchPath</B> configuration additions are done in <b>%STARTUP[-<order>]</b> functions.
   For example, <B>proj</B> project-specific needs can be added by doing the following:

      proj/_.sh^<K
         @ %STARTUP-0()^
         {^
            (++:launcher)_Config[SearchPath]+=' (+:need):'^
         }^

   EXECUTION:^<G
   <name> arguments are processed in the order presented and search the <B>SearchPath</B> for a matching function.
   If --no-error is specified, then <B>0</B> is returned if no function match is found.
   Found functions are called without arguments unless <B>--</B> is encountered.

   If <name> is <B>--</B>, then the next <name> is the search name and <u>all remaining arguments</u>
   are passed to the found function.

   If --show is specified, then any found function name is emitted to stdout.

   SEARCH ORDER:^<G
   The search order for matching functions is (highest-priority first):

      <prefix>:<name>:<distro>-<version>-<arch>    ^>KVersion can be either a minor version or a major version
      <prefix>:<name>:<distro>-<version>
      <prefix>:<name>:<distro>

      <prefix>:<name>:linux-<version>-<arch>       ^>KOnly searched if <is-linux> is true
      <prefix>:<name>:linux-<version>              ^>KOnly searched if <is-linux> is true
      <prefix>:<name>:linux                        ^>KOnly searched if <is-linux> is true

      <prefix>:<name>:

   To illustrate, for the component-level <prefix> <B>proj:dothis:</B>,
   the possible unit-level function matches on this machine would include:

      FUNCTION NAME EXAMPLE^<K
      ^^proj:dothis:${_os[distro]}-${_os[minor-version]}-${_os[arch]}
      ^^proj:dothis:${_os[distro]}-${_os[major-version]}-${_os[arch]}
      ^^proj:dothis:${_os[distro]}-${_os[minor-version]}
      ^^proj:dothis:${_os[distro]}-${_os[major-version]}
      ^^proj:dothis:${_os[distro]}

      ^^proj:dothis:linux-${_os[minor-version]}-${_os[arch]}
      ^^proj:dothis:linux-${_os[major-version]}-${_os[arch]}
      ^^proj:dothis:linux-${_os[minor-version]}
      ^^proj:dothis:linux-${_os[major-version]}
      ^^proj:dothis:linux

      ^^proj:dothis:

   It is a best practice to have the <name> be a component-level function with unit-level possible matches.

EXAMPLES:
   :: git wget                      ^Ensure that git and wget are installed
   :: -- jq --version 1.6           ^Ensure that jq version 1.6 is installed
   :: git wget -- jq --version 1.6  ^Do both of the above

SEE:
   :get:os  ^$( :help: --synopsis :get:os )
EOF
}

::()
{
   local -g ___Args=()                                  # Store any remaining args in this variable

   :getopts: begin \
      -o 's:0' \
      -l 'search:,no-error,has-func,show' \
      -- "$@"

   local ___Option                                      # Option character or word
   local ___Value                                       # Value for options that take a value
   local ___EncounteredStopRequest=false                # encountered --: what follows is search taking args
   local ___ErrorOnNotFound=true                        # Default: error if the function is not found
   local ___HasFunc=false                               # Determine only if the function is found
   local ___HasFuncReturn=1                             # Assume that the function will not be found
   local ___Show=false                                  # Show any found functions instead of calling them

   while :getopts: next ___Option ___Value ___EncounteredStopRequest; do
                                                         # The stop request is true if -- is before the first <name>
      case "$___Option" in
      -s|--search)   :::AddSearch "$2";;
      -0|--no-error) ___ErrorOnNotFound=false;;
      --has-func)    ___HasFunc=true;;
      --show)        ___Show=true;;

      *)          break;;
      esac
   done

   :getopts: end --save ___Args                         # Save unused args
   set -- "${___Args[@]}"

   if [[ -n ${__launcher___Config[SearchPath]} ]]; then
      local ___SearchItem
      for ___SearchItem in ${__launcher___Config[SearchPath]}; do
                                                         # Word splitting intended: space-separated string is list
         :::AddSearch "$___SearchItem"
      done
   fi

   :::AddSearch ':need:'                            # Add the system search prefix :need:

   while (( $# > 0 )); do
      if [[ $1 = -- ]]; then                             # Non-initial --: what follows is <name> taking args
         ___EncounteredStopRequest=true                 # Save state: do not treat remaining args as search requests
         shift
         continue
      fi

      local ___Search="$1"                              # Process the next search item
      shift                                              # ... and shift it off of the positional array

      local _______Found="${___FuncNameMap[$___Search]}"  # See if the function name has already been found

      if [[ -z $_______Found ]]; then
         for ___Prefix in "${_______SearchList[@]}"; do
            :::Find -- "$___Prefix$___Search:${_os[distro]}-" "-${_os[arch]}" || break
            :::Find -- "$___Prefix$___Search:${_os[distro]}-" || break
            :::Find --no-version "$___Prefix$___Search:${_os[distro]}" || break

            if ${_os[is-linux]}; then
               :::Find -- "$___Prefix$___Search:linux-" "-${_os[arch]}" || break
               :::Find -- "$___Prefix$___Search:linux-" || break
               :::Find --no-version "$___Prefix$___Search:linux" || break
            fi

            :::Find --no-version "$___Prefix$___Search:" || break
         done

         if [[ -n $_______Found ]]; then
            ___FuncNameMap[$___Search]="$_______Found"    # Cache the found function to optimize future searches
         fi
      fi

      if $___HasFunc && [[ -n $_______Found ]]; then       # If only looking for whether function exists
         return 0                                        # ... then return 0 as a match was found
      fi

      if $___Show; then
         if $___EncounteredStopRequest; then
            shift $#                                     # All remaining args would have been passed to the function
         fi

         if [[ -n $_______Found ]]; then
            echo "$_______Found"                            # Emit the function name, but only if found
         fi

         continue                                        # Take no further action when showing
      fi

      if [[ -z $_______Found ]]; then
         if $___ErrorOnNotFound; then
            :error: --stacktrace 1 "Did not find a match function for the function search: $___Search"

         else
            return 0
         fi
      fi

      if $___EncounteredStopRequest; then
         "$_______Found" "$@"
         shift $#

      else
         "$_______Found"
      fi
   done
}

:::Find()
{
   local ____RESOLVE__Find___Options
   ____RESOLVE__Find___Options=$(getopt -o '' -l 'no-version' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$____RESOLVE__Find___Options"

   local ____RESOLVE__Find___Version=true
   while true ; do
      case "$1" in
      --no-version)  ____RESOLVE__Find___Version=false; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local ____RESOLVE__Find___Prefix="$1"
   local ____RESOLVE__Find___Suffix="$2"

   if ! $____RESOLVE__Find___Version && :test:has_func "$____RESOLVE__Find___Prefix" ]]; then
      _______Found="$____RESOLVE__Find___Prefix"
      return 1
   fi

   local -a ____RESOLVE__Find___Candidates
   readarray -t ____RESOLVE__Find___Candidates < <(
      compgen -A function "$____RESOLVE__Find___Prefix" |
      { grep -Pe "^$____RESOLVE__Find___Prefix[0-9.]+$____RESOLVE__Find___Suffix$" || true; } |
      sed -e "s|^$____RESOLVE__Find___Prefix||" -e "s|$____RESOLVE__Find___Suffix$||" |
      sed '/^\s*$/d'
   )

   (( ${#____RESOLVE__Find___Candidates[@]} > 0 )) || return 0

   for ____RESOLVE__Find___VersionType in minor-version major-version; do
      _______Found="$(
         {
            printf '%s\n' "${____RESOLVE__Find___Candidates[@]}"
            echo "${_os[minor-version]} #MAX#"
         } |
         sort -V |
         sed '/#MAX#/,$d' |
         {
            if [[ $____RESOLVE__Find___VersionType = major-version ]]; then
               sed '/\./d'
            else
               cat
            fi
         } |
         tail -1
      )"
      [[ -z $_______Found ]] || break
   done

   if [[ -n $_______Found ]]; then
      _______Found="$____RESOLVE__Find___Prefix$_______Found$____RESOLVE__Find___Suffix"
      return 1
   fi
}

:::AddSearch()
{
   local ____RESOLVE__AddSearch___Add="$1"

   if ! :array:has_element _______SearchList "$____RESOLVE__AddSearch___Add"; then
      _______SearchList+=( "$____RESOLVE__AddSearch___Add" )
   fi
}
