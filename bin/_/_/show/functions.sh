#!/bin/bash

:show:functions()
{
   local ___show__functions__functions___Options
   ___show__functions__functions___Options=$(getopt -o '' -l 'short,public,private,both,meta,all,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$___show__functions__functions___Options"

   local ___show__functions__functions___Short=false                                 # Emit in short multi-column format
   local ___show__functions__functions___ShowPublic=false                            # Show private functions: has no uppercase
   local ___show__functions__functions___ShowPrivate=false                           # Show public functions: has some uppercase
   local ___show__functions__functions___ShowMeta=false                              # Also include any functions that contain %
   local ___show__functions__functions___Var='___show__functions__functions___UnspecifiedVar'
   local -a ___show__functions__functions___UnspecifiedVar

   while true; do
      case "$1" in
      --short)    ___show__functions__functions___Short=true; shift;;
      --public)   ___show__functions__functions___ShowPublic=true; shift;;
      --private)  ___show__functions__functions___ShowPrivate=true; shift;;
      --both)     ___show__functions__functions___ShowPublic=true; ___show__functions__functions___ShowPrivate=true; shift;;
      --all)      ___show__functions__functions___ShowPublic=true; ___show__functions__functions___ShowPrivate=true; ___show__functions__functions___ShowMeta=true; shift;;
      --meta)     ___show__functions__functions___ShowMeta=true; shift;;
      --var)      ___show__functions__functions___Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if ! $___show__functions__functions___ShowPublic && ! $___show__functions__functions___ShowPrivate && ! $___show__functions__functions___ShowMeta; then
      ___show__functions__functions___ShowPublic=true
   fi

   local -a ___show__functions__functions___Candidates

   if :test:has_stdin; then
      readarray -t "___show__functions__functions___Candidates" < <(cat)

   else
      local ___show__functions__functions___Indirect="$___show__functions__functions___Var[@]"
      ___show__functions__functions___Candidates=( "${!___show__functions__functions___Indirect}" )
   fi

   local -a ___show__functions__functions___Functions=()
   local ___show__functions__functions___Candidate

   for ___show__functions__functions___Candidate in "${___show__functions__functions___Candidates[@]}"; do
      if $___show__functions__functions___ShowPrivate; then
         if grep -q '[A-Z]' <<<"${___show__functions__functions___Candidate%%%*}"; then
            if $___show__functions__functions___ShowMeta || [[ ! $___show__functions__functions___Candidate =~ % ]]; then
               ___show__functions__functions___Functions+=( "$___show__functions__functions___Candidate" )
            fi
            continue
         fi
      fi

      if $___show__functions__functions___ShowPublic; then
         if grep -q -v '[A-Z]' <<<"${___show__functions__functions___Candidate%%%*}"; then
            if $___show__functions__functions___ShowMeta || [[ ! $___show__functions__functions___Candidate =~ % ]]; then
               ___show__functions__functions___Functions+=( "$___show__functions__functions___Candidate" )
            fi
            continue
         fi
      fi

      if $___show__functions__functions___ShowMeta && [[ $___show__functions__functions___Candidate =~ % ]]; then
         ___show__functions__functions___Functions+=( "$___show__functions__functions___Candidate" )
      fi
   done

   if (( ${#___show__functions__functions___Functions[@]} == 0 )); then
      echo 'No functions found'
      return
   fi

   local ___show__functions__functions___Synopsis
   local ___show__functions__functions___Function

   echo -e '<B>Functions</B>\n' | :highlight:

   {
      for ___show__functions__functions___Function in "${___show__functions__functions___Functions[@]}"; do
         ___show__functions__functions___Synopsis=
         if :test:has_func "$___show__functions__functions___Function%HELP"; then
            :help: --synopsis-var ___show__functions__functions___Synopsis "$___show__functions__functions___Function"
         fi

         if $___show__functions__functions___Short; then
            echo "$___show__functions__functions___Function"
         else
            echo "$___show__functions__functions___Function|$___show__functions__functions___Synopsis"
         fi
      done |
      {
         if $___show__functions__functions___Short; then
            local ___show__functions__functions___OneColumn                          # The initial listing is just a single column
            local -i ___show__functions__functions___MaxLength                       # Get the maximum line length here
            local -i ___show__functions__functions___MaxColumns                      # Get the terminal maximum (current) width
            local -i ___show__functions__functions___Columns                         # Determine how many columns can be created
            local -i ___show__functions__functions___Width                           # Determine the width of each column

            ___show__functions__functions___OneColumn="$(cat)"                       # Store the current stream
            ___show__functions__functions___MaxLength=$(wc -L <<<"$___show__functions__functions___OneColumn")
            ___show__functions__functions___MaxColumns="$(tput cols)"                # Get the number of columns in the present terminal
            ___show__functions__functions___Columns=$(( ___show__functions__functions___MaxColumns / ( ___show__functions__functions___MaxLength + 1 ) ))
                                                         # Add one character to be a space between columns
            ___show__functions__functions___Width=$(( ___show__functions__functions___MaxColumns / ___show__functions__functions___Columns ))

            pr -$___show__functions__functions___Columns -t -s$'\t' <<<"$___show__functions__functions___OneColumn" |
                                                         # Emit as multi-columns separated by tabs
            expand -$___show__functions__functions___Width                           # Convert the tab to the calculated width
         else
            :text:align |
            sed 's|\(^[^ ]*\)\(.*\)|   <B>\1</B>\2|'
         fi
      }
   } |
   :highlight:
}
