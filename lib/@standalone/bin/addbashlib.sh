#!/bin/bash

::addbashlib()
{
   local Options
   Options=$(getopt -o 'c' -l 'cleartext' -n "$FUNCNAME" -- "$@") || return
   eval set -- "$Options"

   local ClearText=false

   while true ; do
      case "$1" in
      -c|--cleartext)   ClearText=true; shift;;          # Emit the library as clear text instead of compressing it

      --)               shift; break;;
      *)                break;;
      esac
   done

   local FileToModify="$1"                               # Required argument: the file to modify
   if [[ ! -w $FileToModify ]]; then
      echo "Invalid file: $FileToModify"                 # If the file doesn't exist or isn't writable, then exit
      return 1
   fi

   local -g __program                                    # Full path to this script (for re-execution)
   local -g __                                           # Basename of this script
   local -g __base_dir                                   # Directory containing this script
   local -g __invocation_dir                             # The directory from which the script was invoked

   __program="$(readlink -f "$BASH_SOURCE")"             # Get the canonical path to this script
   __base_dir="$(dirname "$__program")"                  # base directory: where this script lives
   __lib_dir="$(readlink -fm "$__base_dir/../lib")"      # lib directory: where the library code lives
   __invocation_dir="$(readlink -f .)"                   # Get the directory from which this script was called
   __="${__program##*/}"

   if [[ ! -d $__lib_dir ]]; then
      echo "Missing lib directory: $__lib_dir"           # The lib directory must exist
      return 1
   fi

   set -o errexit                                        # Fail on any error
   set -o pipefail                                       # Fail on any pipe error
   set -o errtrace                                       # Enable error tracing

   local BeginMarker='###{BASH_LIBRARY}###'

   if [[ -z $FileToModify ]]; then
      cat <<EOF
Usage: $__ <file>

   Append to the indicated <file> the supporting Bash library functions

   The following marker is placed in the file to indicate the start of the
   library functions and must not be removed:

      $BeginMarker
EOF
   fi

   shopt -s nullglob globstar

   sed -i '$a\' "$FileToModify"                          # Ensure there is a newline at the end of the file
   sed -i "/$BeginMarker/,\$d" "$FileToModify"           # Remove any existing begin marker

   local SourceErrors
   if ! SourceErrors="$(source "$FileToModify" 2>&1)"; then
      echo "$SourceErrors"
      exit 1
   fi

   local FirstFunction FirstLine Filename
   read FirstFunction FirstLine Filename < <(            # Get information about the first function in the file
      bash <(                                            # In a subshell, get the functions in the file to modify
         set -a                                          # Allow those functions to be auto exported
         echo source "$FileToModify"                     # Create the command to source the file

         # The readarray statement gets the function declared and is in yet another subshell.
         # This is why it is necessary above to use the set -a idiom.
         # Setting extdebug makes it so that line numbers are also emitted via declare -F
         # Finally, the functions are listed, then sorted by line number, getting the first function in the file
         cat <<'EOF'
            shopt -s extdebug
            declare -a Functions

            readarray -t Functions < <(
            declare -F | sed 's|declare -f ||'
         )

         for Function in "${Functions[@]}"; do
            declare -F "$Function"
         done | sort -k2 -n | head -1
EOF
      ) 2>&1
   )

   local -g TmpFile=
   trap ::addbashlib%EXIT EXIT                           # Ensure cleanup is always done

   TmpFile="$(mktemp)"
   if (( $FirstLine == 1 )); then
      cp "$FileToModify" "$TmpFile"                      # Edge case: the first function begins on line 1
   else
      {
         echo "$FirstFunction()"
         sed "1,/$FirstFunction/d" "$FileToModify"
      } > "$TmpFile"
                                                         # Discard lines above the first function
   fi

   local EntryPoint                                      # The entry point is the first function,
   EntryPoint="${FirstFunction%%%*}"                     # ignoring any % suffix such as %HELP

   local -a Files
   readarray -t Files < <(                               # Get the list of all of the .sh files except this script
      find $__lib_dir -type f -name '*.sh' \! -path "$__program" | sort -f
   )

   # Modify the file to include a useful header, followed by the file code, and adding the library
   # code at the bottom. Any previously-added library code will be replaced.
   {
      cat <<EOF
#!/bin/bash

# REQUIRED CONVENTIONS FOR NAMESPACE PROTECTION:         # THESE CONVENTIONS MUST BE FOLLOWED TO GUARANTEE SAFETY
# Where:
#     <p> : {package-level scope}                        # Required unique lowercase alphanumeric name or : or _
#     <c> : {component-level scope}                      # Optional 2nd level namespace
#     <u> : {unit-level scope}                           # Optional 3rd level namespace
#     <n> : {name}                                       # The function or variable name
#
#     Function and Variable Names:
#        [<p>][:<c>][:<u>]:<n>                           # Note: At least one colon : is present
#        [<p>][__<c>][__<u>]__<n>                        # Note: At least one double underscore __ is present
#
#     The Standard Library defines <p> as : for functions and the empty string for variables
#        :[:<c>][:<u>]:<n>                               # Note: Always begins with ::
#        [__<c>][__<u>]__<n>                             # Note: Always begins with __
#
#     <n> Syntax for use in both functions and variables:
#        -  Names may not contain colons nor begin nor end with an underscore; otherwise follows Bash variable syntax
#        -  Names may contain medial underscores, but not contiguous to other underscores
#        -  The capitalization of names indicates how they are to be used:
#              public_name                               # public_name is an API
#              PrivateName                               # PrivateName is an internal implementation
#
# REQUIRED CONVENTIONS WITHOUT NAMESPACE PROTECTION:     # Follow Bash rules with the following restrictions:
#     Functions: Colons are not permitted                # NOTE: Conflicts between such names are possible.
#     Variables: Leading, trailing, and multiple         # Typically, used only for non-reusable functions. Variables
#                contiguous underscores are forbidden    # must always be declared as local without the -g flag.
#
# ENTRYPOINT: The first function name below, ignoring any %<name> suffix determines the entrypoint for this code

$(cat $TmpFile)
EOF

      ##############
      # Clear Text #
      ##############
      if $ClearText; then
         local Line=$'\n'                                # 3 Lines of # marks help separate user from library code
         Line+="$(printf '%0.s#' {1..118})"

         echo -e "\n$BeginMarker$Line$Line$Line"         # Emit the begin marker followed by the visual break

         for File in "${Files[@]}"; do
            sed '1{/^#!\/bin\/bash.*/d}' "$File" |
            sed '/./,$!d;:a;/^\n*$/{$d;N;ba};$a\'
                                                         # Remove blank lines at the top and bottom of the file
         done

         cat <<EOF
$EntryPoint%LOAD()
{
   local -g __program                                    # Full path to this script (for re-execution)
   local -g __                                           # Basename of this script
   local -g __base_dir                                   # Directory containing this script
   local -g __invocation_dir                             # The directory from which the script was invoked

   __program="\$(readlink -f "\$BASH_SOURCE")"           # Get the canonical path to this script
   __base_dir="\$(dirname "\$__program")"                # base directory: where this script lives
   __invocation_dir="\$(readlink -f .)"                  # Get the directory from which this script was called
   __="${__program##*/}"

   local -a SavedArgs=( "\$@" )
   local -ga __Args=()                                   # Store any remaining args in this variable

   :getopts: begin -o '' -l 'help' -- "\$@"

   local __Option                                        # Option letter or word
   local __Value                                         # Value stores a value for options that take a value
   local __EncounteredStopRequest=false                  # encountered --: what follows is search taking args
   local __HelpRequested=false

   while :getopts: next __Option __Value __EncounteredStopRequest; do
      case "\$__Option" in
      --help)  __HelpRequested=true;;

      *)       break;;
      esac
   done

   :getopts: end --save __Args                           # Save unused args
   set -- "\${__Args[@]}"

   if \$__HelpRequested; then
      if (( \$# == 0 )); then
         "$EntryPoint%HELP"
      else
         :help: "\$@"
      fi

      return 0
   fi

   "$EntryPoint" "\${SavedArgs[@]}"
}
EOF

         printf '%s "$@"; exit\n' "$EntryPoint%LOAD"     # Call the entry point

      ##################################
      # Compressed and Base 64 encoded #
      ##################################
      else
         # Emit the begin marker, then source the decoded and uncompressed library content
         cat <<EOF
$BeginMarker
source <(sed "1,/$BeginMarker/d" "\$BASH_SOURCE" | sed '1d' | base64 -d | gunzip); exit
EOF

         {
            for File in "${Files[@]}"; do
               sed '1{/^#!\/bin\/bash.*/d}' "$File" |
               sed '/./,$!d;:a;/^\n*$/{$d;N;ba};$a\'
                                                         # Remove blank lines at the top and bottom of the file
            done

            printf '%s "$@"; exit\n' "$EntryPoint"       # Call the entry point
         } | gzip | base64 -w128  # Emit Bash library
      fi
   } >"$FileToModify"                                    # Modify the file with the header and library content
}

::addbashlib%EXIT()
{
   if [[ -e $TmpFile ]]; then                            # On exit, always remove the temp file if it exists
      rm -f "$TmpFile"
   fi
}

::addbashlib "$@"
