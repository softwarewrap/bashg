#!/bin/bash

@ :%STARTUP-0()
{
   local -Ag (@)_FuncNameMap                             # Define only once: cache for found functions
}

@ :%HELP()
{
   local (.)_Synopsis='Use indirection to execute functions'
   local (.)_Usage='[<OPTIONS>] <name>...'

   :help: --set "$(.)_Synopsis" --usage "$(.)_Usage" <<EOF
OPTIONS:
   -s|--search <prefix>    ^Add a function search <prefix> (optional and can be used more than once)
   -0|--no-error           ^It is not an error if no function match is found
   --has-func              ^Return 0 if any <name> is found; otherwise, return 1
   --show                  ^Only emit the function name to stdout that would be executed

DESCRIPTION:
   Search for and execute functions within a list of search paths

   SEARCH PATH:^<G
   1. The --search <prefix> items are searched first.

   2. Next, the <B>\(++:launcher)_Config[SearchPath]</B> associative array element, if present,
   is a space-separated string of <prefix> values to be used when searching for function-name matching.

   3. Finally, the system <B>:need:</B> path prefix is searched for commonly-needed functionality.

   Typically, <B>SearchPath</B> configuration additions are done in <b>%STARTUP[-<order>]</b> functions.
   For example, <B>proj</B> project-specific needs can be added by doing the following:

      proj/_.sh^<K
         @ %STARTUP-0()^
         {^
            \(++:launcher)_Config[SearchPath]+=' \(+:need):'^
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

@ :()
{
   local -g (.)_Args=()                                  # Store any remaining args in this variable

   :getopts: begin \
      -o 's:0' \
      -l 'search:,no-error,has-func,show' \
      -- "$@"

   local (.)_Option                                      # Option character or word
   local (.)_Value                                       # Value for options that take a value
   local (.)_EncounteredStopRequest=false                # encountered --: what follows is search taking args
   local (.)_ErrorOnNotFound=true                        # Default: error if the function is not found
   local (.)_HasFunc=false                               # Determine only if the function is found
   local (.)_HasFuncReturn=1                             # Assume that the function will not be found
   local (.)_Show=false                                  # Show any found functions instead of calling them

   while :getopts: next (.)_Option (.)_Value (.)_EncounteredStopRequest; do
                                                         # The stop request is true if -- is before the first <name>
      case "$(.)_Option" in
      -s|--search)   (-):AddSearch "$2";;
      -0|--no-error) (.)_ErrorOnNotFound=false;;
      --has-func)    (.)_HasFunc=true;;
      --show)        (.)_Show=true;;

      *)          break;;
      esac
   done

   :getopts: end --save (.)_Args                         # Save unused args
   set -- "${(.)_Args[@]}"

   if [[ -n ${(+:launcher)_Config[SearchPath]} ]]; then
      local (.)_SearchItem
      for (.)_SearchItem in ${(+:launcher)_Config[SearchPath]}; do
                                                         # Word splitting intended: space-separated string is list
         (-):AddSearch "$(.)_SearchItem"
      done
   fi

   (-):AddSearch '(+:need):'                            # Add the system search prefix :need:

   while (( $# > 0 )); do
      if [[ $1 = -- ]]; then                             # Non-initial --: what follows is <name> taking args
         (.)_EncounteredStopRequest=true                 # Save state: do not treat remaining args as search requests
         shift
         continue
      fi

      local (.)_Search="$1"                              # Process the next search item
      shift                                              # ... and shift it off of the positional array

      local (-)_Found="${(@)_FuncNameMap[$(.)_Search]}"  # See if the function name has already been found

      if [[ -z $(-)_Found ]]; then
         for (.)_Prefix in "${(-)_SearchList[@]}"; do
            (-):Find -- "$(.)_Prefix$(.)_Search:${_os[distro]}-" "-${_os[arch]}" || break
            (-):Find -- "$(.)_Prefix$(.)_Search:${_os[distro]}-" || break
            (-):Find --no-version "$(.)_Prefix$(.)_Search:${_os[distro]}" || break

            if ${_os[is-linux]}; then
               (-):Find -- "$(.)_Prefix$(.)_Search:linux-" "-${_os[arch]}" || break
               (-):Find -- "$(.)_Prefix$(.)_Search:linux-" || break
               (-):Find --no-version "$(.)_Prefix$(.)_Search:linux" || break
            fi

            (-):Find --no-version "$(.)_Prefix$(.)_Search:" || break
         done

         if [[ -n $(-)_Found ]]; then
            (@)_FuncNameMap[$(.)_Search]="$(-)_Found"    # Cache the found function to optimize future searches
         fi
      fi

      if $(.)_HasFunc && [[ -n $(-)_Found ]]; then       # If only looking for whether function exists
         return 0                                        # ... then return 0 as a match was found
      fi

      if $(.)_Show; then
         if $(.)_EncounteredStopRequest; then
            shift $#                                     # All remaining args would have been passed to the function
         fi

         if [[ -n $(-)_Found ]]; then
            echo "$(-)_Found"                            # Emit the function name, but only if found
         fi

         continue                                        # Take no further action when showing
      fi

      if [[ -z $(-)_Found ]]; then
         if $(.)_ErrorOnNotFound; then
            :error: --stacktrace 1 "Did not find a match function for the function search: $(.)_Search"

         else
            return 0
         fi
      fi

      if $(.)_EncounteredStopRequest; then
         "$(-)_Found" "$@"
         shift $#

      else
         "$(-)_Found"
      fi
   done
}

- Find()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'no-version' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Version=true
   while true ; do
      case "$1" in
      --no-version)  (.)_Version=false; shift;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local (.)_Prefix="$1"
   local (.)_Suffix="$2"

   if ! $(.)_Version && :test:has_func "$(.)_Prefix" ]]; then
      (-)_Found="$(.)_Prefix"
      return 1
   fi

   local -a (.)_Candidates
   readarray -t (.)_Candidates < <(
      compgen -A function "$(.)_Prefix" |
      { grep -Pe "^$(.)_Prefix[0-9.]+$(.)_Suffix$" || true; } |
      sed -e "s|^$(.)_Prefix||" -e "s|$(.)_Suffix$||" |
      sed '/^\s*$/d'
   )

   (( ${#(.)_Candidates[@]} > 0 )) || return 0

   for (.)_VersionType in minor-version major-version; do
      (-)_Found="$(
         {
            printf '%s\n' "${(.)_Candidates[@]}"
            echo "${_os[minor-version]} #MAX#"
         } |
         sort -V |
         sed '/#MAX#/,$d' |
         {
            if [[ $(.)_VersionType = major-version ]]; then
               sed '/\./d'
            else
               cat
            fi
         } |
         tail -1
      )"
      [[ -z $(-)_Found ]] || break
   done

   if [[ -n $(-)_Found ]]; then
      (-)_Found="$(.)_Prefix$(-)_Found$(.)_Suffix"
      return 1
   fi
}

- AddSearch()
{
   local (.)_Add="$1"

   if ! :array:has_element (-)_SearchList "$(.)_Add"; then
      (-)_SearchList+=( "$(.)_Add" )
   fi
}
