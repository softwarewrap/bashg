#!/bin/bash

+ %STARTUP-0()
{
   # Note: Launcher startup priorities should always be first (%STARTUP-0)
   local -g _whoami                                      # The current user
   local -g _env_var=                                    # The options environment variable name
   local -ig _return=                                    # Return status from commands

   _whoami="$(whoami)"
}

+ ()
{
   ###################################################
   # Must Have No Dependencies on %STARTUP Functions #
   ###################################################
   (-):PreStartup                                        # Do early declarations and satisfy basic requirements
   (-):ProcessOptions "$@"                               # Process options (return on failure)

   #######################################
   # Load Function-Specific Declarations #
   #######################################
   (-):Startup "${(-)_Args[@]}"                          # Setup redirection; Run STARTUP functions

   #################################################
   # Execute Functions based on Command-Line Input #
   #################################################
   (-):DispatchRequests "${(-)_Args[@]}"                 # Process the request

   ###############################
   # Perform an Orderly Shutdown #
   ###############################
   (-):Shutdown                                          # Run SHUTDOWN functions; Close redirection
}

- PreStartup()
{
   :get:os --var _os                                     # Get an associative array providing os (distro) information

   local -Ag (+)_Config                                  # Launcher configuration parameters

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
   local -a (.)_PersistVars=(
      (+)_Config
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
   local (.)_PersistVar
   for (.)_PersistVar in "${(.)_PersistVars[@]}"; do
      eval _entry_vars[$(.)_PersistVar]=                 # Index is a variable to use on :reenter
   done

   ### ENVIRONMENT VARIABLES
   local -gx LESS="-X -F -r"
}

- ProcessOptions()
{
   local -g (-)_Edit=false                               # Interpret the function as a request to edit it
   local -g (-)_EditBin=false                            # Interpret the function as a request to edit it
   local -g (-)_Help=false                               # Interpret the function as a request for help on it

   local -ga (-)_Args=()                                 # Store any remaining args in this variable

   _env_var="$( sed -e 's|.*|\U&|;s|[^A-Z0-9_]|_|g' <<<"$__" )_OPTIONS"
                                                         # Options Env Var is uppercase: <EXE>_OPTIONS

   :getopts: begin \
      -o '=:eEhu:x' \
      -l 'declare:,edit,edit-bin,help,log:,entryuser:,trace,no-color,stdout,mask-errors' \
      -- $( envsubst <<<"\$$_env_var" ) "$@"

   local (.)_Option                                      # Option letter or word
   local (.)_Value                                       # Value stores a value for options that take a value

   while :getopts: next (.)_Option (.)_Value; do
      case "$(.)_Option" in
      -=|--declare)     (-):ProcessOptions.declare "$(.)_Value";;
      -e|--edit)        (-)_Edit=true;;
      -E|--edit-bin)    (-)_Edit=true; (-)_EditBin=true;;
      -h|--help)        (-)_Help=true;;
      -u|--entryuser)   (-):ProcessOptions.entryuser "$(.)_Value";;
      -x|--trace)       (-):ProcessOptions.trace;;

      --log)            (+)_Config[Log]="$(readlink -fm "$(.)_Value")";;
      --no-color)       (+)_Config[HasColor]=false;;
      --stdout)         (+)_Config[DupLogToStdout]=true;;
      --mask-errors)    (+)_Config[MaskErrors]=true;;    # Ignore errors as they happen

      *)          break;;
      esac
   done

   :getopts: end --save (-)_Args                         # Save unused args

   if [[ -d ${(+)_Config[pwd]} && -x ${(+)_Config[pwd]} ]]; then
      cd "${(+)_Config[pwd]}"
   fi
   if [[ -n ${(+)_Config[bash.set]} ]]; then
      eval "$( base64 -d <<<"${(+)_Config[bash.set]}" )"
   fi
   if [[ -n ${(+)_Config[bash.shopt]} ]]; then
      eval "$( base64 -d <<<"${(+)_Config[bash.shopt]}" )"
   fi
}

- ProcessOptions.declare()
{
   local (.)_Value="$1"
   local (.)_Options=( -g )                              # Always use the global namespace

   # See reenter.bash for how options are structured

   if [[ $(.)_Value =~ ^[a-zA-Z]+: ]]; then
      (.)_Options+=( "-${(.)_Value%%:*}" )               # Get the options prefix and form it into an option string
   fi

   (.)_Value="${(.)_Value#*:}"                           # Remove the options prefix

   if [[ $(.)_Options =~ r ]]; then                      # Readonly parameters cannot be re-declared
      :var:unsetro "${Value%%=*}"                        # Attempt to unset the read-only variable
   fi

   eval local "${(.)_Options[@]}" "$(.)_Value"           # Declare the variable to state before :reenter
}

- ProcessOptions.entryuser()
{
   _entry_user="$1"
   _entry_group="$(id -gn "$_entry_user")"
   eval _entry_home="~$_entry_user"                      # The home corresponding to the first-entry user
}

- ProcessOptions.trace()
{
   if (( _dispatch_method < ${#_dispatch_methods[@]} - 1 )); then
      _dispatch_method=$(( _dispatch_method + 1 ))
   fi
}

- Startup()
{
   local -a (.)_StartupFunctions

   :find:functions --meta STARTUP --var (.)_StartupFunctions
                                                         # Get ordered list of startup functions
   local (.)_StartupFunction
   for (.)_StartupFunction in "${(.)_StartupFunctions[@]}"; do
      "$(.)_StartupFunction" "$@"
   done

   # If not specified, set these configuration defaults
   local -A (.)_ConfigDefaults=(
      [HasColor]=true                                    # Color output is available
      [DupLogToStdout]=false                             # Send stdout/stderr to both the log file and stdout
      [Log]=                                             # Do not write to a log file (non-empty is the log file path)
   )

   local (.)_ConfigDefault
   for (.)_ConfigDefault in "${!(.)_ConfigDefaults[@]}"; do
      if [[ -z ${(+)_Config[$(.)_ConfigDefault]} ]]; then
         (+)_Config[$(.)_ConfigDefault]="${(.)_ConfigDefaults[(.)_ConfigDefault]}"
      fi
   done

   (-):RedirectIO                                        # Define variables, redirection, and Bash settings

   :: require_jq                                         # jq is required for JSON parsing
}

- RedirectIO()
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
   if [[ -n ${(+)_Config[Log]} ]]; then                  # Writing to a log file has been requested
      if [[ ! -f ${(+)_Config[Log]} ]]; then
         local (.)_LogDir="$(dirname "${(+)_Config[Log]}")"
      fi

      if [[ -w ${(+)_Config[Log]} || ( ! -f ${(+)_Config[Log]} && -w $(dirname "${(+)_Config[Log]}") ) ]]; then
                                                         # Is the log file writable?
         if [[ ${(+)_Config[DupLogToStdout]} = true ]]; then
                                                         # Yes. Now, should the output also go to stdout?
            exec > >( stdbuf -i0 -o0 -e0 tee -a -i >( sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >>"${(+)_Config[Log]}" ) ) 2>&1
                                                         # Unbuffered tee to stdout/file; Remove color characters from log file


         else
            exec > >( stdbuf -i0 -o0 -e0 sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >>"${(+)_Config[Log]}" ) 2>&1
                                                         # Now the revised stdout and stderr will go only to the log file
                                                         # Remove color characters from log file
         fi

         # See: https://stackoverflow.com/questions/30687504/redirected-output-hangs-when-using-tee
         sleep 0                                         # Workaround for blocking prompt
                                                         # Ensure stdout and stderr go to both stdout and the log file

      else
         :error: "Could not open log file for writing: ${(+)_Config[Log]}"
      fi                                                 # The log file was not writable
   fi
}

- DispatchRequests()
{
   local -g _functions_json
   :json:jq _functions_json '.function' "$_etc_dir/functions.json"

   if $(-)_Help || [[ $1 =~ ^/ ]]; then
      :help: "$@"

   elif (( $# == 0 )); then
      :highlight: <<<"For help, invoke: <B>$__ help</B>"
      return 0

   elif :test:has_func "$1"; then
      if $(-)_Edit; then
         local (.)_FunctionPath
         :json:jq (.)_FunctionPath -r ".\"$1\".path" <<<"$_functions_json"
         if $(-)_EditBin; then
            vi "$(readlink -f "$_bin_dir/$(.)_FunctionPath")"
         else
            vi "$(readlink -f "$_lib_dir/$(.)_FunctionPath")"
         fi

      else

         if [[ ${(+)_Config[MaskErrors]} = true ]]; then # Should errors be ignored?
            set +o errexit                               # Yes, ignore errexit
            set +o pipefail                              # Yes, ignore pipefail
         fi

         "(-):DispatchRequests.${_dispatch_methods[$_dispatch_method]}" "$@"
      fi

   elif [[ $1 = help ]]; then
      shift
      :help: "$@"

   else
      :error: "No such function: $1"
   fi
}

- DispatchRequests.standard()
{
   "$@"
}

- DispatchRequests.funcargs()
{
   :log: --push "$@"

   "$@"

   :log: --pop
}

- DispatchRequests.funcargssetx()
{
   :log: --push "$@"

   set -x
   "$@"
   set +x

   :log: --pop
}

- Shutdown()
{
   local -a (.)_ShutdownFunctions
   :find:functions --meta SHUTDOWN --var (.)_ShutdownFunctions

   local (.)_ShutdownFunction
   for (.)_ShutdownFunction in "${(.)_ShutdownFunctions[@]}"; do
      "$(.)_ShutdownFunction"
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
   if [[ -n ${(+)_Config[Log]} && ${(+)_Config[DupLogToStdout]} = true ]]; then
                                                         # The condition in which tee is used with multiple FDs
      $(true)
   fi
}

- BuildFunctionInfo%DEPRECATED()
{
   local -ga _functions
   readarray -t _functions < <(
      :json:jq - -r 'keys[]' <<<"$_functions_json"
   )

   local -Ag _function_to_path
   local -Ag _path_to_functions
   local (.)_function
   local (.)_Path
   for (.)_Function in "${_functions[@]}"; do
      :json:jq (.)_Path -r ".\"$(.)_Function\".path" <<<"$_functions_json"
      _function_to_path[$(.)_Function]="$(.)_Path"
      _path_to_functions[$(.)_Path]+="${_path_to_functions[$(.)_Path]:+ }$(.)_Function"
   done
}

+ %TEST()
{
   :log: --push "RUNNING: (+):%TEST"
   (-):%TEST.dump 'Before :sudo || :reenter'

   :sudo || :reenter                                     # This function must run as root

   :log: --pop 'Running code following :sudo || :reenter'
}

- %TEST.dump()
{
   local (.)_Message="$1"

   echo
   printf '%0.s=' {1..40}
   echo " $(.)_Message"
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
