#!/bin/bash

:show:functions()
{
   local __show__functions__functions___Options
   __show__functions__functions___Options=$(getopt -o '' -l 'short,public,private,both,meta,all,var:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$__show__functions__functions___Options"

   local __show__functions__functions___Short=false                                 # Emit in short multi-column format
   local __show__functions__functions___ShowPublic=false                            # Show private functions: has no uppercase
   local __show__functions__functions___ShowPrivate=false                           # Show public functions: has some uppercase
   local __show__functions__functions___ShowMeta=false                              # Also include any functions that contain %
   local __show__functions__functions___Var='__show__functions__functions___UnspecifiedVar'
   local -a __show__functions__functions___UnspecifiedVar

   while true; do
      case "$1" in
      --short)    __show__functions__functions___Short=true; shift;;
      --public)   __show__functions__functions___ShowPublic=true; shift;;
      --private)  __show__functions__functions___ShowPrivate=true; shift;;
      --both)     __show__functions__functions___ShowPublic=true; __show__functions__functions___ShowPrivate=true; shift;;
      --all)      __show__functions__functions___ShowPublic=true; __show__functions__functions___ShowPrivate=true; __show__functions__functions___ShowMeta=true; shift;;
      --meta)     __show__functions__functions___ShowMeta=true; shift;;
      --var)      __show__functions__functions___Var="$2"; shift 2;;
      --)         shift; break;;
      *)          break;;
      esac
   done

   if ! $__show__functions__functions___ShowPublic && ! $__show__functions__functions___ShowPrivate && ! $__show__functions__functions___ShowMeta; then
      __show__functions__functions___ShowPublic=true
   fi

   local -a __show__functions__functions___Candidates

   if :test:has_stdin; then
      readarray -t "__show__functions__functions___Candidates" < <(cat)

   else
      local __show__functions__functions___Indirect="$__show__functions__functions___Var[@]"
      __show__functions__functions___Candidates=( "${!__show__functions__functions___Indirect}" )
   fi

   local -a __show__functions__functions___Functions=()
   local __show__functions__functions___Candidate

   for __show__functions__functions___Candidate in "${__show__functions__functions___Candidates[@]}"; do
      if $__show__functions__functions___ShowPrivate; then
         if grep -q '[A-Z]' <<<"${__show__functions__functions___Candidate%%%*}"; then
            if $__show__functions__functions___ShowMeta || [[ ! $__show__functions__functions___Candidate =~ % ]]; then
               __show__functions__functions___Functions+=( "$__show__functions__functions___Candidate" )
            fi
            continue
         fi
      fi

      if $__show__functions__functions___ShowPublic; then
         if grep -q -v '[A-Z]' <<<"${__show__functions__functions___Candidate%%%*}"; then
            if $__show__functions__functions___ShowMeta || [[ ! $__show__functions__functions___Candidate =~ % ]]; then
               __show__functions__functions___Functions+=( "$__show__functions__functions___Candidate" )
            fi
            continue
         fi
      fi

      if $__show__functions__functions___ShowMeta && [[ $__show__functions__functions___Candidate =~ % ]]; then
         __show__functions__functions___Functions+=( "$__show__functions__functions___Candidate" )
      fi
   done

   if (( ${#__show__functions__functions___Functions[@]} == 0 )); then
      echo 'No functions found'
      return
   fi

   local __show__functions__functions___Synopsis
   local __show__functions__functions___Function

   echo -e '<B>Functions</B>\n' | :highlight:

   {
      for __show__functions__functions___Function in "${__show__functions__functions___Functions[@]}"; do
         __show__functions__functions___Synopsis=
         if :test:has_func "$__show__functions__functions___Function%HELP"; then
            :help: --synopsis-var __show__functions__functions___Synopsis "$__show__functions__functions___Function"
         fi

         if $__show__functions__functions___Short; then
            echo "$__show__functions__functions___Function"
         else
            echo "$__show__functions__functions___Function|$__show__functions__functions___Synopsis"
         fi
      done |
      {
         if $__show__functions__functions___Short; then
            local __show__functions__functions___OneColumn                          # The initial listing is just a single column
            local -i __show__functions__functions___MaxLength                       # Get the maximum line length here
            local -i __show__functions__functions___MaxColumns="$_COLS"             # Get the terminal maximum (current) width
            local -i __show__functions__functions___Columns                         # Determine how many columns can be created
            local -i __show__functions__functions___Width                           # Determine the width of each column

            __show__functions__functions___OneColumn="$(cat)"                       # Store the current stream
            __show__functions__functions___MaxLength=$(wc -L <<<"$__show__functions__functions___OneColumn")

            __show__functions__functions___Columns=$(( __show__functions__functions___MaxColumns / ( __show__functions__functions___MaxLength + 1 ) ))
                                                         # Add one character to be a space between columns
            __show__functions__functions___Width=$(( __show__functions__functions___MaxColumns / __show__functions__functions___Columns ))

            pr -$__show__functions__functions___Columns -t -s$'\t' <<<"$__show__functions__functions___OneColumn" |
                                                         # Emit as multi-columns separated by tabs
            expand -$__show__functions__functions___Width                           # Convert the tab to the calculated width
         else
            :text:align |
            sed 's|\(^[^ ]*\)\(.*\)|   <B>\1</B>\2|'
         fi
      }
   } |
   :highlight:
}
