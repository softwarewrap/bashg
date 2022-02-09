#!/bin/bash

:main%HELP()
{
   cat <<EOF
SELECTION OPTIONS:
   -p|--package <package-dirs>   : Restrict files to those under <packages-dirs>

   -t|--tag <tags>               : Restrict files to those containing any or all listed <tags>
   --any                         : For files with set tags, at least one of <tags> must be set to allow inclusion
   --all                         : For files with set tags, all <tags> must be set to allow inclusion

   --shx <password>              : Include .shx files and use <password> for decryption

GENERATION OPTIONS:
   --map <src>:<dst>             : Map src/<package>/bin/<src>.sh to bin/<dst>
   -o|--optimize <level>         : Optimize code generation
   --no-warn                     : Do not warn in the case of duplicate functions
   -v|--verbose                  : Emit more verbose messages during generation

   -h|--help                     : Show this help

DESCRIPTION:
   Generate files into distributable form.

   All files are located under a <base> directory, located under any writable directory.

   Under the <base> directory, the following directories are present:

      src - Original source code: some content might not be distributable, generate into the other directories.
      bin - Distributable generated functions
      etc - Distributable configuration files
      lib - Re-distributable source code

   All source code is organized under <package> names that are used by the generator to provide namespace protection.
   The source code for <package> is found under the src/<package-dir> directory.

      <package>     ::= <package-tld>.<package-subdomain>
      <package-dir> ::= <package-tld>/<package-subdomain>

   Notes:
      -  All <package>, <package-tld>, <package-subdomain>, and <package-dir> names are lowercase
         and follow reverse domain-name notation.

      -  All source code and data files must be placed under the <package-dir> directory.

      -  A <package-subdomain> named underscore (_) indicates code belongs to the top-level domain.

      -  The system <package-tld> is always indicated by an underscore (_) to future proof the generator
         and conveys namespace naming features.

FILE TYPES:
   Files under the src/<package-dir> directory fall into the following types based on file
   or directory naming syntax:

      NON-DISTRIBUTABLE
         A file or directory name that begins with an % character indicates that the file or directory
         is to be skipped during generation, resulting in no change to the bin, etc, or lib directories.
         In the case of the % prefix on a directory, all subdirectories are unconditionally skipped.

         A file or directory is also skipped if tag evaluation indicates exclusion (see TAG EVALUATION);
         however, in the case of directories tag exclusion can be reversed by a subdirectory that
         requests inclusion.

         All other files and directories are considered to be distributable.

      FUNCTIONS
         File has the .sh extension and contains function definitions only.
         No immediately-executable code is permitted in these files.

      LOAD-TIME
         File has the .bash extension and contains aliases, shopt, and set commands only.
         Functions in .bash files are not permitted.
         Function calls within .bash files are not permitted.
         This content will always be executed at program load time.

      ENCRYPTION
         Source .shx files are presumed to be encrypted with 7-zip (https://7-zip.org).
         Decrypted .shx files generate output only if the --shx option is used.

         Other than the decryption for .shx files, both .shx and .shc files follow code generation
         identically to .sh files. The generated results are then post-processed by the shc(1) utility
         that create binary executables with encrypted content and are named with the extensions removed.

         Note: .shc and .shx files are NOT copied to the lib directory.

      DATA
         A file or directory name that begins with an @ character indicates that the file or directory
         is a data file and will only be copied to the lib directory.

TAG EVALUATION:
   The : tag annotation, found in .bash and .sh files, causes evaluation for all distributable files
   as to whether or not the file should be included or skipped by the generator based on tag-matching criteria.

   The : tag annotation parses each argument as a tag request. Requests take the following forms:

      [+|-]<tag>
         The explicit inclusion of + or - set or unsets the tag.
         The tag is set if neither + nor - are present.

      <tag>=<value>
         The tag is set and has the <value> indicated. If the <value> includes spaces, then <value> must be quoted.

   The <tag> can use the expanded function namespace prefix or it can be a simple string.
   Care must be taken when not using namespace protection.

   The : tag annotation has different semantics for .bash and .sh files:

      .bash
         The : tag annotation determines whether the directory and all subdirectories of the .bash file
         are included for generation or are skipped by the generator. Unlike the % prefix on directories,
         tags defined at a subdirectory level can override the exclusion made in a parent directory.

      .sh
         The : tag annotation determines whether the current file is included for generation or is
         skipped by the generator.

   NOTES:
      -  It is customary to place the : tag annotation before other non-comment content.

      -  If the same tag is defined multiple times in a single .sh or .bash file,
         only the last :tag operation applies.

      -  If the same tag is defined in multiple .bash files in the same directory,
         then the tag state is indeterminate.

SELECTION OPTIONS:
   --package <package-dirs>
      If no --package options are specified, then all packages are selected for generation.
      If one or more --package options are specified, then only files under the listed packages are
      selected for generation.

      The <package-dirs> argument is a comma-separated list of <package-dir> paths.

   --tag <tags>
      Restrict which files are considered by the generator. This option can be used multiple times.
      The <tags> argument is a comma-separated list of tag names.
   --any
      If any specified tag is defined for a given file, then that file is included.
   --all
      All specified tags must be defined for a given file for that file to be included.

   NOTES:
      If neither the options --any nor --all are specified, then --any is presumed.

   --shx <password>
      Generate files that have the .shx extension. If this option is not provided, then warnings are
      given unless the --no-warn option is also given.

GENERATION OPTIONS:
   --map <src>:<dst>
      Source files located under src/<package-dir>/bin/<file-path>.sh are converted to entry-point functions
      if this option maps them and creates bin/<dst> as the generated result.

      The <src> portion of the option can take either of the following forms:

         <file-path>                      # matches any src/*/*/bin/<file-path>.sh file
         <package-dir>/bin/<file-path>    # matches <package-dir>/bin/<file-path>.sh file

      Note that the .sh extension of the source file is omitted in the <src> specification.
      In all cases, the generated result is placed directly in the bin directory without the .sh extension
      and the file is made to be executable.

      The entry-point function in mapped files must be declared in the file as:

         @ main()
         {
            ...
         }

      A call to this function is added when mapping as follows:

         (@):main "$@"; exit

      The <dst> is the name of the executable file that will be placed directly under the bin directory.

      This option can be specified multiple times for as many mappings as desired.

   --optimize <level>
      Optimize the generated code to the specified <level>.  Supported levels include:

         all   - all optimizations are performed including function normalization and macro substitution [default]
         none  - no optimizations are performed (identical to "all" but excludes function normalization)

   --no-warn
      Warnings are emitted under various circumstances:

         - when functions with identical content are found
         - when .shx files are being processed, but the --shx option is not specified

      This option supresses the that reporting.

RETURN CODES
   1  : General error
   2  : Script was run as input from a pipe
   3  : Script was run as input from process substitution
EOF

   exit 0
}

:main()
{
   :ProcessOptions "$@" || return                        # Process options (return on failure)
   :SetupEnvironment "$@" || return                      # Define variables and settings
   :SelectAndCopyFunctionFiles                           # Select function files limited by tags and expand macros
   :TransformFunctionFiles
   :SelectAndCopyDataFiles                               # Process data (non-function) files from packages
   :GenerateLookupFile || return                         # Generate manifest of functions
}

:ProcessOptions()
{
   local Options
   Options=$(getopt -o 'p:t:o:hv' -l 'package:,tag:,any,all,shx:,map:,optimize:,no-warn,verbose,help' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$Options"

   local -ag _PackageRequests=()                         # Packages requested to be generated
   local -ag _PackageDirs=()                             # Process the indicated package dirs; empty == all
   local -ag _TagRequests=()
   local -g _Mode='any'
   local -ag _SrcDstMap=()                               # Map src/<package>/bin/file.sh to bin
   local -g _Warn=true
   local -gA _Optimize
   local -g _Verbose=false
   local -g _ShxPassword=

   while true ; do
      case "$1" in
      ### SELECTION
      -p|--package)  :list_append_to_array --list "$2" --var _PackageRequests; shift 2;;
                                                         # Allow comma-separated packages
      -t|--tag)      :list_append_to_array --list "$2" --var _TagRequests; shift 2;;
                                                         # Allow comma-separated tags
      --any)         _Mode=any; shift;;
      --all)         _Mode=all; shift;;

      --shx)         _ShxPassword="$2"; shift 2;;

      ### GENERATION
      --map)         _SrcDstMap+=( "$2" ); shift 2;;     # Add a src/dst mapping

      -o|--optimize) _Optimize[$2]=true; shift 2;;
      --no-warn)     _Warn=false; shift;;
      -v|--verbose)  _Verbose=true; shift;;

      -h|--help)     :main%HELP;;                        # Show help if either of these options are given

      --)            shift; break;;
      *)             break;;
      esac
   done

   if [[ -z $_ShxPassword && -n $BASHG_SHX ]]; then
      _ShxPassword="$BASHG_SHX"
   fi

   if (( ${#_Optimize[@]} == 0 )); then
      _Optimize[none]=true
   fi

   [[ $1 != help ]] || :main%HELP                        # Show help if the first arg is 'help'
}

:SetupEnvironment()
{
   if [[ -z $BASH_SOURCE ]]; then
      echo 'This script cannot be run as input from a pipe' >&2
      return 2
   fi
   if [[ $BASH_SOURCE =~ ^/proc/self/fd ]]; then
      echo 'This script cannot be run as input from process substitution'
      return 3
   fi

   local -g _Program                                     # Full path to this script (for re-execution)
   local -g _ProgramDir                                  # Directory containing this script
   local -gx _BaseDir
   local -g _SrcDir
   local -g _LibDir
   local -g __                                           # Basename of this script
   local -Ag _TAGS

   _Program="$(readlink -f "$BASH_SOURCE")"              # Get the canonical path to this script
   _ProgramDir="$(dirname "$_Program")"                  # Get the directory in which this script lives
   _BaseDir="$(readlink -f "$_ProgramDir/..")"           # The top-level directory containing src, bin, etc, and lib
   _SrcDir="$_BaseDir/src"                               # Set the path to the src directory
   _BinDir="$_BaseDir/bin"                               # The bin files for distribution
   _LibDir="$_BaseDir/lib"                               # The lib files for distribution
   __="$(basename "$0")"                                 # Get the script basename
   _FunctionsJSON='etc/functions.json'                   # The manifest of functions

   shopt -s globstar nullglob

   # Determine the entrypoint loader executable
   local -ga _Loader
   readarray -t _Loader < <(
      cd "$_SrcDir/_/_/bin"
      find . -mindepth 1 -maxdepth 1 -type f -name '*.sh' -print |
      LC_ALL=C sed -e 's|\./||' -e 's|\.sh$||' -e '/^\s*$/d'
   )
   if (( ${#_Loader[@]} != 1 )); then
      echo 'Missing entrypoint loader file'
      return 1
   fi

   if :ArrayContains --anchored _SrcDstMap "$_Loader:"; then
      readarray -t _Loader < <(
         printf '%s\n' "${_SrcDstMap[@]}" |
         grep "^$_Loader:" |
         sed -e 's|[^:]*:||' -e '/^\s*$/d'
      )
      if (( ${#_Loader[@]} != 1 )); then
         echo 'Missing mapping for entrypoint loader'
         return 1
      fi
   fi

   if [[ $_ProgramDir = $_LibDir ]]; then
      rm -rf "$_SrcDir"
      mv "$_LibDir" "$_SrcDir"
      "$_SrcDir/$__" "$@"
      exit 0
   fi

   if [[ $_ProgramDir = $_LibDir ]]; then
      mv "$_LibDir" "$_SrcDir"
   fi

   mkdir -p "$_LibDir"                                   # Ensure the lib directory exists
   cp -p "$_Program" "$_LibDir"/.                        # Copy this script into the lib directory

   cd "$_SrcDir"                                         # Ensure we're in the src directory

   readarray -t _PackageDirs < <(
      {
         if (( ${#_PackageRequests[@]} == 0 )); then
            find . -mindepth 2 -maxdepth 2 -name '[%@]*' -prune -o -type d -print |
            LC_ALL=C sed -e 's|^\./||'                   # Remove the leading ./
         else
            printf '%s\n' "${_PackageRequests[@]}"
         fi
      } |
      { grep -v '__' || true; } |                        # Disallow names containing two adjacent underscores
      { grep -vP '(^_[^/]|^[^/]+_/)' || true; } |        # Disallow package-tld names: _<name> | <name>_
      { grep -vP '^[^/]+/(_.+$|.+_$)' || true; }         # Disallow package-subdomain names: _<name> | <name>_
   )
}

:SelectAndCopyFunctionFiles()
{
   local -Ag _DirTags                                    # Tags associated with a specific directory
   local -agx BashFilesToTransform=()                    # Array of .bash files requiring transformation
   local -ag ShFilesToTransform=()                       # Array of .sh files requiring transformation
   local -ag ShcFilesToTransform=()
   local _PackageDir

   local -ag _Extensions=( bash )                        # The .bash extension is always supported
   ! command -v shc &>/dev/null || _Extensions+=( shc )  # If shc is in the path, then allow .shc files
   ! command -v 7za &>/dev/null || _Extensions+=( shx )  # If 7za is in the path, then allow .shx files
   _Extensions+=( sh )

   for _PackageDir in "${_PackageDirs[@]}"; do

      rm -rf "$_BaseDir"/{bin,lib}/"$_PackageDir"        # Start off with a clean package

      local -a _PackageSubDirs

      cd "$_SrcDir"
      readarray -t _PackageSubDirs < <(                  # Get $_PackageDir/<dirs> in descending lexical order
         find "$_PackageDir" -name '[%@]*' -prune -o -type d ! -path . -print |
                                                         # Find all directories except for .
         LC_ALL=C sort -f |                              # Lexically sort them
         sed '/^$/d'                                     # Omit blank lines
      )

      local _PackageSubDir
      for _PackageSubDir in "${_PackageSubDirs[@]}"; do  # Iterate over $_PackageSubDirs

         :SetDirTags "$_PackageSubDir"
         unset _TAGS
         local -Ag _TAGS
         eval "${_DirTags[$_PackageSubDir]}"

         #############################################################
         # ITERATE OVER EXTENSIONS: .bash .sh and possibly .shc .shx #
         #############################################################
         for _Extension in "${_Extensions[@]}"; do       # Iterate over bash and sh extensions

            cd "$_SrcDir/$_PackageSubDir"                # Ensure we're in the specific package subdirectory

            local -a _PackageSubDirFiles                 # Array containing matched files in the current directory
            readarray -t _PackageSubDirFiles < <(
               find . -mindepth 1 -maxdepth 1 -name '[%@]*' -prune -o -name "*.$_Extension" -print |
                                                         # Look only in this directory for files with $_Extension
               LC_ALL=C sort -f |                        # Lexically sort the results
               sed -e 's|^\./||' -e '/^\s*$/d'           # Remove leading ./ and remove any blank lines
            )

            ################################################################
            # If this package subdirectory contains files, then process it #
            ################################################################
            if (( ${#_PackageSubDirFiles[@]} > 0 )); then
               local _SourceFile                         # Iterator over _PackageSubDirFiles

               for _SourceFile in "${_PackageSubDirFiles[@]}"; do

                  local -g _IsShc=false

                  if [[ $_Extension = shx ]]; then
                     if [[ -z $_ShxPassword ]]; then
                        echo "[WARNING] Skipping .shx file as no password provided: $_SourceFile"
                        continue
                     fi

                     local _SourceExpected="${_SourceFile%.shx}.sh"

                     if [[ $_ShxPassword = - ]]; then
                        read -sp 'Password: ' _ShxPassword
                        echo
                     fi

                     if [[ $(file -b "$_SourceFile") =~ archive ]]; then
                        local -a _ShxFiles
                        readarray -t _ShxFiles < <( unzip -Z1 "$_SourceFile" 2>/dev/null || true )
                        if (( ${#_ShxFiles[@]} != 1 )); then
                           echo "[WARNING] Skipping .shx file as archive size is not 1: $_SourceFile"
                           continue
                        fi

                        if [[ $_ShxFiles != $_SourceExpected ]]; then
                           echo "[WARNING] Skipping .shx file as archived file is not $_SourceExpected: $_SourceFile"
                           continue
                        fi

                        if ! 7za e -y -o. -p"$_ShxPassword" "$_SourceFile" &>/dev/null; then
                           echo "[WARNING] Skipping .shx file as decryption failed: $_SourceFile"

                           rm -f "$_SourceExpected"
                           continue
                        fi

                     else
                        mv -f "$_SourceFile" "$_SourceExpected"
                        7za a -tzip -p"$_ShxPassword" "$_SourceFile" "$_SourceExpected" &>/dev/null
                     fi

                     _IsShc=true
                     _SourceFile="$_SourceExpected"
                  fi

                  if [[ $_Extension = shc ]]; then
                     cp "$_SourceFile" "${_SourceFile%.shc}.sh"
                  fi

                  :UpdateTags "$_SrcDir/$_PackageSubDir/$_SourceFile"
                                                         # Update _TAGS to now include the tags in the file

                  if (( ${#_TagRequests[@]} > 0 && ${#_TAGS[@]} > 0 )); then
                     ####################################################################
                     # The file invokes :tag - determine if this file is to be included #
                     ####################################################################
                     :CheckIfTagsAreSatisfied

                     if [[ $_Extension = bash ]]; then   # Do these tags apply to subdirectories?
                        _DirTags[$_PackageSubDir]="$(declare -p _TAGS | sed 's|^declare |declare -g |')"
                                                         # Associate the tags with this directory
                     else
                        unset _TAGS                      # Otherwise, reset the tags to ignore the tags in this file
                        local -Ag _TAGS                  # so that other files in this directory are unaffected.
                        eval "${_DirTags[$_PackageSubDir]}"
                     fi

                     if $_Satisfied; then                # If the tags conditions are satisfied, transform this file
                        :Copy "$_PackageSubDir/$_SourceFile"
                     fi

                  else
                     #####################################################################
                     # The file does NOT invoke :tag - unconditionally include this file #
                     #####################################################################
                     :Copy "$_PackageSubDir/$_SourceFile"
                  fi

                  if $_IsShc; then
                     rm -f "$_SourceFile"
                  fi

               done
            fi
         done
      done
   done
}

:CheckIfTagsAreSatisfied()
{
   if [[ $_Mode = any ]]; then
      local -g _Satisfied=false                          # At least one tag must be present
   else
      local -g _Satisfied=true                           # All tags must be present
   fi

   local _TagRequest
   for _TagRequest in "${_TagRequests[@]}"; do
      if [[ " ${!_TAGS[@]} " =~ " $_TagRequest " ]]; then
         if [[ $_Mode = any ]]; then
            _Satisfied=true                              # Satisfied 'any' - no need to look further
            break
         fi

      elif [[ $_Mode = all ]]; then
         _Satisfied=false                                # Failed to satisfy 'all' - no need to look further
         break
      fi
   done
}

:SelectAndCopyDataFiles()
{
   ! $_Verbose || echo -e "\nChecking for Data Paths to Copy\n"

   local -a _Keys
   readarray -t _Keys < <( printf '%s\n' "${!_DirTags[@]}" | sort -r -f )

   for _PackageDir in "${_PackageDirs[@]}"; do
      local -a _Files

      cd "$_SrcDir"
      readarray -t _Files < <(
         find "$_PackageDir" -name '%*' -prune -o -type f |
                                                         # Get the list of all distributable files
         grep -P '(^@|/@)' |                             # Limit to only data files beginning with an @ character
         LC_ALL=C sort -f |                              # Lexically sort them
         sed '/^$/d'                                     # Omit blank lines
      )

      if (( ${#_TagRequests[@]} > 0 )); then
         for _Key in "${_Keys[@]}"; do
            if [[ -n "${_DirTags[$_Key]}" ]]; then
               eval "${_DirTags[$_Key]}"

               :CheckIfTagsAreSatisfied
               if ! $_Satisfied; then
                  readarray -t _Files < <(
                     printf '%s\n' "${_Files[@]}" |
                     { grep -v "^$_Key" || true; }
                  )
               fi
            fi
         done
      fi

      (( ${#_Files[@]} > 0 )) || continue

      mkdir -p "$_BaseDir"/{bin,lib}

      printf '%s\n' "${_Files[@]}" |
      tar cpf - --files-from - |
      (
         if $_Verbose; then
            cd "$_BaseDir/lib"; tar xvpf - | sed 's|^|   |'

         else
            cd "$_BaseDir/lib"; tar xpf -
         fi
      )
   done

   ! $_Verbose || echo
}

:GenerateLookupFile()
{
   ! $_Verbose || echo -e "\nGenerating $_FunctionsJSON Function Manifest File\n"

   cd "$_BinDir"

   #######################################################################################
   # .bash files can contain alias definitions that affect Bash parsing: must load first #
   #######################################################################################
   local -a _BashFiles
   readarray -t _BashFiles < <(
      find . -mindepth 2 -name '[%@]*' -prune -o -type f -name '*.bash' -print |
                                                         # Get all .bash files
      LC_ALL=C sort |                                    # Lexically sort them
      sed -e 's|^\./||' -e '/^\s*$/d'                    # Remove leading ./ and remove any blank lines
   )

   #####################################################################################
   # .sh files must contain only function definitions: no executable code is permitted #
   #####################################################################################
   local -a _ShFiles
   readarray -t _ShFiles < <(
      find . -mindepth 2 -name '[%@]*' -prune -o -type f -name '*.sh' -print |
                                                         # Get all .sh files
      LC_ALL=C sort |                                    # Lexically sort them
      sed -e 's|^\./||' -e '/^\s*$/d'                    # Remove leading ./ and remove any blank lines
   )

   local -a _Keys
   readarray -t _Keys < <( printf '%s\n' "${!_DirTags[@]}" | sort -r )

   if (( ${#_TagRequests[@]} > 0 )); then
      for _Key in "${_Keys[@]}"; do
         if [[ -n "${_DirTags[$_Key]}" ]]; then
            eval "${_DirTags[$_Key]}"

            :CheckIfTagsAreSatisfied
            if ! $_Satisfied; then
               readarray -t _BashFiles < <(
                  printf '%s\n' "${_BashFiles[@]}" |
                  { grep -v "^$_Key" || true; }
               )
               readarray -t _ShFiles < <(
                  printf '%s\n' "${_ShFiles[@]}" |
                  { grep -v "^$_Key" || true; }
               )
            fi
         fi
      done
   fi

   local -A _FunctionToFile                              # Store the mapping of function to file here
   local -A _FunctionToHash                              # Store the mapping of function to hash here
   local -A _HashToFunction                              # Used to determine duplicates
   local _I

   #############################################################################################
   # For each .sh file, source all .bash files, then get the functions defined in each of them #
   #############################################################################################
   local _ShFile
   local _ShFileFunctions
   local -a _FunctionItems=()
   local _ErrorOutput="$(mktemp)"                        # Any error output from Bash parsing files
   local _BashFile                                       # Iterator
   local _HashKey                                        # The function hash

   for _ShFile in "${_ShFiles[@]}"; do                   # Only .sh files contain functions (and only functions)
      _ShFileFunctions="$(
         bash <(
            ###################################################################
            # This code runs direct Bash commands, not inside of any function #
            ###################################################################
            for _BashFile in "${_BashFiles[@]}"; do      # For all .sh files...
               cat "$_BinDir/$_BashFile"                 # Load all .bash files prior to sourcing .sh files
            done                                         # as this may change the parsing of the .sh files

            cat "$_BinDir/$_ShFile"                      # Emit the current .sh file (defines functions)

            #############################################################################
            # When run thru above bash invocatation, generates lines: <function> <hash> #
            #############################################################################
            cat <<'EOF'
            declare -a _Functions
            readarray -t _Functions < <(
               declare -F |                              # Lists functions as: declare -f <function-name>
               grep '^declare -f' |                      # Ensure we look only for lines with the function name
               sed 's|.* ||'                             # Remove the declare -f prefix to get the function name
            )
            declare _Function
            for _Function in "${_Functions[@]}"; do
               echo "$_Function $( declare -f "$_Function" | tail -n +2 | md5sum | sed 's| .*||' )"
            done
EOF
         ) 2>"$_ErrorOutput"
      )" || {
         {
            for _BashFile in "${_BashFiles[@]}"; do      # For all .sh files...
               cat "$_BinDir/$_BashFile"                 # Load all .bash files prior to sourcing .sh files
            done                                         # as this may change the parsing of the .sh files

            cat "$_BinDir/$_ShFile"                      # Emit the current .sh file (defines functions)
         } | cat -n >&2

         echo -e "\nInvalid Bash file: $_ShFile" >&2
         cat "$_ErrorOutput" >&2

         rm -f "$_ErrorOutput"                           # Clean up
         return 1
      }

      readarray -t _FunctionItems < <(
         echo "$_ShFileFunctions"
      )

      local _FunctionItem                                # Iterator of the form: <function> <hash>
      local _Function                                    # Stores the <function>

      for _FunctionItem in "${_FunctionItems[@]}"; do    # For all functions
         _Function="${_FunctionItem%% *}"                # Get the <function>
         _HashKey="${_FunctionItem#* }"                  # Get the <hash>

         if [[ -n ${_FunctionToFile[$_Function]} ]]; then
            {
            echo "Warning: Duplicate function '$_Function' found in files:"
            echo "   ${_FunctionToFile[$_Function]}"
            echo "   $_ShFile"
            } >&2

            rm -f "$_ErrorOutput"                        # Clean up
            return 1
         fi

         _FunctionToFile[$_Function]="$_ShFile"          # Add the function to file path mapping
         _FunctionToHash[$_Function]="$_HashKey"         # Add the function to hash path mapping

         if [[ -n ${_HashToFunction[$_HashKey]} ]]; then
            _HashToFunction[$_HashKey]+=" $_ShFile|$_Function"
                                                         # Add the reverse mapping of hash to identical function

         else
            _HashToFunction[$_HashKey]="$_ShFile|$_Function"
                                                         # Store the reverse mapping of hash to function
         fi
      done
   done

   local -i DuplicateFunctionCount=
   local -i TotalDuplicates=
   local -i Duplicates=
   local DuplicateMarkers

   local -a _HashKeys
   readarray -t _HashKeys < <(
      printf '%s\n' "${!_HashToFunction[@]}" |
      LC_ALL=C sort -u |
      sed '/^\s*$/d'
   )

   {
      for _HashKey in "${_HashKeys[@]}"; do
         if [[ ${_HashToFunction[$_HashKey]} =~ ' ' ]]; then
            DuplicateMarkers="${_HashToFunction[$_HashKey]//[^ ]}"
            Duplicates="${#DuplicateMarkers}"
            DuplicateFunctionCount=$(( DuplicateFunctionCount + 1 ))
            TotalDuplicates=$(( TotalDuplicates + Duplicates + 1 ))

            echo "#$DuplicateFunctionCount IDENTICAL:"
            tr ' ' '\n' <<<"${_HashToFunction[$_HashKey]}" | sed 's|^|    |'
            echo
         fi
      done

      if (( DuplicateFunctionCount > 0 )); then
         echo "Duplicate Function Count:|$DuplicateFunctionCount"
         echo "Total Duplicates:|$TotalDuplicates"
      fi
   } | LC_ALL=C sed -e "s~^[^|]*$~&|~" -e "s~|~\x01~" | column -t -s $'\x01' | LC_ALL=C sed 's~\s*$~~'

   rm -f "$_ErrorOutput"                                 # Clean up

   #######################################################################
   # Create a $_FunctionsJSON file: maps functions to relative file paths #
   #######################################################################
   local _Key                                            # The key is the function name
   local _Path                                           # The value is the relative file path
   local _FunctionJSON=                                  # Start with an empty list

   for _Key in "${!_FunctionToFile[@]}"; do              # Iterate over all mappings
      _Path="$(                                          # Get the value first, because _Key is going to be modified
         python -c 'import json,sys; print (json.dumps(sys.stdin.read()))' <<<"${_FunctionToFile[$_Key]}" |
                                                         # This ensures that escapes are added as needed
         LC_ALL=C sed 's|\\n||g'                         # The above code adds a backslash n: remove it
      )"

      _HashKey="${_FunctionToHash[$_Key]}"

      _Key="$(
         python -c 'import json,sys; print (json.dumps(sys.stdin.read()))' <<<"$_Key" |
                                                         # This ensures that escapes are added as needed
         LC_ALL=C sed 's|\\n||g'                         # The above code adds a backslash n: remove it
      )"

      _FunctionJSON+="$_Key:{\"path\":$_Path,\"hash\":\"$_HashKey\"},"
                                                         # Add the JSON key:value pair with a comma at the end
   done

   mkdir -p "$_BaseDir/etc"                              # Ensure the etc directory exists

   jq -S . <<<"{ \"function\": { ${_FunctionJSON%,} } }" > "$_BaseDir/$_FunctionsJSON"
                                                         # Remove the trailing comma and wrap with outer dictionary
                                                         # Create the $_FunctionsJSON file, with sorted keys

   ! $_Verbose || echo -e "Done."
}

:list_append_to_array()                                  # Append comma-separated list to array
{
   local _ListToArray_Options
   _ListToArray_Options=$(getopt -o '' -l 'list:,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_ListToArray_Options"

   local _ListToArray_List=
   local _ListToArray_Var='_ListToArray_Var_Unspecified'

   while true ; do
      case "$1" in
      --list)     _ListToArray_List="$2"; shift 2;;
      --var)      _ListToArray_Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   [[ -v $_ListToArray_Var ]] || local -ag "$_ListToArray_Var=()"
                                                         # If the variable is not defined, then define it

   local _ListToArray_Indirect="$_ListToArray_Var[@]"
   local _ListToArray_Array=( "${!_ListToArray_Indirect}" )
                                                         # Copy the indices of the array as a way of knowing the
                                                         # length of the indirect array

   readarray -t -O "${#_ListToArray_Array[@]}" "$_ListToArray_Var" < <(
                                                         # Append to the indirect array
      sed -e 's|,|\n|g' <<<"$_ListToArray_List" |        # Expanding comma-separated items
      sed -e 's|^\s\+||' -e 's|\s\+$||' -e '/^$/d'       # ... and removing any blank entries
   )
}

:SetDirTags()                                            # Set _DirTags to nearest parent's tags otherwise empty
{
   local Dir="$1"
   if [[ -n ${_DirTags[$Dir]} ]]; then
      return 0                                           # If an entry exists, there is no need to examine parents
   fi

   local Parent="$Dir"

   while [[ $Parent != . ]]; do                          # Look until there are no more parents to examine
      Parent="$(dirname "$Parent")"                      # Get the next parent

      if [[ -n ${_DirTags[$Parent]} ]]; then             # If that parent exists, then use it and return
         _DirTags[$Dir]="${_DirTags[$Parent]}"
         return 0
      fi
   done

   _DirTags[$Dir]=                                       # No parent was found, so start with empty set of tags
}

:UpdateTags()                                            # Augment existing tags with tags in a file
{
   local -gx File="$1"

   local -a _TagCommands
   readarray -t _TagCommands < <(                        # Store all :tag commands in this array variable
      grep '^:tag ' "$File" || true |
      sed '/^\s*$/d'                                     # Remove any blank entries
   )

   local _TagCommand                                     # Store a single :tag command in this variable
   local -gx _TAGS_ENABLED=true                          # Enable :tags to actually do processing

   for _TagCommand in "${_TagCommands[@]}"; do
      $_TagCommand                                       # Run the :tag command. NOTE: Word splitting is intentional
   done
}

:tag()
{
   [[ $_TAGS_ENABLED = true ]] || return 0               # Do nothing unless _TAGS_ENABLED is set to true

   local Mode=set                                        # By default, set tags

   for Arg in "$@"; do
      case "$Arg" in
      -s|--set)   Mode=set;;                             # Switch to set mode
      -u|--unset) Mode=unset;;                           # Switch to unset mode

      *) [[ -n $Arg ]] || continue                       # Ignore any blank tags
         [[ ${Arg%%=*} =~ ^[a-zA-Z0-9_]*$ ]] || return 1
                                                         # Return 1 if the tag key is malformed

         if [[ $Mode = set ]]; then                      # SET THE TAG
            if [[ $Arg =~ = ]]; then                     # If the tag has a value
               _TAGS[${Arg%%=*}]="${Arg#*=}"             # ... create the tag with a value
            else
               printf -v "_TAGS[$Arg]" '%s' true         # ... otherwise, create the tag with no value
            fi

         else                                            # UNSET THE TAG
            unset _TAGS[${Arg%%=*}]                      # Discard any value to get just the key
         fi
         ;;
      esac
   done
}

:Copy()
{
   local SrcFile="$1"                                    # The source file under $_SrcDir
   mkdir -p "$_LibDir/${SrcFile%/*}"                     # Ensure the lib destination directory exists
   if ! $_IsShc; then
      cp -p "$_SrcDir/$SrcFile" "$_LibDir/$SrcFile"
   fi

   local Package
   local Remainder

   Package="$(sed "s|^\([^/]\+/[^/]\+\)/.*|\1|" <<<"$SrcFile")"
   Remainder="${SrcFile#$Package/}"

   if [[ $Remainder =~ bin/.* ]]; then                   # If the directory under the package dir is bin
      local DstFile="${Remainder%.sh}"                   # Then remove the .sh extension in the destination
      local BinFile="${DstFile#bin/}"                    # Get the portion following bin/
      local SrcMap=" $BinFile:[^ ]* "                    # Create a regex to find this src mapping

      if (( ${#_SrcDstMap[@]} > 0 )) && :ArrayContains --match _SrcDstMap "$SrcMap"; then
                                                         # If the src mapping exists,
         local _MapIndex
         _MapIndex="$(declare -p _SrcDstMap | grep -oP "\[\K[0-9]+(?=\]=\"$BinFile(\.sh)?:.*\")")"
                                                         # Get the index containing that src:dst mapping
         if [[ -n $_MapIndex ]]; then                    # A non-empty index means a match was found
            DstFile="${_SrcDstMap[$_MapIndex]#*:}"       # Get the dst from the src:dst mapping; prefix with bin/
         fi


      else
         DstFile="$BinFile"
      fi
   else
      local DstFile="$SrcFile"                           # Otherwise, leave the extension intact
   fi

   mkdir -p "$(dirname "$_BinDir/$DstFile")"             # Ensure the parent directory exists

   if [[ $_Extension = bash ]]; then
      sed '/^\s*:tag\>/d' "$_SrcDir/$SrcFile" > "$_BinDir/$DstFile"
      BashFilesToTransform+=( "$DstFile" )
   else
      cp "$_SrcDir/$SrcFile" "$_BinDir/$DstFile"         # Copy the source file to the destination directory
      ShFilesToTransform+=( "$DstFile" )

      if $_IsShc; then
         ShcFilesToTransform+=( "$DstFile" )
      fi
   fi
}

:ArrayHasElement()
{
   local ArrayName="$1"
   local String="$2"
   local Indirect="$ArrayName[*]"
   local IFS=$'\x01'

   [[ "$IFS${!Indirect}$IFS" =~ "$IFS${String}$IFS" ]]
}

:TransformFunctionFiles()
{
   cd "$_BaseDir"                                        # Results are created in the $_BaseDir

   if (( ${#BashFilesToTransform[@]} > 0 )); then
      ! $_Verbose || echo -e "Generating .bash Files\n"

      for BinFile in "${BashFilesToTransform[@]}"; do
         ! $_Verbose || echo "   $BinFile"

         :Transform "$BinFile"

         if [[ -n ${_Optimize[all]} || -n ${_Optimize[normalize]} ]]; then
            :Normalize "$BinFile"
         fi
      done

      ! $_Verbose || echo
   fi

   if (( ${#ShFilesToTransform[@]} > 0 )); then
      ! $_Verbose || echo -e "Generating .sh Files\n"

      for BinFile in "${ShFilesToTransform[@]}"; do
         ! $_Verbose || echo "   $BinFile"

         :Transform "$BinFile"

         if [[ -n ${_Optimize[all]} || -n ${_Optimize[normalize]} ]]; then
            :Normalize "$BinFile"
         fi

         if :ArrayHasElement ShcFilesToTransform "$BinFile"; then
cp "$_BinDir/$BinFile" ~/file.sh
            shc -f "$_BinDir/$BinFile" -o "$_BinDir/${BinFile%.sh}"
            chmod 755 "$_BinDir/${BinFile%.sh}"
            rm -f "$_BinDir/$BinFile.x.c" "$_BinDir/$BinFile"
         fi
      done
   fi
}

:Normalize()
{
   local BinFile="$1"

   cd "$_BinDir"

   local -a _BashFiles
   readarray -t _BashFiles < <(
      find . -mindepth 2 -name '[%@]*' -prune -o -type f -name '*.bash' -print |
                                                         # Get all .bash files
      LC_ALL=C sort |                                    # Lexically sort them
      sed -e 's|^\./||' -e '/^\s*$/d'                    # Remove leading ./ and remove any blank lines
   )

   local Functions
   local _ErrorOutput="$(mktemp)"                        # Any error output from Bash parsing files

   if [[ ! $BinFile =~ / ]]; then
      local IsEntryPoint=true
   else
      local IsEntryPoint=false
   fi

   Functions="$(
      bash <(
         local _BashFile
         for _BashFile in "${_BashFiles[@]}"; do         # For all .sh files...
            cat "$_BinDir/$_BashFile"                    # Load all .bash files prior to sourcing .sh files
         done                                            # as this may change the parsing of the .sh files

         cat "$_BinDir/$BinFile" |
         sed "/^:main /d"

         echo declare -f
      ) 2>"$_ErrorOutput"
   )" || {
      {
         local _BashFile
         for _BashFile in "${_BashFiles[@]}"; do         # For all .sh files...
            cat "$_BinDir/$_BashFile"                    # Load all .bash files prior to sourcing .sh files
         done                                            # as this may change the parsing of the .sh files

         cat "$_BinDir/$BinFile" |
         sed "/^:main /d"
      } | tee ~/problem.sh | cat -n >&2

      echo -e "\nInvalid Bash file: $BinFile" >&2
      cat "$_ErrorOutput" >&2

   }

   rm -f "$_ErrorOutput"

   {
      [[ $BinFile =~ / ]] || echo $'#!/bin/bash\n'
      echo "$Functions"
      ! $IsEntryPoint || echo -e "\n:main \"\$@\""
   }> "$_BinDir/$BinFile"
}

:EscapeSed()
{
   local Options
   Options=$(getopt -o 'n' -l 'nl' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$Options"

   local EscapeNewlines=false
   while true ; do
      case "$1" in
      -n|--nl) EscapeNewlines=true; shift;;
      --)      shift; break;;
      *)       break;;
      esac
   done

   awk '{ gsub(/[][^$.*?+\/\\()&]/, "\\\\&"); print }' <<<"$@" |
   {
      if $EscapeNewlines; then
         LC_ALL=C sed -- ':a;N;$!ba;s/\n/\\n/g'
      else
         cat
      fi
   }
}

:Transform()
{
   local DstFile="$1"                                    # Transform this source file to a destination file
   local LoadOnly
   LoadOnly='set -- --load-only "$@"; . "$(dirname "$0")/'
   LoadOnly+="$( sed -e 's|/[^/]\+$||' -e 's|[^/]\+|..|g' <<<"$DstFile" )"'"'

   ############################################
   # Setup Package, Component, and Unit Names #
   ############################################

   # Set the defaults for an entrypoint file
   local Package=.
   local PackageDir=
   local Remainder=

   # For non-entrypoints
   if [[ $DstFile =~ / ]]; then
      Package="$(sed "s|^\([^/]\+/[^/]\+\)/.*|\1|" <<<"$DstFile")"
      PackageDir="$Package"
      Remainder="${DstFile#$Package/}"
   fi

   # At this point, $Package is a 2-level directory: <package>/<sub-package>

   local PTLDPackage="${Package%/*}"

   local Component=                                      # The component is the optional 2nd level directory
   local Unit=                                           # The Unit is the optional 3rd level directory
   local Script=                                         # The Script consists of unit directories and the filename

   :StringToNamespace Package                            # Ensure string conforms to namespace conventions

   # At this point, $Package is a dot-separated name <package>[.<sub-package>]

   if [[ $Remainder =~ / ]]; then                        # Check if a component directory is present
      Component="${Remainder%%/*}"                       # The component name is the directory name
      Remainder="${Remainder#$Component/}"               # Strip off the component, leaving Unit and subdirectories
      :StringToNamespace Component                       # Ensure string conforms to namespace conventions

      if [[ $Remainder =~ / ]]; then                     # Check if the file is under a unit directory
         Unit="${Remainder%%/*}"                         # The unit name is the directory name
      else
         Unit="${Remainder%.*sh}"                        # Strip off .bash or .sh to get the unit name
      fi
      :StringToNamespace Unit                            # Ensure string conforms to namespace conventions
   fi

   Script="$(echo -n "$Remainder" | sed -e "s|\.sh||" -e "s|/|__|g" | tr -c 'a-zA-Z0-9' _)"
                                                         # The Script does not include the filename extension,
                                                         # and directory separators are changed to double underscores
   :StringToNamespace Script                             # Ensure string conforms to namespace conventions

   #########################
   # Perform Substitutions #
   #########################
   if [[ $Package = '.' ]]; then                         # For common package variables and functions:
      local PVar=                                        # No prefix for system variables
      local PFunc=                                       # No prefix for system functions
      local PTLDVar=
      local PTLDFunc=
      local PTLDDir=_                                    # The system TLD is _

   else
      local PVar
      PVar="$( echo -n "$Package" | tr -c 'a-zA-Z0-9' _ )"
                                                         # The prefix for non-system variables has var syntax
      local PTLDVar
      PTLDVar="$( echo -n "${DstFile%%/*}" | tr -c 'a-zA-Z0-9' _  | sed 's|^_$||' )"

      local PTLDFunc="${PTLDPackage/_/}"                 # For TLD.s constructions, remove leading . converted to _
                                                         # The prefix for the top-level package
      local PFunc="$Package"                             # The prefix for non-system functions is the package name
      local PTLDDir="${DstFile%%/*}"                     # The TLD is the top directory from $DstFile
   fi

   local CVar
   CVar="__$( echo -n "$Component" | tr -c 'a-zA-Z0-9' _ )" # The variable prefix is __ followed by the component name
   local CFunc=":$Component"                             # The function prefix is : followed by the component name

   local UVar
   UVar="__$( echo -n "$Unit" | tr -c 'a-zA-Z0-9' _ )"   # The variable prefix is __ followed by the unit name
   local UFunc=":$Unit"                                  # The function prefix is : followed by the unit name

   local DstSource
   DstSource="$(cat "$_BinDir/$DstFile")"

   ### Perform function-level substitutions of (.)_ variable idioms
   awk \
      -v RS='(^|\n)[@+-]  *([a-zA-Z%][a-zA-Z0-9_%]* *\\( *\\)|\\( *\\))' \
      -v ORS='' \
      -v Package="${PVar}__" \
      -v Component="${Component}__" \
      -v Script="${Script}__" \
      <<<"$DstSource" \
   '
   BEGIN { FuncVarPrefix="" }                            # Start as not inside a function block
      # RS breaks content into $0 and RT blocks
      #     - $0 is the content that precedes the NEXT function block
      #     - RT is the declaration of the next function
      # ORS is set to the empty string to avoid unwanted newlines
      {
         # Transform unescaped (.)_ idioms to use the currently-defined function
         printf "%s", gensub(/(^|[^\\])\(\.\)_([a-zA-Z0-9_]*)/, "\\1" FuncVarPrefix "___\\2", "g", $0 RT)

         # Extract the function name from RT for the next $0 block to be processed
         FuncVarPrefix=Package Component Script gensub(/\n[@+-]\s*([^( ]*)\s*\(\s*\)/, "\\1", "g", RT)
         FuncVarPrefix=gensub(/%/, "", "g", FuncVarPrefix)
      }
   ' |

   sed "
      ###########
      # PACKAGE #
      ###########
      s,^@\s\+,$PFunc:,                                                 # @ func          Package declaration of func

      ### VARIABLES
      s,\(^\|[^\]\)(@)_,\1${PVar}___,g                                   # (@)_var        Current package var
      s,\(^\|[^\]\)(@:\.\([^/)]\+\))_,\1\x01${PTLDVar}_\2\x02___,g       # (@:.s)_var     Package TLD.s var
      s,\(^\|[^\]\)(@:\([^/)]\+\))_,\1\x01\2\x02___,g                    # (@:p)_var      Package p var
      s,\(^\|[^\]\)(@@)_,\1___,g                                         # (@@)_var       Common package var
      s,\(^\|[^\]\)(@@:\.\([^/)]\+\))_,\1_\2___,g                        # (@@:.s)_var    Package TLD.s var

      ### FUNCTIONS
      s,\(^\|[^\]\)(@):,\1$PFunc:,g                                     # (@):func        Current package func
      s,\(^\|[^\]\)(@:\(\.[^/)]\+\)):,\1\x03$PTLDFunc\2\x04:,g          # (@:.s):func     Package TLD.s func
      s,\(^\|[^\]\)(@:\([^/)]\+\)):,\1\x03\2\x04:,g                     # (@:p):func      Package p func
      s,\(^\|[^\]\)(@@):,\1:,g                                          # (@@):func       Common package func
      s,\(^\|[^\]\)(@@:\(\.[^/)]\+\)):,\1\2:,g                          # (@@:.s):func    Package TLD.s func

      ### PATHS
      s,\(^\|[^\]\)(@)/,\1\"\$_lib_dir/$PackageDir\"/,g                 # (@)/            Current path
      s,\(^\|[^\]\)(@:\.\([^/)]\+\))/,\1\"\$_lib_dir/$PTLDDir/\2\"/,g   # (@:.s)/         Package TLD.s path
      s,\(^\|[^\]\)(@:\([^/)]\+/[^/)]\+\))/,\1\"\$_lib_dir/\2\"/,g      # (@:t/s)/        Package p path
      s,\(^\|[^\]\)(@@)/,\1\"\$_lib_dir/_/_\"/,g                        # (@@)/           Common path
      s,\(^\|[^\]\)(@@:\.\([^/)]\+\))/,\1\"\$_lib_dir/_/\2\"/,g         # (@@:.s)/        Package TLD.s path

      ### Escaped idioms
      s,^\\\\\(@\s\+\),\1,
      s,\\\\(@),(@),g                                                   # Escape package var and func
      s,\\\\(\(@@\?\):\([^)]*\)),(\1:\2),g                              # Escape named Package p var, func, and path
      s,\\\\(@@),(@@),g                                                 # Escape common package var and func
      s,\\\\(@/),(@/),g                                                 # Escape package path
      s,\\\\(@@/),(@@/),g                                               # Escape common path

      #############
      # COMPONENT #
      #############
      s|^+\s\+|$PFunc$CFunc:|                                           # + func          Component declaration of func

      ### VARIABLES
      s,\(^\|[^\]\)(+)_,\1${PVar}${CVar}___,g                           # (+)_var         Current component var
      s,\(^\|[^\]\)(+:\([^/:)]\+\))_,\1${PVar}__\2___,g                 # (+:c)_var       Component c var
      s,\(^\|[^\]\)(+:\.\([^/:)]\+\):\([^/:)]\+\))_,\1\x01${PTLDVar}_\2\x02__\3___,g
                                                                        # (+:.s:c)_var    Package TLD.s component c var
      s,\(^\|[^\]\)(+:\([^/:)]\+\):\([^/:)]\+\))_,\1\x01\2\x02__\3___,g # (+:p:c)_var     Package p component c var
      s,\(^\|[^\]\)(++:\.\([^:)]\+\):\([^)]\+\))_,\1_\2__\3___,g        # (++:.s:c)_var   Common TLD.s component c var
      s,\(^\|[^\]\)(++:\([^/)]\+\))_,\1__\2___,g                        # (++:c)_var      Common component c var

      ### FUNCTIONS
      s,\(^\|[^\]\)(+):,\1$PFunc$CFunc:,g                               # (+):func        Current component func
      s,\(^\|[^\]\)(+:\([^/:)]\+\)):,\1$PFunc:\2:,g                     # (+:c):func      Component c func
      s,\(^\|[^\]\)(+:\(\.[^/:)]\+\):\([^/:)]\+\)):,\1\x03$PTLDFunc\2\x04:\3:,g
                                                                        # (+:.s:c):func   Package TLD.s component c func
      s,\(^\|[^\]\)(+:\([^/:)]\+\):\([^/:)]\+\)):,\1\x03\2\x04:\3:,g    # (+:p:c):func    Package p component c func
      s,\(^\|[^\]\)(++:\(\.[^:)]\+\):\([^/:)]\+\)):,\1\2:\3:,g          # (++:.s:c):func  Common TLD.s component c func
      s,\(^\|[^\]\)(++:\([^/)]\+\)):,\1:\2:,g                           # (++:c):func     Common component c func

      ### PATHS
      s,\(^\|[^\]\)(+)/,\1\"\$_lib_dir/$PackageDir/$Component\"/,g      # (+)/            Current current component path
      s,\(^\|[^\]\)(+:\([^/:)]\+\))/,\1\"\$_lib_dir/$PackageDir/\2\"/,g # (+:c)/          Component c path
      s,\(^\|[^\]\)(+:\.\([^/:)]\+\):\([^/:)]\+\))/,\1\"\$_lib_dir/$PTLDDir/\2/\3\"/,g
                                                                        # (+:.s:c)/       Package TLD.s component c path
      s,\(^\|[^\]\)(+:\([^/:)]\+/[^/:)]\+\):\([^/:)]\+\))/,\1\"\$_lib_dir/\2/\3\"/,g
                                                                        # (+:t/s:c)/      Package p component c path
      s,\(^\|[^\]\)(++:\.\([^:)]\+\):\([^)]\+\))/,\1\"\$_lib_dir/_/\2/\3\"/,g
                                                                        # (++:.s:c)/      Package TLD.s component c path
      s,\(^\|[^\]\)(++:\([^/)]\+\))/,\1\"\$_lib_dir/_/_/\2\"/,g         # (++:c)/         Common component c path

      ### Escaped idioms
      s,^\\\\\(+\s\+\),\1,
      s,\\\\(+),(+),g                                                   # Escape current component var and func
      s,\\\\(+:\([^)]*\)),(+:\1),g                                      # Escape named component var, func, and path
      s,\\\\(++:\([^)]*\)),(++:\1),g                                    # Escape named common component var, func, and path
      s,\\\\(+/),(+/),g                                                 # Escape current component path

      ########
      # UNIT #
      ########
      ### All mappings are within the current package

      s|^-\s\+|$PFunc$CFunc$UFunc:|

      ### VARIABLES
      s,\(^\|[^\]\)(-)_,\1${PVar}$CVar${UVar}___,g                      # (-)_var         Current component current unit var
      s,\(^\|[^\]\)(-:\([^:)]\+\))_,\1${PVar}${CVar}__\2___,g           # (-:u)_var       Current component unit u var
      s,\(^\|[^\]\)(-:\([^/:)]\+\):\([^/:)]\+\))_,\1${PVar}__\2__\3___,g
                                                                        # (-:c:u)_var     Component c unit v var
      s,\(^\|[^\]\)(--:\([^/:)]\+\):\([^/:)]\+\))_,\1__\2__\3___,g      # (--:c:u)_var    Common component c unit u var

      ### FUNCTIONS
      s,\(^\|[^\]\)(-):,\1$PFunc$CFunc$UFunc:,g                         # (-):func        Current component current unit func
      s,\(^\|[^\]\)(-:\([^:/)]\+\)):,\1$PFunc$CFunc:\2:,g               # (-:u):func      Current component u func
      s,\(^\|[^\]\)(-:\([^/:)]\+\):\([^/:)]\+\)):,\1$PFunc:\2:\3:,g     # (-:c:u):func    Component c unit u func
      s,\(^\|[^\]\)(--:\([^/:)]\+\):\([^/:)]\+\)):,\1:\2:\3:,g          # (--:c:u):func   Common component c unit u func

      ### PATHS
      s,\(^\|[^\]\)(-)/,\1\"\$_lib_dir/$PackageDir/$Component/$Unit\"/,g
                                                                        # (-/)            Current unit path
      s,\(^\|[^\]\)(-:\([^/:)]\+\))/,\1\"\$_lib_dir/$PackageDir/$Component/\2\"/,g
                                                                        # (-:u/)          Current component current unit u path
      s,\(^\|[^\]\)(-:\([^/:)]\+\):\([^/:)]\+\))/,\1\"\$_lib_dir/$PackageDir/\2/\3\"/,g
                                                                        # (-:c:u/)        Component c unit u path
      s,\(^\|[^\]\)(--:\([^/:)]\+\):\([^/:)]\+\))/,\1\"\$_lib_dir/_/_/\2/\3\"/,g
                                                                        # (--:c:u/)       Common component c unit u path

      ### OTHER
      s#\(^\|[^\]\)(||)#\1; (exit \$?) ||#g                             # (||) alternative to || - Does not mask errors (set -e)
      s#\(^\|[^\]\)(&&)#\1; (exit \$?) \&\&#g                           # (&&) alternative to && - Does not mask errors (set -e)
      s#\(^\|[^\]\)(%LOAD_FUNCTIONS%)#\1$LoadOnly/$_Loader; shift#g     # Token replacement for the loader entrypoint

      ### Escaped idioms
      s,^\\\\\(-\s\+\),\1,                                              # Escape unit declaration
      s,\\\\(-),(-),g                                                   # Escape current component var and func
      s,\\\\\((--\?:[^)]*)\),\1,g                                       # Escape named component var, func, and path
      s,\\\\(-/),(-/),g                                                 # Escape current component path
      s,\\\\(||),(||),g                                                 # Escape mask-checked OR
      s,\\\\(&&),(\&\&),g                                               # Escape mask-checked AND
      s,\\\\(\.),(.),g                                                  # Escape function variable

      ### Adjust package variable specifiers \x01...\x02
      s,\x01_\x02,_,g                                                   # Common is replaced by _
      s,\x01\([^\x02]*\)\x02,\1,g                                       # Others are left intact

      ### Adjust package function specifiers \x03...\x04
      s,\x03_\x04,,g                                                    # Common is replaced by nothing (colon is already present)
      s,\x03\([^\x04]*\)\x04,\1,g                                       # Others are left intact
   " |

   cat > "$_BinDir/$DstFile"

   local DstFileAsString
   DstFileAsString="$(cat "$_BinDir/$DstFile")"
   if [[ -z $DstFileAsString ]]; then
      rm -f "$_BinDir/$DstFile"
   fi

   if [[ ! $DstFile =~ / ]]; then                        # Only entrypoints should be executable
      chmod a+x "$_BinDir/$DstFile"                      # If the $DstFile is in bin, make it executable
   fi
}

:StringToNamespace()
{
   local _Var="$1"                                       # Update the indicated variable
   local _Value="${!_Var}"                               # Get the value of this variable

   printf -v "$_Var" '%s' "$(                            # Write back to the indicated variable
      if [[ $_Value =~ / ]]; then                        # Converting <package-tld>/<package-subdomain>?
         ### Package
         if [[ ${_Value%%/*} = _ ]]; then                # Is it a system package (_/*)?
            if [[ ${_Value#*/} = _ ]]; then              # Does it have a sub-package?
               echo '.'                                  # No, use _ as the package name
            else
               echo ".${_Value#*/}"                      # Yes, use _<sub-package> as the package name
            fi

         else                                            # It is NOT a system package
            if [[ ${_Value#*/} = _ ]]; then              # Does it have a sub-package?
               echo "${_Value%%/*}"                      # No
            else
               echo "${_Value%%/*}.${_Value#*/}"
            fi
         fi

      else
         ### Component, Unit, Script
         echo -n "$_Value" | tr -cd '[:alnum:]._-'       # Delete characters other than [a-zA-Z0-9._-]
      fi
   )"
}

:ArrayContains()
{
   local Options
   Options=$(getopt -o '' -l 'anchored' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$Options"

   local Anchored=false
   while true ; do
      case "$1" in
      --anchored) Anchored=true; shift;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   local ArrayName="$1"                                  # The array name to be checked
   local String="$2"                                     # The string: see if this is an element of the array
   local Indirect="$ArrayName[*]"                        # Create an indirection string: expand in place
   local IFS=$'\x01'                                     # Use $IFS to separate array entries

   if $Anchored; then
      # Perform an anchored RegEx match
      [[ "$IFS${!Indirect}$IFS" =~ $IFS${String} ]]
   else
      # Perform a literal string match
      [[ "$IFS${!Indirect}$IFS" =~ "$IFS${String}$IFS" ]]
   fi
}

:main "$@"; exit
