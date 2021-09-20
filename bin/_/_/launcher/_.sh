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
   :launcher:_:Startup "${___launcher______Args[@]}"                          # Setup redirection; Run STARTUP functions

   #################################################
   # Execute Functions based on Command-Line Input #
   #################################################
   :launcher:_:DispatchRequests "${___launcher______Args[@]}"                 # Process the request

   ###############################
   # Perform an Orderly Shutdown #
   ###############################
   :launcher:_:Shutdown                                          # Run SHUTDOWN functions; Close redirection
}

:launcher:_:PreStartup()
{
   :get:os --var _os                                     # Get an associative array providing os (distro) information

   local -Ag ___launcher___Config                                  # Launcher configuration parameters

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
   local -a ___launcher_____PreStartup___PersistVars=(
      ___launcher___Config
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
   local ___launcher_____PreStartup___PersistVar
   for ___launcher_____PreStartup___PersistVar in "${___launcher_____PreStartup___PersistVars[@]}"; do
      eval _entry_vars[$___launcher_____PreStartup___PersistVar]=                 # Index is a variable to use on :reenter
   done

   ### ENVIRONMENT VARIABLES
   local -gx LESS="-X -F -r"
}

:launcher:_:ProcessOptions()
{
   local -g ___launcher______Edit=false                               # Interpret the function as a request to edit it
   local -g ___launcher______EditBin=false                            # Interpret the function as a request to edit it
   local -g ___launcher______Help=false                               # Interpret the function as a request for help on it

   local -ga ___launcher______Args=()                                 # Store any remaining args in this variable

   _env_var="$( sed -e 's|.*|\U&|;s|[^A-Z0-9_]|_|g' <<<"$__" )_OPTIONS"
                                                         # Options Env Var is uppercase: <EXE>_OPTIONS

   :getopts: begin \
      -o '=:eEhu:x' \
      -l 'declare:,edit,edit-bin,help,log:,entryuser:,trace,no-color,stdout,mask-errors' \
      -- $( envsubst <<<"\$$_env_var" ) "$@"

   local ___launcher_____ProcessOptions___Option                                      # Option letter or word
   local ___launcher_____ProcessOptions___Value                                       # Value stores a value for options that take a value

   while :getopts: next ___launcher_____ProcessOptions___Option ___launcher_____ProcessOptions___Value; do
      case "$___launcher_____ProcessOptions___Option" in
      -=|--declare)     :launcher:_:ProcessOptions.declare "$___launcher_____ProcessOptions___Value";;
      -e|--edit)        ___launcher______Edit=true;;
      -E|--edit-bin)    ___launcher______Edit=true; ___launcher______EditBin=true;;
      -h|--help)        ___launcher______Help=true;;
      -u|--entryuser)   :launcher:_:ProcessOptions.entryuser "$___launcher_____ProcessOptions___Value";;
      -x|--trace)       :launcher:_:ProcessOptions.trace;;

      --log)            ___launcher___Config[Log]="$(readlink -fm "$___launcher_____ProcessOptions___Value")";;
      --no-color)       ___launcher___Config[HasColor]=false;;
      --stdout)         ___launcher___Config[DupLogToStdout]=true;;
      --mask-errors)    ___launcher___Config[MaskErrors]=true;;    # Ignore errors as they happen

      *)          break;;
      esac
   done

   :getopts: end --save ___launcher______Args                         # Save unused args

   if [[ -d ${___launcher___Config[pwd]} && -x ${___launcher___Config[pwd]} ]]; then
      cd "${___launcher___Config[pwd]}"
   fi
   if [[ -n ${___launcher___Config[bash.set]} ]]; then
      eval "$( base64 -d <<<"${___launcher___Config[bash.set]}" )"
   fi
   if [[ -n ${___launcher___Config[bash.shopt]} ]]; then
      eval "$( base64 -d <<<"${___launcher___Config[bash.shopt]}" )"
   fi
}

:launcher:_:ProcessOptions.declare()
{
   local ___launcher_____ProcessOptions___Value="$1"
   local ___launcher_____ProcessOptions___Options=( -g )                              # Always use the global namespace

   # See reenter.bash for how options are structured

   if [[ $___launcher_____ProcessOptions___Value =~ ^[a-zA-Z]+: ]]; then
      ___launcher_____ProcessOptions___Options+=( "-${___launcher_____ProcessOptions___Value%%:*}" )               # Get the options prefix and form it into an option string
   fi

   ___launcher_____ProcessOptions___Value="${___launcher_____ProcessOptions___Value#*:}"                           # Remove the options prefix

   if [[ $___launcher_____ProcessOptions___Options =~ r ]]; then                      # Readonly parameters cannot be re-declared
      :var:unsetro "${Value%%=*}"                        # Attempt to unset the read-only variable
   fi

   eval local "${___launcher_____ProcessOptions___Options[@]}" "$___launcher_____ProcessOptions___Value"           # Declare the variable to state before :reenter
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
   local -a ___launcher_____Startup___StartupFunctions

   :find:functions --meta STARTUP --var ___launcher_____Startup___StartupFunctions
                                                         # Get ordered list of startup functions
   local ___launcher_____Startup___StartupFunction
   for ___launcher_____Startup___StartupFunction in "${___launcher_____Startup___StartupFunctions[@]}"; do
      "$___launcher_____Startup___StartupFunction" "$@"
   done

   # If not specified, set these configuration defaults
   local -A ___launcher_____Startup___ConfigDefaults=(
      [HasColor]=true                                    # Color output is available
      [DupLogToStdout]=false                             # Send stdout/stderr to both the log file and stdout
      [Log]=                                             # Do not write to a log file (non-empty is the log file path)
   )

   local ___launcher_____Startup___ConfigDefault
   for ___launcher_____Startup___ConfigDefault in "${!___launcher_____Startup___ConfigDefaults[@]}"; do
      if [[ -z ${___launcher___Config[$___launcher_____Startup___ConfigDefault]} ]]; then
         ___launcher___Config[$___launcher_____Startup___ConfigDefault]="${___launcher_____Startup___ConfigDefaults[___launcher_____Startup___ConfigDefault]}"
      fi
   done

   :launcher:_:RedirectIO                                        # Define variables, redirection, and Bash settings

   :test:has_command jq || :require:packages epel-release
   :require:packages jq                                  # These packages must be installed to continue
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
   # FDs 3, 4, and 5 preserve original FDs as is needed when input/output are being redirected to the log file
   { <&3; } 2>/dev/null || exec 3<&0                     # 3: scrin:  Duplicate of stdin
   { >&4; } 2>/dev/null || exec 4>&1                     # 4: scrout: Duplicate of stdout
   { >&5; } 2>/dev/null || exec 5>&2                     # 5: screrr: Duplicate of stderr

   # Additional FDs to be used as needed
   { >&6; } 2>/dev/null || exec 6>/dev/null              # 6: Data payload file descriptor
   { >&7; } 2>/dev/null || exec 7>/dev/null              # 7: API-specific purpose
   { >&8; } 2>/dev/null || exec 8>/dev/null              # 8: API-specific purpose
   { >&9; } 2>/dev/null || exec 9>/dev/null              # 9: API-specific purpose

   ################################
   # Perform Logging Redirections #
   ################################
   if [[ -n ${___launcher___Config[Log]} ]]; then                  # Writing to a log file has been requested
      if [[ ! -f ${___launcher___Config[Log]} ]]; then
         local ___launcher_____RedirectIO___LogDir="$(dirname "${___launcher___Config[Log]}")"
      fi

      if [[ -w ${___launcher___Config[Log]} || ( ! -f ${___launcher___Config[Log]} && -w $(dirname "${___launcher___Config[Log]}") ) ]]; then
                                                         # Is the log file writable?
         if [[ ${___launcher___Config[DupLogToStdout]} = true ]]; then
                                                         # Yes. Now, should the output also go to stdout?
            exec > >( stdbuf -i0 -o0 -e0 tee -a -i >( sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >>"${___launcher___Config[Log]}" ) ) 2>&1
                                                         # Unbuffered tee to stdout/file; Remove color characters from log file


         else
            exec > >( stdbuf -i0 -o0 -e0 sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >>"${___launcher___Config[Log]}" ) 2>&1
                                                         # Now the revised stdout and stderr will go only to the log file
                                                         # Remove color characters from log file
         fi

         # See: https://stackoverflow.com/questions/30687504/redirected-output-hangs-when-using-tee
         sleep 0                                         # Workaround for blocking prompt
                                                         # Ensure stdout and stderr go to both stdout and the log file

      else
         :error: "Could not open log file for writing: ${___launcher___Config[Log]}"
      fi                                                 # The log file was not writable
   fi
}

:launcher:_:DispatchRequests()
{
   local -g _functions_json
   :json:jq _functions_json '.function' "$_etc_dir/functions.json"

   if $___launcher______Help || [[ $1 =~ ^/ ]]; then
      :help: "$@"

   elif (( $# == 0 )); then
      :highlight: <<<"For help, invoke: <B>$__ help</B>"
      return 0

   elif :test:has_func "$1"; then
      if $___launcher______Edit; then
         local ___launcher_____DispatchRequests___FunctionPath
         :json:jq ___launcher_____DispatchRequests___FunctionPath -r ".\"$1\".path" <<<"$_functions_json"
         if $___launcher______EditBin; then
            vi "$(readlink -f "$_bin_dir/$___launcher_____DispatchRequests___FunctionPath")"
         else
            vi "$(readlink -f "$_lib_dir/$___launcher_____DispatchRequests___FunctionPath")"
         fi

      else

         if [[ ${___launcher___Config[MaskErrors]} = true ]]; then # Should errors be ignored?
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
   local -a ___launcher_____Shutdown___ShutdownFunctions
   :find:functions --meta SHUTDOWN --var ___launcher_____Shutdown___ShutdownFunctions

   local ___launcher_____Shutdown___ShutdownFunction
   for ___launcher_____Shutdown___ShutdownFunction in "${___launcher_____Shutdown___ShutdownFunctions[@]}"; do
      "$___launcher_____Shutdown___ShutdownFunction"
   done

   exec 3<&-                                             # Close duplicate of stdin or user-provided input file
   exec 4>&-                                             # Close duplicate of stdout our user-provided output file
   exec 5>&-                                             # Close duplicate of stderr our user-provided output file
   exec 6>&-                                             # Close data payload file descriptor
   exec 7>&-                                             # Close API-specific file descriptor
   exec 8>&-                                             # Close API-specific file descriptor
   exec 9>&-                                             # Close API-specific file descriptor

   # When using tee with multiple file descriptors, output synchronization problems may occur.
   # Running a trivial command in a subshell is a workaround to force correct synchronization so
   # that problems such as the prompt not showing up are avoided.
   if [[ -n ${___launcher___Config[Log]} && ${___launcher___Config[DupLogToStdout]} = true ]]; then
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
   local ___launcher_____BuildFunctionInfoDEPRECATED___function
   local ___launcher_____BuildFunctionInfoDEPRECATED___Path
   for ___launcher_____BuildFunctionInfoDEPRECATED___Function in "${_functions[@]}"; do
      :json:jq ___launcher_____BuildFunctionInfoDEPRECATED___Path -r ".\"$___launcher_____BuildFunctionInfoDEPRECATED___Function\".path" <<<"$_functions_json"
      _function_to_path[$___launcher_____BuildFunctionInfoDEPRECATED___Function]="$___launcher_____BuildFunctionInfoDEPRECATED___Path"
      _path_to_functions[$___launcher_____BuildFunctionInfoDEPRECATED___Path]+="${_path_to_functions[$___launcher_____BuildFunctionInfoDEPRECATED___Path]:+ }$___launcher_____BuildFunctionInfoDEPRECATED___Function"
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
   local ___launcher_____TEST___Message="$1"

   echo
   printf '%0.s=' {1..40}
   echo " $___launcher_____TEST___Message"
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
