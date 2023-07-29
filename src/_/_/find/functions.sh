#!/bin/bash

##############################################################################
# This function is used to identify %STARTUP functions, so it must not       #
# contain any references to variables that are defined in %STARTUP functions #
##############################################################################

+ functions()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'find,meta:,no-meta,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Find=false
   local (.)_Meta=
   local (.)_NoMeta=false
   local (.)_Var='(.)_UnspecifiedVar'

   while true ; do
      case "$1" in
      --find)        (.)_Find=true; shift;;              # Search for regex instead of literal matches
                                                         # This is an alternative to args of the form: /<search>
      --meta)        (.)_Meta="$2"; shift 2;;            # Look only for %<meta>[-<ordering>]$
      --no-meta)     (.)_NoMeta=true; shift;;            # Do not return meta functions

      --var)         (.)_Var="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   local -a (.)_Candidates=()
   local (.)_SearchItem

   if (( $# == 0 )); then
      if [[ -n $(.)_Meta ]]; then
         set -- "/.*%$(.)_Meta"

      else
         set -- '/.'
      fi
   fi

   for (.)_SearchItem in "$@"; do
      if :test:has_func "$(.)_SearchItem%HELP"; then
         (.)_Candidates+=( "$(.)_SearchItem%HELP" )
      fi

      if :test:has_func "$(.)_SearchItem:%HELP"; then
         (.)_Candidates+=( "$(.)_SearchItem:%HELP" )
      fi

      if $(.)_Find || [[ $(.)_SearchItem =~ ^/ ]]; then
         (.)_SearchItem="${(.)_SearchItem#/}"

         readarray -t -O "${#(.)_Candidates[@]}" (.)_Candidates < <(
            compgen -A function |
            { grep -P "$(.)_SearchItem" || true; }
         )
      fi
   done

   [[ -v $(.)_Var ]] || local -g "$(.)_Var"

   readarray -t "$(.)_Var" < <(
      printf '%s\n' "${(.)_Candidates[@]}" |             # Start with existing candidate matches

      sort -u |                                          # Remove duplicates

      {
         if $(.)_NoMeta; then
            grep -v '%[A-Z]*$'                           # Do not select meta functions ending with %[A-Z]*
         else
            cat
         fi
      } |

      {
         if [[ -n $(.)_Meta ]]; then                     # Restrict to %<meta> functions
            local -a (.)_Functions

            readarray -t (.)_Functions < <(
               { grep -P "%$(.)_Meta(-[0-9.]+)?$" || true; }
            )

            if (( ${#(.)_Functions[@]} > 0 )); then
               local -a (.)_OrderedFunctions

               readarray -t (.)_OrderedFunctions < <(
                  printf '%s\n' "${(.)_Functions[@]}" |
                  { grep -P "%$(.)_Meta-[0-9.]+$" || true; } |
                  sort -t% -k2,2V -k1,1
               )
               readarray -t -O ${#(.)_OrderedFunctions[@]} (.)_OrderedFunctions < <(
                  printf '%s\n' "${(.)_Functions[@]}" |
                  { grep -P "%$(.)_Meta$" || true; } |
                  sort
               )

               printf '%s\n' "${(.)_OrderedFunctions[@]}" |
               { grep -P "^:" || true; }

               printf '%s\n' "${(.)_OrderedFunctions[@]}" |
               { grep -P "^[^:]" || true; }

            fi

         else
            cat
         fi
      } |

      LC_ALL=C sed '/^\s*$/d'                            # If after the above, there is nothing: ensure it is empty
   )

   if [[ $(.)_Var = (.)_UnspecifiedVar ]]; then          # If no Var was specified, emit to stdout
      printf '%s\n' "${(.)_UnspecifiedVar[@]}"
   fi
}
