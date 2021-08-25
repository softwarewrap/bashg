#!/bin/bash

##################################
# DIRECTLY EXECUTABLE STATEMENTS #
##################################

# _reenter_vars:
#     A list of arguments to pass when calling $_program again.
#     Construct: <options>:<parameter>=<declare-string>
#     where <options> are the declare options without the leading -
#     The -g option is not included by declare but will be added
#     later during reentry options parsing

# (+:launcher)_Config[bash.set]
#     Note that under command substitution the setting for errexit is not preserved
#     and is unconditionally rendered as set +o errexit.
#     The conditional code is a workaround to ensure that the setting is preserved
#     when errexit is enabled.
#     The base64 encode/decode is needed to ensure that newlines in the output do
#     not cause parsing errors during reentry.

shopt -s expand_aliases                                  # Expand aliases in functions
alias :reenter=$'
{
   if [[ $_whoami != $_RunAs ]]; then
      sudo -n true &>/dev/null || return

      local -a _reentry_vars=()

      (+:launcher)_Config[pwd]="$(pwd)"

      if [[ $- =~ e ]]; then
         (+:launcher)_Config[bash.set]="$( { set +o; echo "set -o errexit"; } | base64 -w0)"
      else
         (+:launcher)_Config[bash.set]="$(set +o | base64 -w0)"
      fi

      (+:launcher)_Config[bash.shopt]="$(shopt -p | base64 -w0)"

      _entry_initial=false

      local _entry_var
      for _entry_var in _entry_vars "${!_entry_vars[@]}"; do
         if [[ -v $_entry_var ]]; then
            local _declare="$(
               declare -p "$_entry_var" |
               sed -e "s|^declare\\s*\\(-\\([^ ]*\\) \\)\\?|\\2:|" -e "s|^-||"
            )"
            _reentry_vars+=( "-=" "$_declare" )
         fi
      done

      sudo -iu "$_RunAs" -- bash "$_program" -u "$_entry_user" "${_reentry_vars[@]}" -- ${(+:launcher)_Config[reenter]:-$FUNCNAME} "$@"
      return
   fi
}
'
