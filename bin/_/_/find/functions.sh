#!/bin/bash

##############################################################################
# This function is used to identify %STARTUP functions, so it must not       #
# contain any references to variables that are defined in %STARTUP functions #
##############################################################################

:find:functions()
{
   local ___find__functions__functions___Options
   ___find__functions__functions___Options=$(getopt -o '' -l 'find,meta:,no-meta,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___find__functions__functions___Options"

   local ___find__functions__functions___Find=false
   local ___find__functions__functions___Meta=
   local ___find__functions__functions___NoMeta=false
   local ___find__functions__functions___Var='___find__functions__functions___UnspecifiedVar'

   while true ; do
      case "$1" in
      --find)        ___find__functions__functions___Find=true; shift;;              # Search for regex instead of literal matches
                                                         # This is an alternative to args of the form: /<search>
      --meta)        ___find__functions__functions___Meta="$2"; shift 2;;            # Look only for %<meta>[-<ordering>]$
      --no-meta)     ___find__functions__functions___NoMeta=true; shift;;            # Do not return meta functions

      --var)         ___find__functions__functions___Var="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local -a ___find__functions__functions___Candidates=()
   local ___find__functions__functions___SearchItem

   if (( $# == 0 )); then
      if [[ -n $___find__functions__functions___Meta ]]; then
         set -- "/.*%$___find__functions__functions___Meta"

      else
         set -- '/.'
      fi
   fi

   for ___find__functions__functions___SearchItem in "$@"; do
      if :test:has_func "$___find__functions__functions___SearchItem%HELP"; then
         ___find__functions__functions___Candidates+=( "$___find__functions__functions___SearchItem%HELP" )
      fi

      if :test:has_func "$___find__functions__functions___SearchItem:%HELP"; then
         ___find__functions__functions___Candidates+=( "$___find__functions__functions___SearchItem:%HELP" )
      fi

      if $___find__functions__functions___Find || [[ $___find__functions__functions___SearchItem =~ ^/ ]]; then
         ___find__functions__functions___SearchItem="${___find__functions__functions___SearchItem#/}"

         readarray -t -O "${#___find__functions__functions___Candidates[@]}" ___find__functions__functions___Candidates < <(
            compgen -A function |
            { grep -P "$___find__functions__functions___SearchItem" || true; }
         )
      fi
   done

   [[ -v $___find__functions__functions___Var ]] || local -g "$___find__functions__functions___Var"

   readarray -t "$___find__functions__functions___Var" < <(
      printf '%s\n' "${___find__functions__functions___Candidates[@]}" |             # Start with existing candidate matches

      sort -u |                                          # Remove duplicates

      {
         if $___find__functions__functions___NoMeta; then
            grep -v '%[A-Z]*$'                           # Do not select meta functions ending with %[A-Z]*
         else
            cat
         fi
      } |

      {
         if [[ -n $___find__functions__functions___Meta ]]; then                     # Restrict to %<meta> functions
            local -a ___find__functions__functions___Functions

            readarray -t ___find__functions__functions___Functions < <(
               { grep -P "%$___find__functions__functions___Meta(-[0-9.]+)?$" || true; }
            )

            if (( ${#___find__functions__functions___Functions[@]} > 0 )); then
               local -a ___find__functions__functions___OrderedFunctions

               readarray -t ___find__functions__functions___OrderedFunctions < <(
                  printf '%s\n' "${___find__functions__functions___Functions[@]}" |
                  { grep -P "%$___find__functions__functions___Meta-[0-9.]+$" || true; } |
                  sort -t% -k2,2V -k1,1
               )
               readarray -t -O ${#___find__functions__functions___OrderedFunctions[@]} ___find__functions__functions___OrderedFunctions < <(
                  printf '%s\n' "${___find__functions__functions___Functions[@]}" |
                  { grep -P "%$___find__functions__functions___Meta$" || true; } |
                  sort
               )

               printf '%s\n' "${___find__functions__functions___OrderedFunctions[@]}" |
               { grep -P "^:" || true; }

               printf '%s\n' "${___find__functions__functions___OrderedFunctions[@]}" |
               { grep -P "^[^:]" || true; }

            fi

         else
            cat
         fi
      } |

      LC_ALL=C sed '/^\s*$/d'                            # If after the above, there is nothing: ensure it is empty
   )

   if [[ $___find__functions__functions___Var = ___find__functions__functions___UnspecifiedVar ]]; then          # If no Var was specified, emit to stdout
      printf '%s\n' "${___find__functions__functions___UnspecifiedVar[@]}"
   fi
}
