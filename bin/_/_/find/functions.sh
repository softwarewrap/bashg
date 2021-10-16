#!/bin/bash

##############################################################################
# This function is used to identify %STARTUP functions, so it must not       #
# contain any references to variables that are defined in %STARTUP functions #
##############################################################################

:find:functions()
{
   local __find__functions__functions___Options
   __find__functions__functions___Options=$(getopt -o '' -l 'find,meta:,no-meta,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__find__functions__functions___Options"

   local __find__functions__functions___Find=false
   local __find__functions__functions___Meta=
   local __find__functions__functions___NoMeta=false
   local __find__functions__functions___Var='__find__functions__functions___UnspecifiedVar'

   while true ; do
      case "$1" in
      --find)        __find__functions__functions___Find=true; shift;;              # Search for regex instead of literal matches
                                                         # This is an alternative to args of the form: /<search>
      --meta)        __find__functions__functions___Meta="$2"; shift 2;;            # Look only for %<meta>[-<ordering>]$
      --no-meta)     __find__functions__functions___NoMeta=true; shift;;            # Do not return meta functions

      --var)         __find__functions__functions___Var="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local -a __find__functions__functions___Candidates=()
   local __find__functions__functions___SearchItem

   if (( $# == 0 )); then
      if [[ -n $__find__functions__functions___Meta ]]; then
         set -- "/.*%$__find__functions__functions___Meta"

      else
         set -- '/.'
      fi
   fi

   for __find__functions__functions___SearchItem in "$@"; do
      if :test:has_func "$__find__functions__functions___SearchItem%HELP"; then
         __find__functions__functions___Candidates+=( "$__find__functions__functions___SearchItem%HELP" )
      fi

      if :test:has_func "$__find__functions__functions___SearchItem:%HELP"; then
         __find__functions__functions___Candidates+=( "$__find__functions__functions___SearchItem:%HELP" )
      fi

      if $__find__functions__functions___Find || [[ $__find__functions__functions___SearchItem =~ ^/ ]]; then
         __find__functions__functions___SearchItem="${__find__functions__functions___SearchItem#/}"

         readarray -t -O "${#__find__functions__functions___Candidates[@]}" __find__functions__functions___Candidates < <(
            compgen -A function |
            { grep -P "$__find__functions__functions___SearchItem" || true; }
         )
      fi
   done

   [[ -v $__find__functions__functions___Var ]] || local -g "$__find__functions__functions___Var"

   readarray -t "$__find__functions__functions___Var" < <(
      printf '%s\n' "${__find__functions__functions___Candidates[@]}" |             # Start with existing candidate matches

      sort -u |                                          # Remove duplicates

      {
         if $__find__functions__functions___NoMeta; then
            grep -v '%[A-Z]*$'                           # Do not select meta functions ending with %[A-Z]*
         else
            cat
         fi
      } |

      {
         if [[ -n $__find__functions__functions___Meta ]]; then                     # Restrict to %<meta> functions
            local -a __find__functions__functions___Functions

            readarray -t __find__functions__functions___Functions < <(
               { grep -P "%$__find__functions__functions___Meta(-[0-9.]+)?$" || true; }
            )

            if (( ${#__find__functions__functions___Functions[@]} > 0 )); then
               local -a __find__functions__functions___OrderedFunctions

               readarray -t __find__functions__functions___OrderedFunctions < <(
                  printf '%s\n' "${__find__functions__functions___Functions[@]}" |
                  { grep -P "%$__find__functions__functions___Meta-[0-9.]+$" || true; } |
                  sort -t% -k2,2V -k1,1
               )
               readarray -t -O ${#__find__functions__functions___OrderedFunctions[@]} __find__functions__functions___OrderedFunctions < <(
                  printf '%s\n' "${__find__functions__functions___Functions[@]}" |
                  { grep -P "%$__find__functions__functions___Meta$" || true; } |
                  sort
               )

               printf '%s\n' "${__find__functions__functions___OrderedFunctions[@]}" |
               { grep -P "^:" || true; }

               printf '%s\n' "${__find__functions__functions___OrderedFunctions[@]}" |
               { grep -P "^[^:]" || true; }

            fi

         else
            cat
         fi
      } |

      LC_ALL=C sed '/^\s*$/d'                            # If after the above, there is nothing: ensure it is empty
   )

   if [[ $__find__functions__functions___Var = __find__functions__functions___UnspecifiedVar ]]; then          # If no Var was specified, emit to stdout
      printf '%s\n' "${__find__functions__functions___UnspecifiedVar[@]}"
   fi
}
