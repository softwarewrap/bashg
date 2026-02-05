#!/bin/bash

::get_config_args%HELP()
{
   :help: --set 'Process --config arguments'  <<EOF
OPTIONS:
   --config <key=value>^
      Define the parameter <key> with the specified <value>

   --config <key>^
      Define the parameter <key> with the value <b>true</b>
EOF
}

::get_config_args()
{
   if ! command -v jq &>/dev/null; then
      echo 'Error: The command jq was not found'
      return 1
   fi
   if ! command -v yq &>/dev/null; then
      echo 'Error: The command yq was not found'
      return 1
   fi

   Config[Branch]='main'                                 # Associative array for storing configuration data

   local OptName OptArg StopRequest
   :getopts: begin -o '' -l 'config:' -- "$@"

   local Key Value                                       # Temporary for iterating
   while :getopts: next OptName OptArg StopRequest; do
      case "$OptName" in
      --config)
            if [[ $OptArg =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
               Key="$OptArg"
               Value=true
            elif [[ $OptArg =~ = ]]; then
               Key="${OptArg%%=*}"
               Value="${OptArg#*=}"
            else
               echo "Error: Unexpected --config argument: $OptArg"
               return 1
            fi

            Config[$Key]="$Value"
            ;;
      *)    break;;
      esac
   done

   local -ga Unused
   :getopts: end --save Unused                           # Save unused args
   set -- "${Unused[@]}"

   if [[ -n ${Config[Jenkins]} ]]; then                  # Set Jenkins-specific parameters
      # JenkinsInfo
      Config[JenkinsInfo]="$( curl --silent -u 'passuser:116778d95dafd7da0487642c526c8470bd' "$BUILD_URL/api/json" 2>/dev/null )"
                                                            # Get the job info
      if [[ -z $JobInfo ]]; then
         echo 'Could not get Jenkins job information'
         return 2
      fi
      echo "Reading Key='JenkinsInfo' and Value='${Config[JenkinsInfo]}'"

      # JenkinsUserID
      Config[JenkinsUserID]="$( sed 's|.*"userId":"\([^"]*\)".*|\1|' <<<"${Config[JenkinsInfo]}" )"

      if [[ -z $JobUserID ]]; then
         echo 'Error: Cannot determine the username'
         return 2
      fi

      # JenkinsUserFullName
      Config[JenkinsUserFullName]="$( sed 's|.*"userName":"\([^"]*\)".*|\1|' <<<"${Config[JenkinsInfo]}" )"
   fi

   :array:dump_associative Config '<h2>Configuration</h2>'
}
