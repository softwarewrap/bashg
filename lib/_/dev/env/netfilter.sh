#!/bin/bash

# See: https://www.linode.com/community/questions/11143/top-tip-firewalld-and-ipset-country-blacklist

+ netfilter()
{
   :sudo || :reenter                                     # This function must run as root

   local (-)_NetFilterDir='/etc/netfilter'

   local (.)_Options
   (.)_Options=$(getopt -o 'ztru' -l 'zones,trust,rules,update' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (-)_Update=false
   local (.)_GetZoneData=false
   local (.)_UpdateTrust=false
   local (.)_UpdateRules=false

   while true ; do
      case "$1" in
      -z|--zones)    (.)_GetZoneData=true; shift;;
      -t|--trust)    (.)_UpdateTrust=true; shift;;
      -r|--rules)    (.)_UpdateRules=true; shift;;
      -u|--update)   (-)_Update=true; shift;;

      --)            shift; break;;
      *)             break;;
      esac
   done

   if $(-)_Update ||                                     # If force updating or if conditions require, get zone data
      $(.)_GetZoneData ||
      [[ ! -d $(-)_NetFilterDir/zones ||
         ! -d $(-)_NetFilterDir/countries ]]; then

      (-):GetZoneData
   fi

   if $(-)_Update ||
      $(.)_UpdateTrust ||
      [[ ! -f $(-)_NetFilterDir/allow.conf ||
         ! -d $(-)_NetFilterDir/trusted ||
         ! -d $(-)_NetFilterDir/untrusted ]]; then

      (-):UpdateTrust
   fi

   if $(-)_Update ||
      $(.)_UpdateRules ||
      [[ ! -d $(-)_NetFilterDir/rules ||
         ! -f $(-)_NetFilterDir/rules.conf ]]; then

      (-):UpdateRules
   fi

   if :test:has_func "(-):${1^}"; then
      "(-):${1^}"
   fi
}

- GetZoneData()
{
   mkdir -p "$(-)_NetFilterDir"                          # Ensure the netfilter dir exists
   cd "$(-)_NetFilterDir"

   rm -rf ipblocks zones countries trusted untrusted     # Clear files and directories that will be rebuilt

   local -a (.)_CurlOptions=(
      --url       'https://www.ipdeny.com/ipblocks'
      --info-var  (.)_Info
      --get       http_code
      --output    "$(-)_NetFilterDir/ipblocks"
      --
      -s
      -k
      -L
   )

   :curl: "${(.)_CurlOptions[@]}"

   if [[ ${(.)_Info[status]} -ne 0 || ! ${(.)_Info[http_code]} =~ ^2[0-9][0-9]$ ]]; then
      :error: 1 "Failed to get ipblocks: status=${(.)_Info[status]} and http_code=${(.)_Info[http_code]}"
      return
   fi

   local -a (.)_SedGetRegionsAndZones=(
      -e 's|^.*<tr><td><p>\([^(]*\)([^>]*>\([a-zA-Z0-9_]*\).*|\1\t\2|'
      -e 's|[^a-zA-Z0-9_ \t\n]||g' -e 's|  *\t|\t|' -e 's|  *|_|g'
   )

   mkdir zones countries
   local -a (.)_ZoneFailList=()
   local (.)_Country (.)_Zone

   while read (.)_Country (.)_Zone; do
      (.)_CurlOptions=(
         --url       "https://www.ipdeny.com/ipblocks/data/countries/$(.)_Zone.zone"
         --info-var  (.)_Info
         --get       http_code
         --output    "$(-)_NetFilterDir/zones/$(.)_Zone.zone"
         --
         -s
         -k
         -L
      )

      echo -n "$(.)_Zone "
      :curl: "${(.)_CurlOptions[@]}"

      if [[ ${(.)_Info[status]} -ne 0 || ! ${(.)_Info[http_code]} =~ ^2[0-9][0-9]$ ]]; then
         (.)_ZoneFailList+=( "$(.)_Zone" )

      else
         ln -sr "zones/$(.)_Zone.zone" "countries/$(.)_Country"
      fi

   done < <(
      grep 'data/countries/.*\.zone' ipblocks |
      sed "${(.)_SedGetRegionsAndZones[@]}"
   )
   echo '.'

   if (( ${#(.)_ZoneFailList[@]} > 0 )); then
      :error: 0 "Failed to get the following zones:"
      printf '   %s\n' "${(.)_ZoneFailList[@]}"
      return 1
   fi

   (-)_Update=true
}

- UpdateTrust()
{
   cd "$(-)_NetFilterDir"

   if [[ ! -f allow.conf ]]; then
      /bin/ls -1 countries > allow.conf                  # If not yet set up, presume all countries will be allowed
   fi

   rm -rf trusted untrusted untrusted.zones              # Clear trust state
   cp -rp countries untrusted                            # Presume all countries are not trusted

   local -a (.)_AllowedCountries
   readarray -t (.)_AllowedCountries < <(                # Get the list of allowed countries
      cat allow.conf
   )

   mkdir trusted
   for (.)_AllowedCountry in "${(.)_AllowedCountries[@]}"; do
      if [[ -f untrusted/$(.)_AllowedCountry ]]; then
         :log: "Allowing $(.)_AllowedCountry"

         mv "untrusted/$(.)_AllowedCountry" trusted/.

      else
         :error: 0 "Not allowing country without a zone file: $(.)_AllowedCountry"
      fi
   done

   if (( ${#(.)_AllowedCountries[@]} > 0 )); then
      :glob:set                                          # Expand "no match" to the empty string
      local -a (.)_Untrusted=(
         untrusted/*                                     # Get the list of untrusted zones, if any
      )
      :glob:reset

      if (( ${#(.)_Untrusted > 0 )); then
         cat "${(.)_Untrusted[@]}" > untrusted.zones
      fi
   else
      touch untrusted.zones
   fi
}

- UpdateRules()
{
   cd "$(-)_NetFilterDir"

   mkdir -p rules                                        # Ensure a custom rules directory exists
   if [[ ! -f rules.conf ]]; then
      cp (+)/@netfilter/services.conf .
   fi

   local (.)_NIC
   (.)_NIC="$( ip route get 1 | head -1 | awk '{print $5}' )"
   if [[ -z $(.)_NIC ]]; then
      :error: 1 'Cannot determine network interface'
      return
   fi

   local (.)_SSHPort
   (.)_SSHPort="$(grep '^Port\s\+' /etc/ssh/sshd_config | awk '{print $2}' | tail -1)"
   if [[ ! $(.)_SSHPort =~ ^[0-9]+$ ]]; then
      :error: 1 'Cannot determine SSH port'
      return
   fi

   local -a (.)_SedReplacements=(
      -e "s|%{NIC}%|$(.)_NIC|g"
      -e "s|%{SSHPort}%|$(.)_SSHPort|g"
   )

   local -a (.)_Services
   readarray -t (.)_Services < <(
      sed -e '/^\s*#/d' -e '/^\s*$/d' services.conf
   )

   {
      local (.)_Service
      local (.)_ServiceRuleFile

      cat (+)/@netfilter/pre.rules                       # Before customized rules

      for (.)_Service in "${(.)_Services[@]}"; do
         local (.)_MatchFound=false                      # Assume the requested service is not found

         for (.)_RuleDir in rules (+)/@netfilter; do     # Give priority to custom rules
            (.)_ServiceRuleFile="$(.)_RuleDir/$(.)_Service.rules"

            if [[ -f $(.)_ServiceRuleFile ]]; then
               echo
               cat "$(.)_ServiceRuleFile"

               (.)_MatchFound=true
               break
            fi
         done

         if ! $(.)_MatchFound; then
            :error: 0 "No match for service: $(.)_Service" >&2
         fi

      done

      echo
      cat (+)/@netfilter/post.rules                      # After customized rules
   } |
      sed "${(.)_SedReplacements[@]}" > rules.conf
}

- Start()
{
   (-):Stop

   cd "$(-)_NetFilterDir"

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

- Stop()
{
   ipset flush denylist 2>/dev/null || true
   systemctl restart iptables 2>/dev/null || true
   sleep 1
   ipset destroy denylist 2>/dev/null || true

   iptables -P INPUT ACCEPT
   iptables -P FORWARD ACCEPT
   iptables -P OUTPUT ACCEPT

   local (.)_Type
   for (.)_Type in mangle nat raw; do
      iptables -t "$(.)_Type" -X || true
      iptables -t "$(.)_Type" -F || true
   done

   iptables -F || true
   iptables -Z || true
   iptables -X LOG_DROP 2>/dev/null || true
   iptables -X PORTSCAN 2>/dev/null || true

   :log: 'Rules cleared'
}
