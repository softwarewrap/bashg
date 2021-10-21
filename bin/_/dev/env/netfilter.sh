#!/bin/bash

# See: https://www.linode.com/community/questions/11143/top-tip-firewalld-and-ipset-country-blacklist

.dev:env:netfilter()
{
   :sudo || :reenter                                     # This function must run as root

   local _dev__env__netfilter___NetFilterDir='/etc/netfilter'

   local _dev__env__netfilter__netfilter___Options
   _dev__env__netfilter__netfilter___Options=$(getopt -o 'ztru' -l 'zones,trust,rules,update' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$_dev__env__netfilter__netfilter___Options"

   local _dev__env__netfilter___Update=false
   local _dev__env__netfilter__netfilter___GetZoneData=false
   local _dev__env__netfilter__netfilter___UpdateTrust=false
   local _dev__env__netfilter__netfilter___UpdateRules=false

   while true ; do
      case "$1" in
      -z|--zones)    _dev__env__netfilter__netfilter___GetZoneData=true; shift;;
      -t|--trust)    _dev__env__netfilter__netfilter___UpdateTrust=true; shift;;
      -r|--rules)    _dev__env__netfilter__netfilter___UpdateRules=true; shift;;
      -u|--update)   _dev__env__netfilter___Update=true; shift;;

      --)            shift; break;;
      *)             break;;
      esac
   done

   if $_dev__env__netfilter___Update ||                                     # If force updating or if conditions require, get zone data
      $_dev__env__netfilter__netfilter___GetZoneData ||
      [[ ! -d $_dev__env__netfilter___NetFilterDir/zones ||
         ! -d $_dev__env__netfilter___NetFilterDir/countries ]]; then

      .dev:env:netfilter:GetZoneData
   fi

   if $_dev__env__netfilter___Update ||
      $_dev__env__netfilter__netfilter___UpdateTrust ||
      [[ ! -f $_dev__env__netfilter___NetFilterDir/allow.conf ||
         ! -d $_dev__env__netfilter___NetFilterDir/trusted ||
         ! -d $_dev__env__netfilter___NetFilterDir/untrusted ]]; then

      .dev:env:netfilter:UpdateTrust
   fi

   if $_dev__env__netfilter___Update ||
      $_dev__env__netfilter__netfilter___UpdateRules ||
      [[ ! -d $_dev__env__netfilter___NetFilterDir/rules ||
         ! -f $_dev__env__netfilter___NetFilterDir/rules.conf ]]; then

      .dev:env:netfilter:UpdateRules
   fi

   if :test:has_func ".dev:env:netfilter:${1^}"; then
      ".dev:env:netfilter:${1^}"
   fi
}

.dev:env:netfilter:GetZoneData()
{
   mkdir -p "$_dev__env__netfilter___NetFilterDir"                          # Ensure the netfilter dir exists
   cd "$_dev__env__netfilter___NetFilterDir"

   rm -rf ipblocks zones countries trusted untrusted     # Clear files and directories that will be rebuilt

   local -a _dev__env__netfilter__GetZoneData___CurlOptions=(
      --url       'https://www.ipdeny.com/ipblocks'
      --info-var  _dev__env__netfilter__GetZoneData___Info
      --get       http_code
      --output    "$_dev__env__netfilter___NetFilterDir/ipblocks"
      --
      -s
      -k
      -L
   )

   :curl: "${_dev__env__netfilter__GetZoneData___CurlOptions[@]}"

   if [[ ${_dev__env__netfilter__GetZoneData___Info[status]} -ne 0 || ! ${_dev__env__netfilter__GetZoneData___Info[http_code]} =~ ^2[0-9][0-9]$ ]]; then
      :error: 1 "Failed to get ipblocks: status=${_dev__env__netfilter__GetZoneData___Info[status]} and http_code=${_dev__env__netfilter__GetZoneData___Info[http_code]}"
      return
   fi

   local -a _dev__env__netfilter__GetZoneData___SedGetRegionsAndZones=(
      -e 's|^.*<tr><td><p>\([^(]*\)([^>]*>\([a-zA-Z0-9_]*\).*|\1\t\2|'
      -e 's|[^a-zA-Z0-9_ \t\n]||g' -e 's|  *\t|\t|' -e 's|  *|_|g'
   )

   mkdir zones countries
   local -a _dev__env__netfilter__GetZoneData___ZoneFailList=()
   local _dev__env__netfilter__GetZoneData___Country _dev__env__netfilter__GetZoneData___Zone

   while read _dev__env__netfilter__GetZoneData___Country _dev__env__netfilter__GetZoneData___Zone; do
      _dev__env__netfilter__GetZoneData___CurlOptions=(
         --url       "https://www.ipdeny.com/ipblocks/data/countries/$_dev__env__netfilter__GetZoneData___Zone.zone"
         --info-var  _dev__env__netfilter__GetZoneData___Info
         --get       http_code
         --output    "$_dev__env__netfilter___NetFilterDir/zones/$_dev__env__netfilter__GetZoneData___Zone.zone"
         --
         -s
         -k
         -L
      )

      echo -n "$_dev__env__netfilter__GetZoneData___Zone "
      :curl: "${_dev__env__netfilter__GetZoneData___CurlOptions[@]}"

      if [[ ${_dev__env__netfilter__GetZoneData___Info[status]} -ne 0 || ! ${_dev__env__netfilter__GetZoneData___Info[http_code]} =~ ^2[0-9][0-9]$ ]]; then
         _dev__env__netfilter__GetZoneData___ZoneFailList+=( "$_dev__env__netfilter__GetZoneData___Zone" )

      else
         ln -sr "zones/$_dev__env__netfilter__GetZoneData___Zone.zone" "countries/$_dev__env__netfilter__GetZoneData___Country"
      fi

   done < <(
      grep 'data/countries/.*\.zone' ipblocks |
      sed "${_dev__env__netfilter__GetZoneData___SedGetRegionsAndZones[@]}"
   )
   echo '.'

   if (( ${#_dev__env__netfilter__GetZoneData___ZoneFailList[@]} > 0 )); then
      :error: 0 "Failed to get the following zones:"
      printf '   %s\n' "${_dev__env__netfilter__GetZoneData___ZoneFailList[@]}"
      return 1
   fi

   _dev__env__netfilter___Update=true
}

.dev:env:netfilter:UpdateTrust()
{
   cd "$_dev__env__netfilter___NetFilterDir"

   if [[ ! -f allow.conf ]]; then
      /bin/ls -1 countries > allow.conf                  # If not yet set up, presume all countries will be allowed
   fi

   rm -rf trusted untrusted untrusted.zones              # Clear trust state
   cp -rp countries untrusted                            # Presume all countries are not trusted

   local -a _dev__env__netfilter__UpdateTrust___AllowedCountries
   readarray -t _dev__env__netfilter__UpdateTrust___AllowedCountries < <(                # Get the list of allowed countries
      cat allow.conf
   )

   mkdir trusted
   for _dev__env__netfilter__UpdateTrust___AllowedCountry in "${_dev__env__netfilter__UpdateTrust___AllowedCountries[@]}"; do
      if [[ -f untrusted/$_dev__env__netfilter__UpdateTrust___AllowedCountry ]]; then
         :log: "Allowing $_dev__env__netfilter__UpdateTrust___AllowedCountry"

         mv "untrusted/$_dev__env__netfilter__UpdateTrust___AllowedCountry" trusted/.

      else
         :error: 0 "Not allowing country without a zone file: $_dev__env__netfilter__UpdateTrust___AllowedCountry"
      fi
   done

   if (( ${#_dev__env__netfilter__UpdateTrust___AllowedCountries[@]} > 0 )); then
      cat untrusted/* > untrusted.zones
   else
      touch untrusted.zones
   fi
}

.dev:env:netfilter:UpdateRules()
{
   cd "$_dev__env__netfilter___NetFilterDir"

   mkdir -p rules                                        # Ensure a custom rules directory exists
   if [[ ! -f rules.conf ]]; then
      cp "$_lib_dir/_/dev/env"/@netfilter/services.conf .
   fi

   local _dev__env__netfilter__UpdateRules___NIC
   _dev__env__netfilter__UpdateRules___NIC="$( ip route get 1 | head -1 | awk '{print $5}' )"
   if [[ -z $_dev__env__netfilter__UpdateRules___NIC ]]; then
      :error: 1 'Cannot determine network interface'
      return
   fi

   local _dev__env__netfilter__UpdateRules___SSHPort
   _dev__env__netfilter__UpdateRules___SSHPort="$(grep '^Port\s\+' /etc/ssh/sshd_config | awk '{print $2}' | tail -1)"
   if [[ ! $_dev__env__netfilter__UpdateRules___SSHPort =~ ^[0-9]+$ ]]; then
      :error: 1 'Cannot determine SSH port'
      return
   fi

   local -a _dev__env__netfilter__UpdateRules___SedReplacements=(
      -e "s|%{NIC}%|$_dev__env__netfilter__UpdateRules___NIC|g"
      -e "s|%{SSHPort}%|$_dev__env__netfilter__UpdateRules___SSHPort|g"
   )

   local -a _dev__env__netfilter__UpdateRules___Services
   readarray -t _dev__env__netfilter__UpdateRules___Services < <(
      sed -e '/^\s*#/d' -e '/^\s*$/d' services.conf
   )

   {
      local _dev__env__netfilter__UpdateRules___Service
      local _dev__env__netfilter__UpdateRules___ServiceRuleFile

      cat "$_lib_dir/_/dev/env"/@netfilter/pre.rules                       # Before customized rules

      for _dev__env__netfilter__UpdateRules___Service in "${_dev__env__netfilter__UpdateRules___Services[@]}"; do
         local _dev__env__netfilter__UpdateRules___MatchFound=false                      # Assume the requested service is not found

         for _dev__env__netfilter__UpdateRules___RuleDir in rules "$_lib_dir/_/dev/env"/@netfilter; do     # Give priority to custom rules
            _dev__env__netfilter__UpdateRules___ServiceRuleFile="$_dev__env__netfilter__UpdateRules___RuleDir/$_dev__env__netfilter__UpdateRules___Service.rules"

            if [[ -f $_dev__env__netfilter__UpdateRules___ServiceRuleFile ]]; then
               echo
               cat "$_dev__env__netfilter__UpdateRules___ServiceRuleFile"

               _dev__env__netfilter__UpdateRules___MatchFound=true
               break
            fi
         done

         if ! $_dev__env__netfilter__UpdateRules___MatchFound; then
            :error: 0 "No match for service: $_dev__env__netfilter__UpdateRules___Service" >&2
         fi

      done

      echo
      cat "$_lib_dir/_/dev/env"/@netfilter/post.rules                      # After customized rules
   } |
      sed "${_dev__env__netfilter__UpdateRules___SedReplacements[@]}" > rules.conf
}

.dev:env:netfilter:Start()
{
   .dev:env:netfilter:Stop

   cd "$_dev__env__netfilter___NetFilterDir"

   if [[ ! -f untrusted.zones ]]; then
      :error: 1 'Missing untrusted.zones (run with -t to build trust)'
      return
   fi

   if [[ ! -f rules.conf ]]; then
      :error: 1 'Missing rules.conf (run with -r to build rules)'
      return
   fi

   {
      cat <<EOF
create denylist hash:net family inet hashsize 65536 maxelem 262144
EOF
      sed 's|^|add denylist |' < untrusted.zones
   } > untrusted.ipset

   ipset restore -exist < untrusted.ipset

   iptables-restore < rules.conf
   iptables-save > /etc/sysconfig/iptables

   systemctl restart iptables 2>/dev/null || true

   :log: "Total CIDR ranges denied: $(ipset list denylist | wc -l)"
}

.dev:env:netfilter:Stop()
{
   ipset flush denylist 2>/dev/null || true
   systemctl restart iptables 2>/dev/null || true
   sleep 1
   ipset destroy denylist 2>/dev/null || true

   iptables -P INPUT ACCEPT
   iptables -P FORWARD ACCEPT
   iptables -P OUTPUT ACCEPT

   local _dev__env__netfilter__Stop___Type
   for _dev__env__netfilter__Stop___Type in mangle nat raw; do
      iptables -t "$_dev__env__netfilter__Stop___Type" -X || true
      iptables -t "$_dev__env__netfilter__Stop___Type" -F || true
   done

   iptables -Z || true
   iptables -X LOG_DROP 2>/dev/null || true
   iptables -X PORTSCAN 2>/dev/null || true

   :log: 'Rules cleared'
}
