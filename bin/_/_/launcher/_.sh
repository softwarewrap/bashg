#!/bin/bash

:launcher:%STARTUP-0()
{
   # Note: Launcher startup priorities should always be first (%STARTUP-0)
   local -g _whoami                                      # The current user
   local -g _env_var=                                    # The options environment variable name
   local -ig _return=                                    # Return status from commands

   _whoami="$(whoami)"
}

:launcher:()
{
   ###################################################
   # Must Have No Dependencies on %STARTUP Functions #
   ###################################################
   :launcher:_:PreStartup                                        # Do early declarations and satisfy basic requirements
   :launcher:_:ProcessOptions "$@"                               # Process options (return on failure)

   #######################################
   # Load Function-Specific Declarations #
   #######################################
   :launcher:_:Startup "${__launcher______Args[@]}"                          # Setup redirection; Run STARTUP functions

   #################################################
   # Execute Functions based on Command-Line Input #
   #################################################
   if [[ ${__launcher___Config[LoadOnly]} != true ]]; then
      :launcher:_:DispatchRequests "${__launcher______Args[@]}"              # Process the request
   fi

   ###############################
   # Perform an Orderly Shutdown #
   ###############################
   :launcher:_:Shutdown                                          # Run SHUTDOWN functions; Close redirection
}

:launcher:_:PreStartup()
{
   :get:os --var _os                                     # Get an associative array providing os (distro) information

   local -Ag __launcher___Config                                  # Launcher configuration parameters

   ### DEFAULT REENTRY AND DISPATCH DEFINITIONS
   local -g _entry_user="$(id -un "$UID")"               # The user corresponding to the current UID
   local -g _entry_group="$(id -gn "$_entry_user")"      # The group corresponding to the current user
   local -g _entry_home="$HOME"                          # The home corresponding to the current user
   local -g _entry_initial=true                          # Do some tasks only on initial entry (e.g, I/O redirection)

   local -ag _dispatch_methods=(
      [0]=standard
      [1]=funcargs
      [2]=funcargssetx
   )

   if [[ -f $_etc_dir/trace ]]; then
      local -gi _dispatch_method=2
   else
      local -gi _dispatch_method=0
   fi

   ### PERSIST THESE VARIABLES FOR USE BY :reenter
   local -a __launcher_____PreStartup___PersistVars=(
      __launcher___Config
      _whoami
      _entry_user
      _entry_group
      _entry_home
      _entry_initial
      _dispatch_method
   )

   local -Ag _entry_vars                                 # Keys are variables to be declared after :reenter
                                                         # Associative allows for unset _entry_vars[some_var]
                                                         # The value is unused at the present, but may be used later
   local __launcher_____PreStartup___PersistVar
   for __launcher_____PreStartup___PersistVar in "${__launcher_____PreStartup___PersistVars[@]}"; do
      eval _entry_vars[$__launcher_____PreStartup___PersistVar]=                 # Index is a variable to use on :reenter
   done

   ### ENVIRONMENT VARIABLES
   local -gx LESS="-X -F -r"

   if [[ ! :$PATH: =~ :/usr/local/bin: ]]; then
      PATH="${PATH%:}:/usr/local/bin"
   fi
}

:launcher:_:ProcessOptions()
{
   local -g __launcher______Edit=false                               # Interpret the function as a request to edit it
   local -g __launcher______EditBin=false                            # Interpret the function as a request to edit it
   local -g __launcher______Help=false                               # Interpret the function as a request for help on it

   local -ga __launcher______Args=()                                 # Store any remaining args in this variable

   _env_var="$( sed -e 's|.*|\U&|;s|[^A-Z0-9_]|_|g' <<<"$__" )_OPTIONS"
                                                         # Options Env Var is uppercase: <EXE>_OPTIONS

   :getopts: begin \
      -o '=:eEhu:x' \
      -l 'declare:,edit,edit-bin,help,log:,load-only,entryuser:,trace,no-color,stdout,mask-errors,shx:' \
      -- $( envsubst <<<"\$$_env_var" ) "$@"

   local __launcher_____ProcessOptions___Option                                      # Option letter or word
   local __launcher_____ProcessOptions___Value                                       # Value stores a value for options that take a value

   while :getopts: next __launcher_____ProcessOptions___Option __launcher_____ProcessOptions___Value; do
      case "$__launcher_____ProcessOptions___Option" in
      -=|--declare)     :launcher:_:ProcessOptions.declare "$__launcher_____ProcessOptions___Value";;
      -e|--edit)        __launcher______Edit=true;;
      -E|--edit-bin)    __launcher______Edit=true; __launcher______EditBin=true;;
      -h|--help)        __launcher______Help=true;;
      -u|--entryuser)   :launcher:_:ProcessOptions.entryuser "$__launcher_____ProcessOptions___Value";;
      -x|--trace)       :launcher:_:ProcessOptions.trace;;

      --log)            __launcher___Config[Log]="$(readlink -fm "$__launcher_____ProcessOptions___Value")";;
      --load-only)      __launcher___Config[LoadOnly]=true;;
      --no-color)       __launcher___Config[HasColor]=false;;
      --stdout)         __launcher___Config[DupLogToStdout]=true;;
      --mask-errors)    __launcher___Config[MaskErrors]=true;;    # Ignore errors as they happen
      --shx)            __launcher___Config[ShxPassword]="$__launcher_____ProcessOptions___Value";;

      *)          break;;
      esac
   done

   :getopts: end --save __launcher______Args                         # Save unused args

   if [[ -d ${__launcher___Config[pwd]} && -x ${__launcher___Config[pwd]} ]]; then
      cd "${__launcher___Config[pwd]}"
   fi
   if [[ -n ${__launcher___Config[bash.set]} ]]; then
      eval "$( base64 -d <<<"${__launcher___Config[bash.set]}" )"
   fi
   if [[ -n ${__launcher___Config[bash.shopt]} ]]; then
      eval "$( base64 -d <<<"${__launcher___Config[bash.shopt]}" )"
   fi
}

:launcher:_:ProcessOptions.declare()
{
   local __launcher_____ProcessOptions___Value="$1"
   local __launcher_____ProcessOptions___Options=( -g )                              # Always use the global namespace

   # See reenter.bash for how options are structured

   if [[ $__launcher_____ProcessOptions___Value =~ ^[a-zA-Z]+: ]]; then
      __launcher_____ProcessOptions___Options+=( "-${__launcher_____ProcessOptions___Value%%:*}" )               # Get the options prefix and form it into an option string
   fi

   __launcher_____ProcessOptions___Value="${__launcher_____ProcessOptions___Value#*:}"                           # Remove the options prefix

   if [[ $__launcher_____ProcessOptions___Options =~ r ]]; then                      # Readonly parameters cannot be re-declared
      :var:unsetro "${Value%%=*}"                        # Attempt to unset the read-only variable
   fi

   eval local "${__launcher_____ProcessOptions___Options[@]}" "$__launcher_____ProcessOptions___Value"           # Declare the variable to state before :reenter
}

:launcher:_:ProcessOptions.entryuser()
{
   _entry_user="$1"
   _entry_group="$(id -gn "$_entry_user")"
   eval _entry_home="~$_entry_user"                      # The home corresponding to the first-entry user
}

:launcher:_:ProcessOptions.trace()
{
   if (( _dispatch_method < ${#_dispatch_methods[@]} - 1 )); then
      _dispatch_method=$(( _dispatch_method + 1 ))
   fi
}

:launcher:_:Startup()
{
   local -a __launcher_____Startup___StartupFunctions

   :find:functions --meta STARTUP --var __launcher_____Startup___StartupFunctions
                                                         # Get ordered list of startup functions
   local __launcher_____Startup___StartupFunction
   for __launcher_____Startup___StartupFunction in "${__launcher_____Startup___StartupFunctions[@]}"; do
      "$__launcher_____Startup___StartupFunction" "$@"
   done

   # If not specified, set these configuration defaults
   local -A __launcher_____Startup___ConfigDefaults=(
      [HasColor]=true                                    # Color output is available
      [DupLogToStdout]=false                             # Send stdout/stderr to both the log file and stdout
      [Log]=                                             # Do not write to a log file (non-empty is the log file path)
      [LoadOnly]=false                                   # Load functions only; do not run the dispatcher
   )

   local __launcher_____Startup___ConfigDefault
   for __launcher_____Startup___ConfigDefault in "${!__launcher_____Startup___ConfigDefaults[@]}"; do
      if [[ -z ${__launcher___Config[$__launcher_____Startup___ConfigDefault]} ]]; then
         __launcher___Config[$__launcher_____Startup___ConfigDefault]="${__launcher_____Startup___ConfigDefaults[__launcher_____Startup___ConfigDefault]}"
      fi
   done

   :launcher:_:RedirectIO                                        # Define variables, redirection, and Bash settings

   :: require_jq                                         # jq is required for JSON parsing
}

:launcher:_:RedirectIO()
{
   $_entry_initial || return 0                           # Perform redirection only once

   local -gx GREP_OPTIONS=

   local -g _in=3                                        # Script duplicate of stdin
   local -g _out=4                                       # Script duplicate of stdout
   local -g _err=5                                       # Script duplicate of stderr
   local -g _data=6                                      # Script addition of a data file descriptor

   ######################################
   # Define Additional File Descriptors #
   ######################################
   [[ ${__launcher___Config[LoadOnly]} = true ]] || :launcher:OpenCustomFDs

   ################################
   # Perform Logging Redirections #
   ################################
   if [[ -n ${__launcher___Config[Log]} ]]; then                  # Writing to a log file has been requested
      if [[ ! -f ${__launcher___Config[Log]} ]]; then
         local __launcher_____RedirectIO___LogDir="$(dirname "${__launcher___Config[Log]}")"
      fi

      if [[ -w ${__launcher___Config[Log]} || ( ! -f ${__launcher___Config[Log]} && -w $(dirname "${__launcher___Config[Log]}") ) ]]; then
                                                         # Is the log file writable?
         if [[ ${__launcher___Config[DupLogToStdout]} = true ]]; then
                                                         # Yes. Now, should the output also go to stdout?
            exec > >( stdbuf -i0 -o0 -e0 tee -a -i >( sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >>"${__launcher___Config[Log]}" ) ) 2>&1
                                                         # Unbuffered tee to stdout/file; Remove color characters from log file


         else
            exec > >( stdbuf -i0 -o0 -e0 sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >>"${__launcher___Config[Log]}" ) 2>&1
                                                         # Now the revised stdout and stderr will go only to the log file
                                                         # Remove color characters from log file
         fi

         # See: https://stackoverflow.com/questions/30687504/redirected-output-hangs-when-using-tee
         sleep 0                                         # Workaround for blocking prompt
                                                         # Ensure stdout and stderr go to both stdout and the log file

      else
         :error: "Could not open log file for writing: ${__launcher___Config[Log]}"
      fi                                                 # The log file was not writable
   fi
}

:launcher:OpenCustomFDs()
{
   # FDs 3, 4, and 5 preserve original FDs as is needed when input/output are being redirected to the log file
   { <&3; } 2>/dev/null || exec 3<&0                     # 3: scrin:  Duplicate of stdin
   { >&4; } 2>/dev/null || exec 4>&1                     # 4: scrout: Duplicate of stdout
   { >&5; } 2>/dev/null || exec 5>&2                     # 5: screrr: Duplicate of stderr

   # Additional FDs to be used as needed
   { >&6; } 2>/dev/null || exec 6>/dev/null              # 6: Data payload file descriptor
   { >&7; } 2>/dev/null || exec 7>/dev/null              # 7: API-specific purpose
   { >&8; } 2>/dev/null || exec 8>/dev/null              # 8: API-specific purpose
   { >&9; } 2>/dev/null || exec 9>/dev/null              # 9: API-specific purpose
}

:launcher:CloseCustomFDs()
{
   exec 3<&-                                             # Close duplicate of stdin or user-provided input file
   exec 4>&-                                             # Close duplicate of stdout our user-provided output file
   exec 5>&-                                             # Close duplicate of stderr our user-provided output file
   exec 6>&-                                             # Close data payload file descriptor
   exec 7>&-                                             # Close API-specific file descriptor
   exec 8>&-                                             # Close API-specific file descriptor
   exec 9>&-                                             # Close API-specific file descriptor
}

:launcher:_:DispatchRequests()
{
   local -g _functions_json
   :json:jq _functions_json '.function' "$_etc_dir/functions.json"

   if $__launcher______Help || [[ $1 =~ ^/ ]]; then
      :help: "$@"

   elif (( $# == 0 )); then
      return 0

   elif [[ -f $1 ]]; then
      if [[ $1 = *.shx ]]; then
         if ! command 7za &>/dev/null; then
            :error: 'The command 7za is not installed'
            return 1

         elif [[ -n "${__launcher___Config[ShxPassword]}" ]]; then
            (
               local __launcher_____DispatchRequests___Dir="$(dirname "$1")"
               if [[ ${__launcher___Config[ShxPassword]} = - ]]; then
                  read -sp 'Password: ' __launcher___Config[ShxPassword]
                  echo
               fi
               7za e -y -o"$__launcher_____DispatchRequests___Dir" -p"${__launcher___Config[ShxPassword]}" "$1" &>/dev/null || true
            )

            if [[ -s ${1%.shx}.sh ]]; then
               echo "Unzipped: $1"
            else
               echo "Failed to unzip: $1"
               rm -f "${1%.shx}.sh"
               return 1
            fi

         else
            :error: "The option --shx must be used to unzip: $1"
            return 1
         fi
      fi

   elif :test:has_func "$1"; then
      if $__launcher______Edit; then
         local __launcher_____DispatchRequests___FunctionPath
         :json:jq __launcher_____DispatchRequests___FunctionPath -r ".\"$1\".path" <<<"$_functions_json"
         if $__launcher______EditBin; then
            vi "$(readlink -f "$_bin_dir/$__launcher_____DispatchRequests___FunctionPath")"
         else
            vi "$(readlink -f "$_lib_dir/$__launcher_____DispatchRequests___FunctionPath")"
         fi

      else

         if [[ ${__launcher___Config[MaskErrors]} = true ]]; then # Should errors be ignored?
            set +o errexit                               # Yes, ignore errexit
            set +o pipefail                              # Yes, ignore pipefail
         fi

         ":launcher:_:DispatchRequests.${_dispatch_methods[$_dispatch_method]}" "$@"
      fi

   elif [[ $1 = help ]]; then
      shift
      :help: "$@"

   else
      :error: "No such function: $1"
   fi
}

:launcher:_:DispatchRequests.standard()
{
   "$@"
}

:launcher:_:DispatchRequests.funcargs()
{
   :log: --push "$@"

   "$@"

   :log: --pop
}

:launcher:_:DispatchRequests.funcargssetx()
{
   :log: --push "$@"

   set -x
   "$@"
   set +x

   :log: --pop
}

:launcher:_:Shutdown()
{
   local -a __launcher_____Shutdown___ShutdownFunctions
   :find:functions --meta SHUTDOWN --var __launcher_____Shutdown___ShutdownFunctions

   local __launcher_____Shutdown___ShutdownFunction
   for __launcher_____Shutdown___ShutdownFunction in "${__launcher_____Shutdown___ShutdownFunctions[@]}"; do
      "$__launcher_____Shutdown___ShutdownFunction"
   done

   :launcher:CloseCustomFDs                                          # Close additional file descriptors

   # When using tee with multiple file descriptors, output synchronization problems may occur.
   # Running a trivial command in a subshell is a workaround to force correct synchronization so
   # that problems such as the prompt not showing up are avoided.
   if [[ -n ${__launcher___Config[Log]} && ${__launcher___Config[DupLogToStdout]} = true ]]; then
                                                         # The condition in which tee is used with multiple FDs
      $(true)
   fi
}

:launcher:_:BuildFunctionInfo%DEPRECATED()
{
   local -ga _functions
   readarray -t _functions < <(
      :json:jq - -r 'keys[]' <<<"$_functions_json"
   )

   local -Ag _function_to_path
   local -Ag _path_to_functions
   local __launcher_____BuildFunctionInfoDEPRECATED___function
   local __launcher_____BuildFunctionInfoDEPRECATED___Path
   for __launcher_____BuildFunctionInfoDEPRECATED___Function in "${_functions[@]}"; do
      :json:jq __launcher_____BuildFunctionInfoDEPRECATED___Path -r ".\"$__launcher_____BuildFunctionInfoDEPRECATED___Function\".path" <<<"$_functions_json"
      _function_to_path[$__launcher_____BuildFunctionInfoDEPRECATED___Function]="$__launcher_____BuildFunctionInfoDEPRECATED___Path"
      _path_to_functions[$__launcher_____BuildFunctionInfoDEPRECATED___Path]+="${_path_to_functions[$__launcher_____BuildFunctionInfoDEPRECATED___Path]:+ }$__launcher_____BuildFunctionInfoDEPRECATED___Function"
   done
}

:launcher:%TEST()
{
   :log: --push "RUNNING: :launcher:%TEST"
   :launcher:_:%TEST.dump 'Before :sudo || :reenter'

   :sudo || :reenter                                     # This function must run as root

   :log: --pop 'Running code following :sudo || :reenter'
}

:launcher:_:%TEST.dump()
{
   local __launcher_____TEST___Message="$1"

   echo
   printf '%0.s=' {1..40}
   echo " $__launcher_____TEST___Message"
   echo

   echo "Whoami:   $(whoami)"
   echo "PWD:      $(pwd)"
   echo

   local _entry_var
   for _entry_var in _entry_vars "${!_entry_vars[@]}"; do
      if [[ -v $_entry_var ]]; then
         declare -p "$_entry_var"
      fi
   done
}
