#!/bin/bash

:curl:%HELP()
{
   :help: --set 'Call curl with additional functionaltity' --usage '<options> [-- <curl-pass-thru-options> [<url>] ]' <<'EOF'
OPTIONS:
   --callback <callback-name>    ^Call <callback-name> that can add or modify curl(1) args before calling curl

   --info-var <info-array>       ^Store metadata information in the indicated Bash associative <array>
   --get <curl-variable-name>    ^Get metadata information for the indicated <curl-variable-name>

   --body-var <variable>         ^Store the result body in the indicated Bash <variable>
   --filter <filter>             ^Apply JSON <filter> to result body

   --timeout <duration>          ^Terminate the curl command if it is still running after <duration> seconds
   --debug                       ^Write command to stdout prior to execution
   --quiet                       ^Do not emit error messages

   -s|--scheme <scheme>          ^HTTP scheme: one of http or https only
   -h|--host <host>              ^Host or IP address
   -p|--port <port>              ^Port number
   -r|--resource <path>          ^URL resource path that identifies the specific resource on the host to access
   -u|--url <path>               ^A full URL or local filesystem path as an alternative to the above 4 options

   -o|--output <file>            ^Store the result body to <file>

   -e|--expect <http-expect>     ^Expect the http_code matching the given regex


DESCRIPTION:
   Wrapper for curl(1) that provides convenience functionality including curl variable extraction,
   callbacks for authentication and custom needs, JSON parsing, timeouts, and more.

   If --path is specified, then the path can be either a URL that includes <scheme> and <host>
   and optionally includes <port> and <context>, or it can be a filesystem path that is either
   relative or absolute.

   If --body-var is specified, then it must be the case that the result body must be non-binary data.
   That is, Bash variables do not support storing NULL (hex 00) character strings.

   If --expect is specified, then the http_code variable must match the anchored <http-expect> regex.
   If the <http-expect> code is a single digit, then [0-9][0-9] is automatically appended.
   For example, <B>--expect 2</B> is equivalent to <B>--expect '2[0-9][0-9]'</B>.

   Note: Quoting must be used when passing regex strings that include characters that might otherwise
   be interpreted immediately by the shell.

CALLBACK VARIABLES:
   (++:curl)_Args               ^The options to pass to curl that can be modified by callbacks

RETURN STATUS:
   0  ^Success
   1  ^Error with the invocation of :curl:
   2  ^The native curl returned non-zero and is stored in the <info-array> <b>status</b> element.
   3  ^JSON <filter> returned non-zero and is stored in the <info-array> <b>status</b> element.
   4  ^The <http-expect> test returned non-zero: consult the <info-array> <b>http_code</b> element.

EXAMPLE:
   local -A Info                 ^Store metadata information

   local Options=(               ^^>GThe first block of args are consumed by :curl:
      --info-var  Info           ^Use the Info variable to store metadata information
      --get       http_code      ^Get the response HTTP code
      --get       url_effective  ^Get the effective URL, if present
      --body-var  Body           ^Store the response body in the Body variable
      --                         ^^>GThe second block of args are consumed directly by curl(1)
      -s -k                      ^Additional arguments
   )^
   :curl: --url 'https://some/path' "${Options[@]}" -L^
                                 ^Get metadata info needed for second :curl: call

   if [[ -n ${Info[url_effective]} ]]; then^
      MY_Redirect="$(MY_get_redirect "${Info[url_effective]}")"^
                                 ^Modify the effective URL
      local -a Callback=( :curl:auth_tmpl --basic "admin:mypassword" )^
                                 Array contains function call parameters that inject into
                                 options processed by :curl:
      :curl: --url "$MY_Redirect" --callback Callback "${Options[@]}"^
                                 ^Add authentication to this :curl: call

      if [[ ${Info[http_code]} =~ ^2[0-9][0-9]$ ]]; then^
         echo 'Success'^
      else^
         echo 'Fail'^
      else^
   fi^
EOF
}

:curl:()
{
   :getopts: begin \
      -o ':s:h:p:r:u:o:e:' \
      -l 'callback:,info-var:,get:,body-var:,filter:,timeout:,debug,quiet,scheme:,host:,port:,resource:,url:,output:,expect:' \
      -- "$@"

   local ___curl________Option                                      # Iterate over options
   local ___curl________Value                                       # For options that take args, store in this variable

   local -a ___curl________CallbackVars=()                          # Callback to modify (+)_Args

   local ___curl________InfoVar="___curl________UnspecifiedInfoVar"            # Use this variable name if none is specified by --info-var
   local -a ___curl________GetVars=()                               # Get curl variables. See curl(1): --write-out

   local ___curl________BodyVar="___curl________UnspecifiedBodyVar"            # Store the result body in this variable
   local ___curl________Filter=                                     # Apply the JSON jq filter to the result body

   local ___curl________Timeout=                                    # Terminate the curr command after the given duration
   local ___curl________Debug=false                                 # Write the curl command to stdout prior to execution
   local ___curl________Quiet=false                                 # Emit error messages

   local ___curl________Scheme=                                     # Either http or https
   local ___curl________Host=                                       # Host or IP address
   local ___curl________Port=                                       # Port number
   local ___curl________ResourcePath=                               # The resource path follows the host and port
   local ___curl________Url=                                        # A fully-formed alternative to the above 4 variables

   local ___curl________Output=                                     # Store the result body to a file
   local ___curl________IsTmpOutput=false

   local ___curl________Expect=

   local -ag ___curl___Args=()                                 # These are the arguments that are passed to curl(1)

   while :getopts: next ___curl________Option ___curl________Value; do
      case "$___curl________Option" in
      --callback)    ___curl________CallbackVars+=( "$___curl________Value" );;

      --info-var)    ___curl________InfoVar="$___curl________Value";;          # Store metdata information in this variable
      --get)         ___curl________GetVars+=( "$___curl________Value" );;     # Get curl variables

      --body-var)    ___curl________BodyVar="$___curl________Value";;          # Store the result body in this variable
      --filter)      ___curl________Filter="$___curl________Value";;           # Apply the JSON jq filter to the result body

      --timeout)     ___curl________Timeout="$___curl________Value";;          # Terminate the curl command after specified duration
      --debug)       ___curl________Debug=true;;                    # Enable debug output
      --quiet)       ___curl________Quiet=true;;                    # Do not emit error messages

      -s|--scheme)   ___curl________Scheme="$___curl________Value";;           # http or https
      -h|--host)     ___curl________Host="$___curl________Value";;             # FQDN
      -p|--port)     ___curl________Port="$___curl________Value";;             # Numeric port
      -r|--resource) ___curl________ResourcePath="$___curl________Value";;     # Resource path following the above 3 entries
      -u|--url)      ___curl________Url="$___curl________Value";;              # Alternative to the above 4: full URL or local path

      -o|--output)   ___curl________Output="$___curl________Value";;           # Write response body to the indicated file

      -e|--expect)   ___curl________Expect="${___curl________Value/^}";;       # Specify an http_code expect regex string; strip anchor

      *)          break;;
      esac
   done

   :getopts: end --save ___curl___Args --append                # Save unused args as args to be used by curl

   unset "$___curl________InfoVar"                                  # Clear the associative array before running curl
   local -Ag "$___curl________InfoVar"                              # Now, the declaration contains no elements

   local ___curl________ReturnStatus=0                              # Presume success

   if [[ -z $___curl________Output ]]; then                         # If no explicit output file is specified,
      ___curl________Output="$(mktemp)"                             # then create a temporary file for the output
      ___curl________IsTmpOutput=true                               # and mark this as temporary
   fi
   ___curl___Args+=( -o "$___curl________Output" )                        # Save response body to the specified file

   ##########################################################################################
   # Construct URL; See: Scheme definition: https://tools.ietf.org/html/rfc3986#section-3.1 #
   ##########################################################################################
   if [[ -n $___curl________Url ]]; then                            # Check if a URL is explicitly specified
      if [[ ( $___curl________Url =~ ^[/.] ) &&                     # If start is absolute or relative path and not a scheme
            ! $___curl________Url =~ ^[a-zA-Z][a-zA-Z0-9.+-]*'://' ]]; then

         if [[ ! -f  $___curl________Url ]]; then
            if ! $___curl________Quiet; then
               :error: "No such file: $___curl________Url"       # If file doesn't exist and not quiet, emit message
            fi

            printf -v "$___curl________InfoVar[status]" '%s' 1
            return 1
         fi

         ___curl________Url="file://$(readlink -fm "$___curl________Url")"     # Normalize the URL with the file:// scheme
      fi

   elif [[ -n $___curl________Scheme && -n $___curl________Host ]]; then       # Scheme and Host are required
      ___curl________Url="$___curl________Scheme://$___curl________Host"                  # Begin constructing the URL with scheme and host

      if [[ -n $___curl________Port ]]; then
         ___curl________Url+=":$___curl________Port"                           # Add a port if one is provided
      fi

      if [[ -n $___curl________ResourcePath ]]; then                # If a resource path is specified, then use it
         ___curl________Url+="/${___curl________ResourcePath#/}"               # Append the resource path, stripping any leading /
      fi

   else
      if ! $___curl________Quiet; then
         :error: 'Either <scheme> and <host> or <path> must be specified'
      fi

      printf -v "$___curl________InfoVar[status]" '%s' 1
      return 1
   fi

   ___curl___Args+=( "$___curl________Url" )                              # Add the URL to the curl args

   #################################################
   # Run Provided Callbacks that Modify (+)_Args   #
   #################################################
   if ((${#___curl________CallbackVars[@]} > 0)); then
      local ___curl________CallbackVar                              # Iterate over CallbackVars

      for ___curl________CallbackVar in "${___curl________CallbackVars[@]}"; do
         local ___curl________IndirectCallbackVar="$___curl________CallbackVar[@]"
                                                         # Create the array indirection pattern: command and args
         set -- "${!___curl________IndirectCallbackVar}"            # Set positional parameters to the command and args

         if :test:has_func "$1"; then                    # If $1 is a known function,
            "$@" || ___curl________ReturnStatus=$?                  # ... then execute the function along with the args
            if (( $___curl________ReturnStatus != 0 )); then
               if ! $___curl________Quiet; then
                  :error: "Curl callback $1 returned status code: $___curl________ReturnStatus"
               fi

               printf -v "$___curl________InfoVar[status]" '%s' 1
               return 1
            fi
         fi
      done
   fi

   ############################################
   # Construct Curl Variable Format Arguments #
   ############################################
   local ___curl________CodePrefix=$'\x08\x14\x14\x10{'             # A unique prefix: Control 'HTTP' + {
   local ___curl________CodeSuffix=$'}\x08\x14\x14\x10'             # A unique suffix: } + Control 'HTTP'

      # Create the option for curl variable names
   if [[ ${#___curl________GetVars[@]} -gt 0 ]]; then               # If requesting curl variable data
      local ___curl________Format=                                  # Start with empty string for the format
      local ___curl________GetVar                                   # Iterator for ___curl________GetVars

      if [[ -n $___curl________Expect &&                            # Ensure that http_code is present if --expect is used
            ( ! " ${___curl________GetVars[@]} " =~ ' http_code ' ) ]]; then
         ___curl________GetVars+=( 'http_code' )
      fi

      :array:sort --var ___curl________GetVars --unique             # Ensure only unique curl vars are requested

      for ___curl________GetVar in "${___curl________GetVars[@]}"; do
         ___curl________Format+="\n$___curl________CodePrefix $___curl________GetVar: %{$___curl________GetVar}$___curl________CodeSuffix"
                                                         # Construct a parseable format for the GetVar
      done
      ___curl________Format+="\n"                                   # The format is now bounded by newlines

      ___curl___Args+=( '-w' "$___curl________Format" )                   # Add the block of formats to curl
   fi

   ###################################
   ### RUN THE NATIVE CURL COMMAND ###
   ###################################
   if $___curl________Debug; then
      echo "=================================================="
      echo "curl ${___curl___Args[@]}"
      echo "=================================================="
   fi

   local ___curl________HTTPResponse                                # Store the HTTP response (not response headers)

   ___curl________HTTPResponse="$(
      if [[ -n $___curl________Timeout ]]; then                     # Apply a timeout if requested
         local ___curl________Kill="$(($___curl________Timeout + $___curl________Timeout / 10))"
                                                         # Kill time = timeout time + 10%
         ### RUN CURL WITH TIMEOUT
         timeout -k "${___curl________Kill}s" -s KILL "${___curl________Timeout}s" curl "${___curl___Args[@]}"

      else
         ### RUN CURL
         curl "${___curl___Args[@]}"
      fi
   )" || ___curl________ReturnStatus=$?

   ##################################
   # Get Curl Variable Data Results #
   ##################################
   printf -v "$___curl________InfoVar[status]" '%s' "$___curl________ReturnStatus"

   if (( ${#___curl________GetVars[@]} > 0 )); then
      for ___curl________GetVar in "${___curl________GetVars[@]}"; do          # Iterate over GetVars and store the curl variable results
         printf -v "$___curl________InfoVar[$___curl________GetVar]" '%s' "$(
            printf '%s' "$___curl________HTTPResponse" |            # The response includes the formatted data
            grep "^$___curl________CodePrefix $___curl________GetVar: .*$___curl________CodeSuffix$" |
                                                         # Get the single line containing the formatted data
            sed "s|$___curl________CodePrefix $___curl________GetVar: \(.*\)$___curl________CodeSuffix|\1|"
                                                         # Extract the individual variable data result
         )"
      done
   fi

   #######################################
   # Return on curl Non-Zero Return Code #
   #######################################
   if (( $___curl________ReturnStatus != 0 )); then
      if ! $___curl________Quiet; then
         :error: "Bad return status code: $___curl________ReturnStatus"
      fi

      printf -v "$___curl________InfoVar[status]" '%s' 2
      return 2                                           # The curl variables may be valid in this case
   fi

   #########################################
   # Apply the jq JSON Filter if Requested #
   #########################################
   if [[ -n $___curl________Filter ]]; then
      local ___curl________TmpFile="$(mktemp)"                      # Create a temporary file for the modified output

      __jq - "$___curl________Filter" "$___curl________Output" >"$___curl________TmpFile" || ___curl________ReturnStatus=$?
      if (( $___curl________ReturnStatus != 0 )); then
         if ! $___curl________Quiet; then
            :error: "JSON filter $1 returned status code: $___curl________ReturnStatus"
         fi

         rm -f "$___curl________TmpFile"                            # Cleanup

         printf -v "$___curl________InfoVar[status]" '%s' "$___curl________ReturnStatus"
         return 3
      fi
                                                         # Perform the filter and return on failure
      mv "$___curl________TmpFile" "$___curl________Output"
   fi

   ##############################
   # Store data in the Body Var #
   ##############################
   if [[ $___curl________BodyVar != ___curl________UnspecifiedBodyVar ]]; then
      [[ -v $___curl________BodyVar ]] || local -g $___curl________BodyVar     # Ensure the BodyVar variable is declared

      printf -v "$___curl________BodyVar" "%s" "$(cat "$___curl________Output")"
                                                         # Store the output in the provided variable
                                                         # NOTE: This should be done ONLY for text data, not binary

   elif $___curl________IsTmpOutput; then                           # If not saving to BodyVar and no output file is defined,
      cat "$___curl________Output"                                  # then just emit to stdout
   fi

   ##################################
   # With --expect, Check http_code #
   ##################################
   if [[ -n $___curl________Expect ]]; then
      if [[ $___curl________Expect =~ ^[0-9]$ ]]; then              # If just a single digit, add pattern for 2 additional digits
         ___curl________Expect+='[0-9][0-9]'
      fi

      local ___curl________Indirect="$___curl________InfoVar[http_code]"       # Indirection to get the http_code
      if [[ ! ${!___curl________Indirect} =~ ^$___curl________Expect ]]; then
                                                         # Test the http_code expectation
         if ! $___curl________Quiet; then
            :error: "Bad HTTP status code: ${!___curl________Indirect}"
         fi

         printf -v "$___curl________InfoVar[status]" '%s' 4
         return 4                                        # Return an error on no match
      fi
   fi

   ######################
   # Cleanup and Return #
   ######################
   if $___curl________IsTmpOutput; then
      rm -f "$___curl________Output"                                # Clean up if the user is not saving the output explicitly
   fi

   printf -v "$___curl________InfoVar[status]" '%s' 0               # Success
   return 0
}

:curl:auth_tmpl()
{
   local ___curl_____auth_tmpl___Options
   ___curl_____auth_tmpl___Options=$(getopt -o r:s: -l "request:,shortcut:,basic:,oauth:" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___curl_____auth_tmpl___Options"

   local ___curl_____auth_tmpl___Request=                                    # Specify the request type, default: GET
   local ___curl_____auth_tmpl___Shortcut=                                   # Specify a known shortcut to augment (+)_Args
   local ___curl_____auth_tmpl___Basic=                                      # Specify basic authentication (username and password)
   local ___curl_____auth_tmpl___OAuth=                                      # Specify oauth authentication (username and password)

   while true ; do
      case "$1" in
      -r|--request)  ___curl_____auth_tmpl___Request="$2"                    # Specify the request type
                     shift 2;;
      -s|--shortcut) ___curl_____auth_tmpl___Shortcut="$2"                   # Specify a known shortcut
                     shift 2;;

      --basic)    ___curl_____auth_tmpl___Basic="$2"; shift 2;;              # <username>:<password>
      --oauth)    ___curl_____auth_tmpl___OAuth="$2"; shift 2;;              # <username>:<password>
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $___curl_____auth_tmpl___Request ]]; then                        # Update args with request type
      ___curl___Args+=( -X "$___curl_____auth_tmpl___Request" )
   else
      ___curl___Args+=( -X GET )
   fi

   if [[ -n $___curl_____auth_tmpl___Shortcut ]]; then                       # Augment (+)_Args with shortcut
      case "$___curl_____auth_tmpl___Shortcut" in
      jsonenc) ___curl___Args+=(
               -H 'Accept: application/json'
               -H 'Content-Type: application/x-www-form-urlencoded'
               )
               ;;
      *)       ;;
      esac
   fi

   # Basic authentication
   if [[ -n $___curl_____auth_tmpl___Basic ]]; then
      ___curl___Args+=('-u' "$___curl_____auth_tmpl___Basic")                      # Add basic authentication args
   fi

   # OAuth authentication
   if [[ -n $___curl_____auth_tmpl___OAuth ]]; then
      ___curl___Args+=(                                        # Add OAuth authentication args
         -d "grant_type=password&username=${___curl_____auth_tmpl___OAuth%%:*}"
         --data-urlencode "password=${___curl_____auth_tmpl___OAuth#*:}"
      )
   fi
}

:curl:tenant_token_auth_tmpl()
{
   local ___curl_____tenant_token_auth_tmpl___Options
   ___curl_____tenant_token_auth_tmpl___Options=$(getopt -o '' -l "tenant-id:,credentials:" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___curl_____tenant_token_auth_tmpl___Options"

   local ___curl_____tenant_token_auth_tmpl___TenantID=                                   # The tenant ID
   local ___curl_____tenant_token_auth_tmpl___Credentials=                                # Pre-constructed credentials

   while true ; do
      case "$1" in
      --tenant-id)   ___curl_____tenant_token_auth_tmpl___TenantID="$2"; shift 2;;
      --credentials) ___curl_____tenant_token_auth_tmpl___Credentials="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   [[ -n $___curl_____tenant_token_auth_tmpl___TenantID && -n $___curl_____tenant_token_auth_tmpl___Credentials ]] || return

   ___curl___Args+=(
      '-H' 'Accept: application/json'
      '-H' 'Content-Type: application/x-www-form-urlencoded'
      '-H' "X-Identity-Zone-Id: $___curl_____tenant_token_auth_tmpl___TenantID"
      '-H' "Authorization: bearer $___curl_____tenant_token_auth_tmpl___Credentials"
      '-d' 'grant_type=client_credentials'
   )
}
