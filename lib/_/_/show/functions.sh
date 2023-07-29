#!/bin/bash

+ functions()
{
   local (.)_Options
   (.)_Options=$(getopt -o '' -l 'short,public,private,both,meta,all,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (.)_Short=false                                 # Emit in short multi-column format
   local (.)_ShowPublic=false                            # Show private functions: has no uppercase
   local (.)_ShowPrivate=false                           # Show public functions: has some uppercase
   local (.)_ShowMeta=false                              # Also include any functions that contain %
   local (.)_Var='(.)_UnspecifiedVar'
   local -a (.)_UnspecifiedVar

   while true; do
      case "$1" in
      --short)    (.)_Short=true; shift;;
      --public)   (.)_ShowPublic=true; shift;;
      --private)  (.)_ShowPrivate=true; shift;;
      --both)     (.)_ShowPublic=true; (.)_ShowPrivate=true; shift;;
      --all)      (.)_ShowPublic=true; (.)_ShowPrivate=true; (.)_ShowMeta=true; shift;;
      --meta)     (.)_ShowMeta=true; shift;;
      --var)      (.)_Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if ! $(.)_ShowPublic && ! $(.)_ShowPrivate && ! $(.)_ShowMeta; then
      (.)_ShowPublic=true
   fi

   local -a (.)_Candidates

   if :test:has_stdin; then
      readarray -t "(.)_Candidates" < <(cat)

   else
      local (.)_Indirect="$(.)_Var[@]"
      (.)_Candidates=( "${!(.)_Indirect}" )
   fi

   local -a (.)_Functions=()
   local (.)_Candidate

   for (.)_Candidate in "${(.)_Candidates[@]}"; do
      if $(.)_ShowPrivate; then
         if grep -q '[A-Z]' <<<"${(.)_Candidate%%%*}"; then
            if $(.)_ShowMeta || [[ ! $(.)_Candidate =~ % ]]; then
               (.)_Functions+=( "$(.)_Candidate" )
            fi
            continue
         fi
      fi

      if $(.)_ShowPublic; then
         if grep -q -v '[A-Z]' <<<"${(.)_Candidate%%%*}"; then
            if $(.)_ShowMeta || [[ ! $(.)_Candidate =~ % ]]; then
               (.)_Functions+=( "$(.)_Candidate" )
            fi
            continue
         fi
      fi

      if $(.)_ShowMeta && [[ $(.)_Candidate =~ % ]]; then
         (.)_Functions+=( "$(.)_Candidate" )
      fi
   done

   if (( ${#(.)_Functions[@]} == 0 )); then
      echo 'No functions found'
      return
   fi

   local (.)_Synopsis
   local (.)_Function

   echo -e '<B>Functions</B>\n' | :highlight:

   {
      for (.)_Function in "${(.)_Functions[@]}"; do
         (.)_Synopsis=
         if :test:has_func "$(.)_Function%HELP"; then
            :help: --synopsis-var (.)_Synopsis "$(.)_Function"
         fi

         if $(.)_Short; then
            echo "$(.)_Function"
         else
            echo "$(.)_Function|$(.)_Synopsis"
         fi
      done |
      {
         if $(.)_Short; then
            local (.)_OneColumn                          # The initial listing is just a single column
            local -i (.)_MaxLength                       # Get the maximum line length here
            local -i (.)_MaxColumns="$_COLS"             # Get the terminal maximum (current) width
            local -i (.)_Columns                         # Determine how many columns can be created
            local -i (.)_Width                           # Determine the width of each column

            (.)_OneColumn="$(cat)"                       # Store the current stream
            (.)_MaxLength=$(wc -L <<<"$(.)_OneColumn")

            (.)_Columns=$(( (.)_MaxColumns / ( (.)_MaxLength + 1 ) ))
                                                         # Add one character to be a space between columns
            (.)_Width=$(( (.)_MaxColumns / (.)_Columns ))

            pr -$(.)_Columns -t -s$'\t' <<<"$(.)_OneColumn" |
                                                         # Emit as multi-columns separated by tabs
            expand -$(.)_Width                           # Convert the tab to the calculated width
         else
            :text:align |
            sed 's|\(^[^ ]*\)\(.*\)|   <B>\1</B>\2|'
         fi
      }
   } |
   :highlight:
}
