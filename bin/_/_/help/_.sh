#!/bin/bash

:help:%HELP()
{
   local ___help_____HELP___Synopsis='Provide help on available functions'
   :help: --set "$___help_____HELP___Synopsis" --usage '[OPTIONS] [<search>]' <<EOF
OPTIONS:
   -l|--list            ^List functions matching <search> if provided, sorted by directory
   -L|--list-all        ^Shorthand for --list --all

   --public             ^When listing, include public functions only [default]
   --private            ^When listing, include private functions only
   --both               ^When listing, include both public and private functions

   --meta               ^When listing, include functions with a %<meta> suffix
   --all                ^When listing, include all of public, private, and meta functions

   <search>             ^Search for help on functions matching the <search> pattern

SCRIPTING OPTIONS:
   --set <synopsis>     ^Define the synopsis: a one-line summary for the function whose help is being defined
   --get <synopsis-var> ^Get the synopsis and place the string into the indicated variable
   --synopsis           ^Get the synopsis only and emit to stdout (only to be used within %HELP functions)
   --usage <usage>      ^Use the provided <usage> string instead of the standard string for headings

DESCRIPTION:
   The help command is use to obtain helpful information on the Bash library APIs.

   The following help can be obtained:

      - List available functions, along with synopsis information for each function
      - Search for functions
      - Provide help for a specific function
      - Provide only the synopsis for a specific function

   The --list option is used to list the available Bash functions, organized by namespaces.
   The --name option is used to list the available Bash functions by function name only.

   The --get option is used to emit synopsis information only.
   If <synopsis-var> is <B>-</B>, then emit to stdout.

   <G>Public</G> functions consist of lowercase letters, numbers, colon, and underscore characters only.
   <G>Private</G> functions are those whose named contain at least one uppercase character.
   Listings, by default, are restricted to public functions unless --private or --all is used.

   To obtain help, any of the following forms can be used:

      $__ help [<options>] [<search>]     ^Provide help, possibly searching for <search> function matches
      $__ --help [<options>] [<search>]   ^Identical to above
      $__ -h [<options>] [<search>]       ^Identical to above

   Bash API functions are organized into a hierarchy of namespaces and use various pieces to ensure uniqueness:

      p  ^Project directories are immediately under the <b>\$_base_dir</b> directory
      c  ^Component are immediately under project directories
      u  ^Unit directories are immediately under component directories
      f  ^Function names are namespace protected by the above

   <search> is one of the following patterns:

      The following patterns match a single function, if it exists:^<G

      PROJECT p   COMMON PROJECT _   DESCRIPTION^<K
      =========   ================   ===========^<K
      p:f         :f^                 Matches function <B>f</B> in project <B>p</B> or <B>_</B> namespace
      p:c:f       :c:f^               Matches function <B>f</B> in project <B>p</B> or <B>_</B>, component <B>c</B> namespace
      p:c:u:f     :c:u:f^             Matches function <B>f</B> in project <B>p</B> or <B>_</B>, component <B>c</B>, unit <B>u</B> namespace

      The following patterns can match multiple functions, if any exist:^<G <R>[Partially Implemented]</R>

      SEARCH      DESCRIPTION^<K
      ======      ===========
      /f          ^Matches <B>f</B> in any namespace

      /@f         ^Matches <B>f</B> in any project namespace

      /+f         ^Matches <B>f</B> in any component namespace
      /+c:f       ^Matches <B>f</B> in any component namespace <B>c</B>
      /++f        ^Matches <B>f</B> in any common component namespace

      /-f         ^Matches <B>f</B> in any unit namespace
      /-u:f       ^Matches <B>f</B> in any unit namespace <B>u</B>
      /-c:u:f     ^Matches <B>f</B> in any component namespace <B>c</B> and unit namespace <B>u</B>
      /--f        ^Matches <B>f</B> in any common unit namespace
      /--u:f      ^Matches <B>f</B> in any common unit namespace <B>u</B>

      The following idioms are included for completeness only and match 0 or 1 functions only:

      /@@f        ^Same as :f
      /++c:f      ^Same as :c:f
      /--c:u:f    ^Same as :c:u:f

   When an idiom from above matches just one function, any available help for that function is emitted.
   When an idiom from above matches more than one function, a list of matching functions is emitted.
   When an idiom from above matches no functions, an error is emitted.

   The <B>c</B>, <B>u</B>, or <B>f</B> above can contain pattern-matching characters (*, ?, [<list-or-range>])
   as described in the Bash man page.


SCRIPTING DESCRIPTION:
   If standard input is available to this command, then that input is formatted similar to a man(1) page.

HELP EXAMPLES:
   $__ help -l             ^List available modules and their short descriptions
   $__ help -l '*high*'    ^List all functions that contain the string <B>high</B>
   $__ help highlight    ^Provide help on the _highlight module
EOF
}

:help:()
{
   local ___help________Options
   ___help________Options=$(getopt -o 'lLsa' -l 'list,list-all,short,public,private,both,meta,all,set:,synopsis-var:,synopsis,usage:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___help________Options"

   [[ -v ___help______Mode ]] || local -g ___help______Mode='search'          # Ensure the Emit control variable is defined
   [[ -v ___help______Synopsis ]] || local -g ___help______Synopsis=
   [[ -v ___help______SynopsisVar ]] || local -g ___help______SynopsisVar=

   local ___help________Usage='[OPTIONS]'
   local ___help________GenerateList=false
   local -a ___help________ShowOptions=()

   while true ; do
      case "$1" in
      # External Options
      -l|--list)        ___help________GenerateList=true; shift;;
      -L|--list-all)    ___help________GenerateList=true; ___help________ShowOptions+=( --all ); shift;;
      -s|--short)       ___help________ShowOptions+=( --short ); shift;;

      --public)         ___help________ShowOptions+=( "$1" ); shift;;
      --private)        ___help________ShowOptions+=( "$1" ); shift;;
      --both)           ___help________ShowOptions+=( "$1" ); shift;;

      --meta)           ___help________ShowOptions+=( "$1" ); shift;;
      -a|--all)         ___help________ShowOptions+=( --all ); shift;;

      # Internal Options
      --set)            ___help______Synopsis="$2"; shift 2;;
      --synopsis-var)   ___help______SynopsisVar="$2"; shift 2;;
      --synopsis)       ___help______SynopsisVar='-'; shift;;
      --usage)          ___help________Usage="$2"; shift 2;;
      --)               shift; break;;
      *)                break;;
      esac
   done

   ### SYNOPSIS HANDLING
   if [[ $___help______Mode = synopsis ]]; then
      if [[ -n $___help______SynopsisVar && $___help______SynopsisVar != - ]]; then
         printf -v "$___help______SynopsisVar" '%s' "$___help______Synopsis"

      elif [[ -n $___help______Synopsis ]]; then
         echo "$___help______Synopsis"
      fi

      return 0
   fi

   if [[ -n $___help______SynopsisVar ]]; then
      if :test:has_func "$1%HELP"; then
         ___help______Mode='synopsis'
         "$1%HELP"
         ___help______Mode='search'
      fi

      return 0
   fi

   ### EMIT FUNCTION HELP
   if :test:has_stdin; then                              # Only true if being called from a %HELP function
      local ___help______Input=                                   # Transfer stdin to this variable
      ___help______Input="$(cat)"                                 # The raw man page is delivered via stdin

      {
         echo "\nSYNOPSIS: <B>${FUNCNAME[1]%\%HELP}</B> $___help________Usage"
         [[ -z $___help______Synopsis ]] || echo "   <G>$___help______Synopsis</G>"
         echo "\n$___help______Input"
      } | :highlight: --pager 'less -R'

      return 0
   fi

   ### NO REQUEST: PROVIDE GENERAL HELP
   if (( $# == 0 )) && ! $___help________GenerateList; then
      :help:%HELP                                          # Call the help function

      return 0
   fi

   ### SEARCH FOR FUNCTION MATCHES
   local -a ___help______FunctionMatches=()
   if :array:has_element -- ___help________ShowOptions '--all' ||
      :array:has_element -- ___help________ShowOptions '--meta'; then
      local -a ___help________FindOptions=()
   else
      local -a ___help________FindOptions=( --no-meta )
   fi

   :find:functions --find "${___help________FindOptions[@]}" --var ___help______FunctionMatches "$@"
                                                         # Get function matches based on the remaining arguments
   local -a ___help________PublicMatches
   readarray -t ___help________PublicMatches < <(                   # Determine if there is only one public match
      printf '%s\n' "${___help______FunctionMatches[@]}" |
      { grep -v '[A-Z]' || true; } |
      sed '/^\s*$/d'
   )
   if (( ${#___help________PublicMatches[@]} == 1 )) &&             # ... if so, and
         :test:has_func "$___help________PublicMatches%HELP" &&     # ... if a HELP function for it exists,
         ! $___help________GenerateList; then                       # ... and a listing is not explicitly requested

      "$___help________PublicMatches%HELP"                          # ... then display the found function's help page

   elif (( $# == 1 )) &&                                 # If only one <search> pattern is requested
      :array:has_element ___help______FunctionMatches "$1" &&     # and if there is an exact match
      :test:has_func "$1%HELP"; then                     # and there is a help function as well

      "$1%HELP"                                          # ... then show the help

   else
      ___help________ShowOptions+=( --var ___help______FunctionMatches )
      :show:functions "${___help________ShowOptions[@]}"
   fi
}
