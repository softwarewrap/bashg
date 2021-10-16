#!/bin/bash

:curl:%HELP()
{
   :help: --set 'Call curl with additional functionaltity' --usage '<options> [-- <curl-pass-thru-options> [<url>] ]' <<'EOF'
OPTIONS:
   --callback <callback-name>    ^Call <callback-name> that can add or modify curl(1) args before calling curl

   --info-var <info-var>>        ^Store metadata information in the indicated Bash associative <array>
   --body-var <body-var>         ^Store the result body in the indicated Bash <body-var>
   --get <curl-output-name>      ^Get metadata information for the indicated <curl-output-name>

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

   Notes:
      Quoting must be used when passing regex strings that include characters that might otherwise
      be interpreted immediately by the shell.

      The <info-var> variable should not be declared before use. It is automatically unset and then declared.
      The <body-var> variable may be declared in advance, but if it is not declared, it will automatically
      be declared.
      Both of the above variables are declared with global scope.

      If -- is present as an argument, then all arguments before it are parsed as :curl: arguments.
      Those that follow -- are passed directly to the underlying curl command.

CALLBACK VARIABLES:
   (++:curl)_Args               ^The options to pass to curl that can be modified by callbacks

RETURN STATUS:
   0  ^Success
   1  ^Error with the invocation of :curl:
   2  ^The native curl returned non-zero and is stored in the <info-var>> <b>status</b> element.
   3  ^JSON <filter> returned non-zero and is stored in the <info-var>> <b>status</b> element.
   4  ^The <http-expect> test returned non-zero: consult the <info-var>> <b>http_code</b> element.

EXAMPLE:
   local -a Options=(            ^^>GThe first block of args are consumed by :curl:
      --info-var  Info           ^Use the Info variable to store metadata information
      --body-var  Body           ^Store the response body in the Body variable
      --get       http_code      ^Get the response HTTP code
      --get       url_effective  ^Get the effective URL, if present
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

   local __curl________Option                                      # Iterate over options
   local __curl________Value                                       # For options that take args, store in this variable

   local -a __curl________CallbackVars=()                          # Callback to modify (+)_Args

   local __curl________InfoVar="__curl________UnspecifiedInfoVar"            # Use this variable name if none is specified by --info-var
   local -a __curl________GetVars=()                               # Get curl variables. See curl(1): --write-out

   local __curl________BodyVar="__curl________UnspecifiedBodyVar"            # Store the result body in this variable
   local __curl________Filter=                                     # Apply the JSON jq filter to the result body

   local __curl________Timeout=                                    # Terminate the curr command after the given duration
   local __curl________Debug=false                                 # Write the curl command to stdout prior to execution
   local __curl________Quiet=false                                 # Emit error messages

   local __curl________Scheme=                                     # Either http or https
   local __curl________Host=                                       # Host or IP address
   local __curl________Port=                                       # Port number
   local __curl________ResourcePath=                               # The resource path follows the host and port
   local __curl________Url=                                        # A fully-formed alternative to the above 4 variables

   local __curl________Output=                                     # Store the result body to a file
   local __curl________IsTmpOutput=false

   local __curl________Expect=

   local -ag __curl___Args=()                                 # These are the arguments that are passed to curl(1)

   while :getopts: next __curl________Option __curl________Value; do
      case "$__curl________Option" in
      --callback)    __curl________CallbackVars+=( "$__curl________Value" );;

      --info-var)    __curl________InfoVar="$__curl________Value";;          # Store metdata information in this variable
      --get)         __curl________GetVars+=( "$__curl________Value" );;     # Get curl variables

      --body-var)    __curl________BodyVar="$__curl________Value";;          # Store the result body in this variable
      --filter)      __curl________Filter="$__curl________Value";;           # Apply the JSON jq filter to the result body

      --timeout)     __curl________Timeout="$__curl________Value";;          # Terminate the curl command after specified duration
      --debug)       __curl________Debug=true;;                    # Enable debug output
      --quiet)       __curl________Quiet=true;;                    # Do not emit error messages

      -s|--scheme)   __curl________Scheme="$__curl________Value";;           # http or https
      -h|--host)     __curl________Host="$__curl________Value";;             # FQDN
      -p|--port)     __curl________Port="$__curl________Value";;             # Numeric port
      -r|--resource) __curl________ResourcePath="$__curl________Value";;     # Resource path following the above 3 entries
      -u|--url)      __curl________Url="$__curl________Value";;              # Alternative to the above 4: full URL or local path

      -o|--output)   __curl________Output="$__curl________Value";;           # Write response body to the indicated file

      -e|--expect)   __curl________Expect="${__curl________Value/^}";;       # Specify an http_code expect regex string; strip anchor

      *)          break;;
      esac
   done

   :getopts: end --save __curl___Args --append                # Save unused args as args to be used by curl

   unset "$__curl________InfoVar"                                  # Clear the associative array before running curl
   local -Ag "$__curl________InfoVar"                              # Now, the declaration contains no elements

   local __curl________ReturnStatus=0                              # Presume success

   if [[ -z $__curl________Output ]]; then                         # If no explicit output file is specified,
      __curl________Output="$(mktemp)"                             # then create a temporary file for the output
      __curl________IsTmpOutput=true                               # and mark this as temporary
   fi
   __curl___Args+=( -o "$__curl________Output" )                        # Save response body to the specified file

   ##########################################################################################
   # Construct URL; See: Scheme definition: https://tools.ietf.org/html/rfc3986#section-3.1 #
   ##########################################################################################
   if [[ -n $__curl________Url ]]; then                            # Check if a URL is explicitly specified
      if [[ ( $__curl________Url =~ ^[/.] ) &&                     # If start is absolute or relative path and not a scheme
            ! $__curl________Url =~ ^[a-zA-Z][a-zA-Z0-9.+-]*'://' ]]; then

         if [[ ! -f  $__curl________Url ]]; then
            if ! $__curl________Quiet; then
               :error: "No such file: $__curl________Url"       # If file doesn't exist and not quiet, emit message
            fi

            printf -v "$__curl________InfoVar[status]" '%s' 1
            return 1
         fi

         __curl________Url="file://$(readlink -fm "$__curl________Url")"     # Normalize the URL with the file:// scheme
      fi

   elif [[ -n $__curl________Scheme && -n $__curl________Host ]]; then       # Scheme and Host are required
      __curl________Url="$__curl________Scheme://$__curl________Host"                  # Begin constructing the URL with scheme and host

      if [[ -n $__curl________Port ]]; then
         __curl________Url+=":$__curl________Port"                           # Add a port if one is provided
      fi

      if [[ -n $__curl________ResourcePath ]]; then                # If a resource path is specified, then use it
         __curl________Url+="/${__curl________ResourcePath#/}"               # Append the resource path, stripping any leading /
      fi

   else
      if ! $__curl________Quiet; then
         :error: 'Either <scheme> and <host> or <path> must be specified'
      fi

      printf -v "$__curl________InfoVar[status]" '%s' 1
      return 1
   fi

   __curl___Args+=( "$__curl________Url" )                              # Add the URL to the curl args

   #################################################
   # Run Provided Callbacks that Modify (+)_Args   #
   #################################################
   if ((${#__curl________CallbackVars[@]} > 0)); then
      local __curl________CallbackVar                              # Iterate over CallbackVars

      for __curl________CallbackVar in "${__curl________CallbackVars[@]}"; do
         local __curl________IndirectCallbackVar="$__curl________CallbackVar[@]"
                                                         # Create the array indirection pattern: command and args
         set -- "${!__curl________IndirectCallbackVar}"            # Set positional parameters to the command and args

         if :test:has_func "$1"; then                    # If $1 is a known function,
            "$@" || __curl________ReturnStatus=$?                  # ... then execute the function along with the args
            if (( $__curl________ReturnStatus != 0 )); then
               if ! $__curl________Quiet; then
                  :error: "Curl callback $1 returned status code: $__curl________ReturnStatus"
               fi

               printf -v "$__curl________InfoVar[status]" '%s' 1
               return 1
            fi
         fi
      done
   fi

   ############################################
   # Construct Curl Variable Format Arguments #
   ############################################
   local __curl________CodePrefix=$'\x08\x14\x14\x10{'             # A unique prefix: Control 'HTTP' + {
   local __curl________CodeSuffix=$'}\x08\x14\x14\x10'             # A unique suffix: } + Control 'HTTP'

      # Create the option for curl variable names
   if [[ ${#__curl________GetVars[@]} -gt 0 ]]; then               # If requesting curl variable data
      local __curl________Format=                                  # Start with empty string for the format
      local __curl________GetVar                                   # Iterator for __curl________GetVars

      if [[ -n $__curl________Expect &&                            # Ensure that http_code is present if --expect is used
            ( ! " ${__curl________GetVars[@]} " =~ ' http_code ' ) ]]; then
         __curl________GetVars+=( 'http_code' )
      fi

      :array:sort --var __curl________GetVars --unique             # Ensure only unique curl vars are requested

      for __curl________GetVar in "${__curl________GetVars[@]}"; do
         __curl________Format+="\n$__curl________CodePrefix $__curl________GetVar: %{$__curl________GetVar}$__curl________CodeSuffix"
                                                         # Construct a parseable format for the GetVar
      done
      __curl________Format+="\n"                                   # The format is now bounded by newlines

      __curl___Args+=( '-w' "$__curl________Format" )                   # Add the block of formats to curl
   fi

   ###################################
   ### RUN THE NATIVE CURL COMMAND ###
   ###################################
   if $__curl________Debug; then
      echo "=================================================="
      echo "curl ${__curl___Args[@]}"
      echo "=================================================="
   fi

   local __curl________HTTPResponse                                # Store the HTTP response (not response headers)

   __curl________HTTPResponse="$(
      if [[ -n $__curl________Timeout ]]; then                     # Apply a timeout if requested
         local __curl________Kill="$(($__curl________Timeout + $__curl________Timeout / 10))"
                                                         # Kill time = timeout time + 10%
         ### RUN CURL WITH TIMEOUT
         timeout -k "${__curl________Kill}s" -s KILL "${__curl________Timeout}s" curl "${__curl___Args[@]}"

      else
         ### RUN CURL
         curl "${__curl___Args[@]}"
      fi
   )" || __curl________ReturnStatus=$?

   ##################################
   # Get Curl Variable Data Results #
   ##################################
   printf -v "$__curl________InfoVar[status]" '%s' "$__curl________ReturnStatus"

   if (( ${#__curl________GetVars[@]} > 0 )); then
      for __curl________GetVar in "${__curl________GetVars[@]}"; do          # Iterate over GetVars and store the curl variable results
         printf -v "$__curl________InfoVar[$__curl________GetVar]" '%s' "$(
            printf '%s' "$__curl________HTTPResponse" |            # The response includes the formatted data
            grep "^$__curl________CodePrefix $__curl________GetVar: .*$__curl________CodeSuffix$" |
                                                         # Get the single line containing the formatted data
            sed "s|$__curl________CodePrefix $__curl________GetVar: \(.*\)$__curl________CodeSuffix|\1|"
                                                         # Extract the individual variable data result
         )"
      done
   fi

   #######################################
   # Return on curl Non-Zero Return Code #
   #######################################
   if (( $__curl________ReturnStatus != 0 )); then
      if ! $__curl________Quiet; then
         :error: "Bad return status code: $__curl________ReturnStatus"
      fi

      printf -v "$__curl________InfoVar[status]" '%s' 2
      return 2                                           # The curl variables may be valid in this case
   fi

   #########################################
   # Apply the jq JSON Filter if Requested #
   #########################################
   if [[ -n $__curl________Filter ]]; then
      local __curl________TmpFile="$(mktemp)"                      # Create a temporary file for the modified output

      __jq - "$__curl________Filter" "$__curl________Output" >"$__curl________TmpFile" || __curl________ReturnStatus=$?
      if (( $__curl________ReturnStatus != 0 )); then
         if ! $__curl________Quiet; then
            :error: "JSON filter $1 returned status code: $__curl________ReturnStatus"
         fi

         rm -f "$__curl________TmpFile"                            # Cleanup

         printf -v "$__curl________InfoVar[status]" '%s' "$__curl________ReturnStatus"
         return 3
      fi
                                                         # Perform the filter and return on failure
      mv "$__curl________TmpFile" "$__curl________Output"
   fi

   ##############################
   # Store data in the Body Var #
   ##############################
   if [[ $__curl________BodyVar != __curl________UnspecifiedBodyVar ]]; then
      [[ -v $__curl________BodyVar ]] || local -g $__curl________BodyVar     # Ensure the BodyVar variable is declared

      printf -v "$__curl________BodyVar" "%s" "$(cat "$__curl________Output")"
                                                         # Store the output in the provided variable
                                                         # NOTE: This should be done ONLY for text data, not binary

   elif $__curl________IsTmpOutput; then                           # If not saving to BodyVar and no output file is defined,
      cat "$__curl________Output"                                  # then just emit to stdout
   fi

   ##################################
   # With --expect, Check http_code #
   ##################################
   if [[ -n $__curl________Expect ]]; then
      if [[ $__curl________Expect =~ ^[0-9]$ ]]; then              # If just a single digit, add pattern for 2 additional digits
         __curl________Expect+='[0-9][0-9]'
      fi

      local __curl________Indirect="$__curl________InfoVar[http_code]"       # Indirection to get the http_code
      if [[ ! ${!__curl________Indirect} =~ ^$__curl________Expect ]]; then
                                                         # Test the http_code expectation
         if ! $__curl________Quiet; then
            :error: "Bad HTTP status code: ${!__curl________Indirect}"
         fi

         printf -v "$__curl________InfoVar[status]" '%s' 4
         return 4                                        # Return an error on no match
      fi
   fi

   ######################
   # Cleanup and Return #
   ######################
   if $__curl________IsTmpOutput; then
      rm -f "$__curl________Output"                                # Clean up if the user is not saving the output explicitly
   fi

   printf -v "$__curl________InfoVar[status]" '%s' 0               # Success
   return 0
}

:curl:auth_tmpl()
{
   local __curl_____auth_tmpl___Options
   __curl_____auth_tmpl___Options=$(getopt -o r:s: -l "request:,shortcut:,basic:,oauth:" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__curl_____auth_tmpl___Options"

   local __curl_____auth_tmpl___Request=                                    # Specify the request type, default: GET
   local __curl_____auth_tmpl___Shortcut=                                   # Specify a known shortcut to augment (+)_Args
   local __curl_____auth_tmpl___Basic=                                      # Specify basic authentication (username and password)
   local __curl_____auth_tmpl___OAuth=                                      # Specify oauth authentication (username and password)

   while true ; do
      case "$1" in
      -r|--request)  __curl_____auth_tmpl___Request="$2"                    # Specify the request type
                     shift 2;;
      -s|--shortcut) __curl_____auth_tmpl___Shortcut="$2"                   # Specify a known shortcut
                     shift 2;;

      --basic)    __curl_____auth_tmpl___Basic="$2"; shift 2;;              # <username>:<password>
      --oauth)    __curl_____auth_tmpl___OAuth="$2"; shift 2;;              # <username>:<password>
      --)         shift; break;;
      *)          break;;
      esac
   done

   if [[ -n $__curl_____auth_tmpl___Request ]]; then                        # Update args with request type
      __curl___Args+=( -X "$__curl_____auth_tmpl___Request" )
   else
      __curl___Args+=( -X GET )
   fi

   if [[ -n $__curl_____auth_tmpl___Shortcut ]]; then                       # Augment (+)_Args with shortcut
      case "$__curl_____auth_tmpl___Shortcut" in
      jsonenc) __curl___Args+=(
               -H 'Accept: application/json'
               -H 'Content-Type: application/x-www-form-urlencoded'
               )
               ;;
      *)       ;;
      esac
   fi

   # Basic authentication
   if [[ -n $__curl_____auth_tmpl___Basic ]]; then
      __curl___Args+=('-u' "$__curl_____auth_tmpl___Basic")                      # Add basic authentication args
   fi

   # OAuth authentication
   if [[ -n $__curl_____auth_tmpl___OAuth ]]; then
      __curl___Args+=(                                        # Add OAuth authentication args
         -d "grant_type=password&username=${__curl_____auth_tmpl___OAuth%%:*}"
         --data-urlencode "password=${__curl_____auth_tmpl___OAuth#*:}"
      )
   fi
}

:curl:tenant_token_auth_tmpl()
{
   local __curl_____tenant_token_auth_tmpl___Options
   __curl_____tenant_token_auth_tmpl___Options=$(getopt -o '' -l "tenant-id:,credentials:" -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__curl_____tenant_token_auth_tmpl___Options"

   local __curl_____tenant_token_auth_tmpl___TenantID=                                   # The tenant ID
   local __curl_____tenant_token_auth_tmpl___Credentials=                                # Pre-constructed credentials

   while true ; do
      case "$1" in
      --tenant-id)   __curl_____tenant_token_auth_tmpl___TenantID="$2"; shift 2;;
      --credentials) __curl_____tenant_token_auth_tmpl___Credentials="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   [[ -n $__curl_____tenant_token_auth_tmpl___TenantID && -n $__curl_____tenant_token_auth_tmpl___Credentials ]] || return

   __curl___Args+=(
      '-H' 'Accept: application/json'
      '-H' 'Content-Type: application/x-www-form-urlencoded'
      '-H' "X-Identity-Zone-Id: $__curl_____tenant_token_auth_tmpl___TenantID"
      '-H' "Authorization: bearer $__curl_____tenant_token_auth_tmpl___Credentials"
      '-d' 'grant_type=client_credentials'
   )
}
