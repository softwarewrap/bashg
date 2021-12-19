#!/bin/bash

+ %HELP()
{
   :help: --set 'Call curl with additional functionaltity' --usage '<options> [-- <curl-pass-thru-options> ]' <<'EOF'
RESULTS OPTIONS:
   --info-var <info-var>^
      Store metadata information in the associative array <info-var>. Metadata keys include:
         http_code   - The http_code returned when running the underlying curl(1) command
         status      - the return status of the underlying curl(1) command
         <format>    - the value returned by using the --get option
   --body-var <body-var>^
      Store the response body in the <body-var> variable.
      It must be the case that the response body must be non-binary data because Bash variables
      do not support storing NULL (hex 00) character strings.
      To store binary data, use the --output option.
   --headers-var <headers-var>^
      Store the response headers in the <headers-var> variable
   --get <format>^
      The underlying curl(1) command supports writing out metadata via the --write-out <format> option.
      This option stores the value obtained into the <info-var> associative array variable.
   --filter <filter>^
      Apply the JSON <filter> to the response body before storing the result in the <body-var>.

CURL ARGUMENTS OPTIONS:
   --callback <callback-name>^
      Call the function <callback-name> that modifies the \(++curl)_Args array variable.
   --url <path>
      A full URL or local filesystem path as an alternative to using the 4 options below:
      The path can be either a URL that includes <scheme> and <host> and optionally includes
      <port> and <context>, or it can be a filesystem path that is either relative or absolute.

      --scheme <scheme>^
         HTTP scheme: one of http or https only
      --host <host>^
         A resolvable host name or IP address
      --port <port>^
         a port number.
      --resource <path>^
         URL resource path that identifies the specific resource on the host to access.

EXECUTION OPTIONS:
   --timeout <duration>^
      Terminate the underlying curl(1) command if it is still running after <duration> seconds.
   --show^
      Show command to stdout prior to execution.
   --show-change <change>^
      When showing, perform the <change> replacement.
   --dry-run^
      Do not execute the curl command (implies --show).
   --quiet^
      Do not emit error messages.
   --output <file>^
      Store the response body to <file>
   --expect <code-regex>^
      Expect the <info-var> <b>http_code</b> to match the anchored <code-regex>.
      If the <http-expect> code is a single digit, then [0-9][0-9] is automatically appended.
      For example, <B>--expect 2</B> is equivalent to <B>--expect '2[0-9][0-9]'</B>.
      Quoting must be used when passing regex strings that include characters that might otherwise
      be interpreted immediately by the shell.

DESCRIPTION:
   Wrapper for curl(1) that provides convenience functionality including curl variable extraction,
   callbacks for authentication and custom needs, JSON parsing, timeouts, and more.

   Notes:
      The <info-var> variable should not be declared before use. It is automatically unset and then declared.
      The <body-var> variable may be declared in advance, but if it is not declared, it will automatically
      be declared. The same applies to the <headers-var> variable.
      The above variables are declared with global scope.

      If -- is present as an argument, then all arguments before it are parsed as \(++):curl_Args arguments
      and those follow -- are passed directly to the underlying curl(1) command.

CALLBACK VARIABLES:
   \(++:curl)_Args               ^The options to pass to curl that can be modified by callbacks

RETURN STATUS:
   0  ^Success
   1  ^Error with the invocation of :curl:
   2  ^The native curl returned non-zero and is stored in the <info-var> <b>status</b> element.
   3  ^JSON <filter> returned non-zero and is stored in the <info-var> <b>status</b> element.
   4  ^The <http-expect> test returned non-zero: consult the <info-var> <b>http_code</b> element.

EXAMPLE:
   local -a \(.)_Options=(           ^^>GThe first block of args are consumed by :curl:
      --info-var     \(.)_Info       ^Use the Info variable to store metadata information
      --body-var     \(.)_Body       ^Store the response body in the Body variable
      --headers-var  \(.)_Header     ^Store the response headers in the Header variable
      --get          http_code      ^Get the response HTTP code
      --get          url_effective  ^Get the effective URL, if present

      --                            ^^>GThe second block of args are consumed directly by curl(1)
      -s -k                         ^Additional arguments
   )^
   :curl: --url 'https://some/path' "${\(.)_Options[@]}" -L^
                                    Get metadata info needed for second :curl: call

   if [[ -n ${\(.)_Info[url_effective]} ]]; then^
      \(.)_MY_Redirect="$(\(.)_MY_get_redirect "${Info[url_effective]}")"^
                                    Modify the effective URL
      local -a Callback=( \(++:curl)_auth_tmpl --basic "admin:mypassword" )^
                                    Array contains function call parameters that inject into
                                    options processed by :curl:

      :curl: --url "$\(.)_MY_Redirect" --callback Callback "${\(.)_Options[@]}"^
                                    Add \(++:curl)_auth_tmpl callback for authentication to this :curl: call

      if [[ ${\(.)_Info[http_code]} =~ ^2[0-9][012]$ ]]; then^
         echo 'Success'             ^Success on HTTP OK, Created, or Accepted
      else^
         echo 'Fail'                ^Indicate failure otherwise
      else^
   fi^
EOF
}

+ ()
{
   :getopts: begin \
      -o ':s:h:p:r:u:o:e:' \
      -l 'callback:,info-var:,get:,body-var:,headers-var:,filter:,timeout:,show,show-change:,dry-run,quiet,scheme:,host:,port:,resource:,url:,output:,expect:' \
      -- "$@"

   local (.)_Option                                      # Iterate over options
   local (.)_Value                                       # For options that take args, store in this variable

   local -a (.)_CallbackVars=()                          # Callback to modify \(+)_Args

   local (.)_InfoVar="(.)_UnspecifiedInfoVar"            # Use this variable name if none is specified by --info-var
   local -a (.)_GetVars=()                               # Get curl variables. See curl(1): --write-out

   local (.)_BodyVar="(.)_UnspecifiedBodyVar"            # Store the response body in this variable
   local (.)_HeadersVar="(.)_UnspecifiedHeadersVar"      # Store the response headers in this variable
   local (.)_HeadersTmpFile=                             # Store the response headers temporarily in this file
   local (.)_Filter=                                     # Apply the JSON jq filter to the response body

   local (.)_Timeout=                                    # Terminate the curr command after the given duration

   local (.)_Show=false                                  # Show the curl command to stdout prior to execution
   local -a (.)_Changes=()                               # Do not show these patterns

   local (.)_DryRun=false                                # Perform a dry run only
   local (.)_Quiet=false                                 # Emit error messages

   local (.)_Scheme=                                     # Either http or https
   local (.)_Host=                                       # Host or IP address
   local (.)_Port=                                       # Port number
   local (.)_ResourcePath=                               # The resource path follows the host and port
   local (.)_Url=                                        # A fully-formed alternative to the above 4 variables

   local (.)_Output=                                     # Store the response body to a file
   local (.)_IsTmpOutput=false

   local (.)_Expect=

   local -ag (+)_Args=()                                 # These are the arguments that are passed to curl(1)

   while :getopts: next (.)_Option (.)_Value; do
      case "$(.)_Option" in
      --callback)    (.)_CallbackVars+=( "$(.)_Value" );;

      --info-var)    (.)_InfoVar="$(.)_Value";;          # Store metdata information in this variable
      --get)         (.)_GetVars+=( "$(.)_Value" );;     # Get curl variables

      --body-var)    (.)_BodyVar="$(.)_Value";;          # Store the response body in this variable
      --headers-var) (.)_HeadersVar="$(.)_Value";;       # Store the response headers in this variable
      --filter)      (.)_Filter="$(.)_Value";;           # Apply the JSON jq filter to the response body

      --timeout)     (.)_Timeout="$(.)_Value";;          # Terminate the curl command after specified duration

      --show)        (.)_Show=true;;                     # Enable showing the curl command prior to execution
      --show-change) (.)_Changes=("$(.)_Value")          # Do not show <curl-pass-thru-options> matching <name>
                     (.)_Show=true;;

      --dry-run)     (.)_DryRun=true; (.)_Show=true;;    # Dry run: just show then return
      --quiet)       (.)_Quiet=true;;                    # Do not emit error messages

      -s|--scheme)   (.)_Scheme="$(.)_Value";;           # http or https
      -h|--host)     (.)_Host="$(.)_Value";;             # FQDN
      -p|--port)     (.)_Port="$(.)_Value";;             # Numeric port
      -r|--resource) (.)_ResourcePath="$(.)_Value";;     # Resource path following the above 3 entries
      -u|--url)      (.)_Url="$(.)_Value";;              # Alternative to the above 4: full URL or local path

      -o|--output)   (.)_Output="$(.)_Value";;           # Write response body to the indicated file

      -e|--expect)   (.)_Expect="${(.)_Value/^}";;       # Specify an http_code expect regex string; strip anchor

      *)          break;;
      esac
   done

   :getopts: end --save (+)_Args --append                # Save unused args as args to be used by curl

   unset "$(.)_InfoVar"                                  # Clear the associative array before running curl
   local -Ag "$(.)_InfoVar"                              # Now, the declaration contains no elements

   local (.)_ReturnStatus=0                              # Presume success

   ### Save Response Body to a File
   if [[ -z $(.)_Output ]]; then                         # If no explicit output file is specified,
      (.)_Output="$(mktemp)"                             # then create a temporary file for the output
      (.)_IsTmpOutput=true                               # and mark this as temporary
   fi
   (+)_Args+=( -o "$(.)_Output" )                        # Save response body to the specified file

   ### Save Response Headers to a Temporary File
   if [[ $(.)_HeadersVar != (.)_UnspecifiedHeadersVar ]]; then
      (.)_HeadersTmpFile="$(mktemp)"                     # Create a temporary file to store response headers
      (+)_Args+=( -D "$(.)_HeadersTmpFile" )             # Dump the headers to this file
   fi

   ##########################################################################################
   # Construct URL; See: Scheme definition: https://tools.ietf.org/html/rfc3986#section-3.1 #
   ##########################################################################################
   if [[ -n $(.)_Url ]]; then                            # Check if a URL is explicitly specified
      if [[ ( $(.)_Url =~ ^[/.] ) &&                     # If start is absolute or relative path and not a scheme
            ! $(.)_Url =~ ^[a-zA-Z][a-zA-Z0-9.+-]*'://' ]]; then

         if [[ ! -f  $(.)_Url ]]; then
            if ! $(.)_Quiet; then
               :error: "No such file: $(.)_Url"          # If file doesn't exist and not quiet, emit message
            fi

            printf -v "$(.)_InfoVar[status]" '%s' 1
            return 1
         fi

         (.)_Url="file://$(readlink -fm "$(.)_Url")"     # Normalize the URL with the file:// scheme
      fi

   elif [[ -n $(.)_Scheme && -n $(.)_Host ]]; then       # Scheme and Host are required
      (.)_Url="$(.)_Scheme://$(.)_Host"                  # Begin constructing the URL with scheme and host

      if [[ -n $(.)_Port ]]; then
         (.)_Url+=":$(.)_Port"                           # Add a port if one is provided
      fi

      if [[ -n $(.)_ResourcePath ]]; then                # If a resource path is specified, then use it
         (.)_Url+="/${(.)_ResourcePath#/}"               # Append the resource path, stripping any leading /
      fi

   else
      if ! $(.)_Quiet; then
         :error: 'Either <scheme> and <host> or <path> must be specified'
      fi

      printf -v "$(.)_InfoVar[status]" '%s' 1
      return 1
   fi

   (+)_Args+=( "$(.)_Url" )                              # Add the URL to the curl args

   #################################################
   # Run Provided Callbacks that Modify \(+)_Args   #
   #################################################
   if ((${#(.)_CallbackVars[@]} > 0)); then
      local (.)_CallbackVar                              # Iterate over CallbackVars

      for (.)_CallbackVar in "${(.)_CallbackVars[@]}"; do
         local (.)_IndirectCallbackVar="$(.)_CallbackVar[@]"
                                                         # Create the array indirection pattern: command and args
         set -- "${!(.)_IndirectCallbackVar}"            # Set positional parameters to the command and args

         if :test:has_func "$1"; then                    # If $1 is a known function,
            "$@" || (.)_ReturnStatus=$?                  # ... then execute the function along with the args
            if (( $(.)_ReturnStatus != 0 )); then
               if ! $(.)_Quiet; then
                  :error: "Curl callback $1 returned status code: $(.)_ReturnStatus"
               fi

               printf -v "$(.)_InfoVar[status]" '%s' 1
               return 1
            fi
         fi
      done
   fi

   ############################################
   # Construct Curl Variable Format Arguments #
   ############################################
   local (.)_CodePrefix=$'\x08\x14\x14\x10{'             # A unique prefix: Control 'HTTP' + {
   local (.)_CodeSuffix=$'}\x08\x14\x14\x10'             # A unique suffix: } + Control 'HTTP'

      # Create the option for curl variable names
   if [[ ${#(.)_GetVars[@]} -gt 0 ]]; then               # If requesting curl variable data
      local (.)_Format=                                  # Start with empty string for the format
      local (.)_GetVar                                   # Iterator for (.)_GetVars

      if [[ -n $(.)_Expect &&                            # Ensure that http_code is present if --expect is used
            ( ! " ${(.)_GetVars[@]} " =~ ' http_code ' ) ]]; then
         (.)_GetVars+=( 'http_code' )
      fi

      :array:sort --var (.)_GetVars --unique             # Ensure only unique curl vars are requested

      for (.)_GetVar in "${(.)_GetVars[@]}"; do
         (.)_Format+="\n$(.)_CodePrefix $(.)_GetVar: %{$(.)_GetVar}$(.)_CodeSuffix"
                                                         # Construct a parseable format for the GetVar
      done
      (.)_Format+="\n"                                   # The format is now bounded by newlines

      (+)_Args+=( '-w' "$(.)_Format" )                   # Add the block of formats to curl
   fi

   ###################################
   ### RUN THE NATIVE CURL COMMAND ###
   ###################################
   if $(.)_Show; then
      local -a (.)_ShowArgs=()                           # The collected list of args to show
      local (.)_Arg                                      # Iterator over (+)_Args

      local (.)_Change                                   # Iterator over (.)_Changes

      # Nested iterators: over (+)_Args and (.)_Changes
      for (.)_Arg in "${(+)_Args[@]}"; do
         for (.)_Change in "${(.)_Changes[@]}"; do
            local D="${(.)_Change:0:1}"                  # Get the delimiter
            (.)_Search="${(.)_Change:1}"                 # Remove the leading delimiter
            (.)_Search="${(.)_Search%$D}"                # Remove the trailing delimiter

            ###################################################################################################
            # The replacement can have capture groups. The printf escapes everything, including the backslash #
            # in front of capture groups resulting in two backslashes. Replace \\<capture-group> with         #
            # \<capture-group> that preserves the capture group as is, but otherwise adds quoting to treat    #
            # characters as literals instead of actionable sequences such as redirection (< >),               #
            # backgrounding (&), parameter dereferencing ($), etc.                                            #
            ###################################################################################################
            (.)_Replace="$(printf '%q\n' "${(.)_Search#*$D}" | sed 's|\\\\\([0-9]\+\)|\\\1|g')"

            (.)_Search="${(.)_Search%%$D*}"              # Remove the replacement, leaving just the search string

            if [[ $(.)_Arg =~ $(.)_Search ]]; then       # If a change is needed, then make it
               (.)_Replace="$( sed 's|\\\([0-9]\+\)|\${BASH_REMATCH\[\1\]}|g' <<<"$(.)_Replace" )"
                                                         # Convert capture groups to reference the match variable
               eval (.)_Arg="$(.)_Replace"               # Eval to dereference the match variable BASH_REMATCH.
                                                         # This is safe due to the quoting above.
            fi
         done

         (.)_ShowArgs+=( "$(.)_Arg" )
      done

      echo "================================================== CURL INVOCATION"
      echo "curl ${(.)_ShowArgs[@]}"
      echo "=================================================="
   fi

   if $(.)_DryRun; then                                  # If this is a dry run, then just return
      return 0
   fi

   local (.)_HTTPResponse                                # Store the HTTP response (not response headers)

   (.)_HTTPResponse="$(
      if [[ -n $(.)_Timeout ]]; then                     # Apply a timeout if requested
         local (.)_Kill="$(($(.)_Timeout + $(.)_Timeout / 10))"
                                                         # Kill time = timeout time + 10%
         ### RUN CURL WITH TIMEOUT
         timeout -k "${(.)_Kill}s" -s KILL "${(.)_Timeout}s" curl "${(+)_Args[@]}"

      else
         ### RUN CURL
         curl "${(+)_Args[@]}"
      fi
   )" || (.)_ReturnStatus=$?

   ##################################
   # Get Curl Variable Data Results #
   ##################################
   printf -v "$(.)_InfoVar[status]" '%s' "$(.)_ReturnStatus"

   if (( ${#(.)_GetVars[@]} > 0 )); then
      for (.)_GetVar in "${(.)_GetVars[@]}"; do          # Iterate over GetVars and store the curl variable results
         printf -v "$(.)_InfoVar[$(.)_GetVar]" '%s' "$(
            printf '%s' "$(.)_HTTPResponse" |            # The response includes the formatted data
            grep "^$(.)_CodePrefix $(.)_GetVar: .*$(.)_CodeSuffix$" |
                                                         # Get the single line containing the formatted data
            sed "s|$(.)_CodePrefix $(.)_GetVar: \(.*\)$(.)_CodeSuffix|\1|"
                                                         # Extract the individual variable data result
         )"
      done
   fi

   #######################################
   # Return on curl Non-Zero Return Code #
   #######################################
   if (( $(.)_ReturnStatus != 0 )); then
      if ! $(.)_Quiet; then
         :error: "Bad return status code: $(.)_ReturnStatus"
      fi

      printf -v "$(.)_InfoVar[status]" '%s' 2
      return 2                                           # The curl variables may be valid in this case
   fi

   #########################################
   # Apply the jq JSON Filter if Requested #
   #########################################
   if [[ -n $(.)_Filter ]]; then
      local (.)_TmpFile="$(mktemp)"                      # Create a temporary file for the modified output

      __jq - "$(.)_Filter" "$(.)_Output" >"$(.)_TmpFile" || (.)_ReturnStatus=$?
      if (( $(.)_ReturnStatus != 0 )); then
         if ! $(.)_Quiet; then
            :error: "JSON filter $1 returned status code: $(.)_ReturnStatus"
         fi

         rm -f "$(.)_TmpFile"                            # Cleanup

         printf -v "$(.)_InfoVar[status]" '%s' "$(.)_ReturnStatus"
         return 3
      fi
                                                         # Perform the filter and return on failure
      mv "$(.)_TmpFile" "$(.)_Output"
   fi

   ##############################
   # Store data in the Body Var #
   ##############################
   if [[ $(.)_BodyVar != (.)_UnspecifiedBodyVar ]]; then
      [[ -v $(.)_BodyVar ]] || local -g $(.)_BodyVar     # Ensure the BodyVar variable is declared

      printf -v "$(.)_BodyVar" "%s" "$(cat "$(.)_Output")"
                                                         # Store the output in the provided variable
                                                         # NOTE: This should be done ONLY for text data, not binary

   elif $(.)_IsTmpOutput; then                           # If not saving to BodyVar and no output file is defined,
      cat "$(.)_Output"                                  # then just emit to stdout
   fi

   #################################
   # Store data in the Headers Var #
   #################################
   if [[ $(.)_HeadersVar != (.)_UnspecifiedHeadersVar ]]; then
      [[ -v $(.)_HeadersVar ]] || local -g $(.)_HeadersVar
                                                         # Ensure the HeadersVar variable is declared
      printf -v "$(.)_HeadersVar" "%s" "$(cat "$(.)_HeadersTmpFile")"
      rm -f "$(.)_HeadersTmpFile"
   fi

   ##################################
   # With --expect, Check http_code #
   ##################################
   if [[ -n $(.)_Expect ]]; then
      if [[ $(.)_Expect =~ ^[0-9]$ ]]; then              # If just a single digit, add pattern for 2 additional digits
         (.)_Expect+='[0-9][0-9]'
      fi

      local (.)_Indirect="$(.)_InfoVar[http_code]"       # Indirection to get the http_code
      if [[ ! ${!(.)_Indirect} =~ ^$(.)_Expect ]]; then
                                                         # Test the http_code expectation
         if ! $(.)_Quiet; then
            :error: "Bad HTTP status code: ${!(.)_Indirect}"
         fi

         printf -v "$(.)_InfoVar[status]" '%s' 4
         return 4                                        # Return an error on no match
      fi
   fi

   ######################
   # Cleanup and Return #
   ######################
   if $(.)_IsTmpOutput; then
      rm -f "$(.)_Output"                                # Clean up if the user is not saving the output explicitly
   fi

   printf -v "$(.)_InfoVar[status]" '%s' 0               # Success
   return 0
}

+ auth_tmpl()
{
   local (.)_Options
   (.)_Options=$(getopt -o r:s: -l "request:,shortcut:,basic:,oauth:" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Request=                                    # Specify the request type, default: GET
   local (.)_Shortcut=                                   # Specify a known shortcut to augment \(+)_Args
   local (.)_Basic=                                      # Specify basic authentication (username and password)
   local (.)_OAuth=                                      # Specify oauth authentication (username and password)

   while true ; do
      case "$1" in
      -r|--request)  (.)_Request="$2"                    # Specify the request type
                     shift 2;;
      -s|--shortcut) (.)_Shortcut="$2"                   # Specify a known shortcut
                     shift 2;;

      --basic)    (.)_Basic="$2"; shift 2;;              # <username>:<password>
      --oauth)    (.)_OAuth="$2"; shift 2;;              # <username>:<password>
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $(.)_Request ]]; then                        # Update args with request type
      (+)_Args+=( -X "$(.)_Request" )
   else
      (+)_Args+=( -X GET )
   fi

   if [[ -n $(.)_Shortcut ]]; then                       # Augment \(+)_Args with shortcut
      case "$(.)_Shortcut" in
      jsonenc) (+)_Args+=(
               -H 'Accept: application/json'
               -H 'Content-Type: application/x-www-form-urlencoded'
               )
               ;;
      *)       ;;
      esac
   fi

   # Basic authentication
   if [[ -n $(.)_Basic ]]; then
      (+)_Args+=('-u' "$(.)_Basic")                      # Add basic authentication args
   fi

   # OAuth authentication
   if [[ -n $(.)_OAuth ]]; then
      (+)_Args+=(                                        # Add OAuth authentication args
         -d "grant_type=password&username=${(.)_OAuth%%:*}"
         --data-urlencode "password=${(.)_OAuth#*:}"
      )
   fi
}
