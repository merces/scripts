#!/bin/bash
#
#   checkdns.sh - Looks for suspicious behaviour in DNS servers
#   
#   Copyright (C) 2015 Fernando Mercês
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Verbosity levels
normal=0
info=1
debug=2
csv=3

# set defaults
verbosity=${normal}
file_dns_ips=""
file_domains=""

log() {
    if [[ $1 -eq ${verbosity} ]]; then
        echo "$(date), $2, $3";
    elif [[ $1 -ge ${verbosity} ]]; then
        echo "$(date) [$3] $3";
    fi
}

# Domains to check
sites=( itau.com.br bradesco.com.br hsbc.com.br bb.com.br caixa.gov.br \
banrisul.com.br facebook.com.br facebook.com gmail.com hotmail.com \
hotmail.com.br serasaexperian.com.br mercadolivre.com.br pagseguro.com.br \
paypal.com paypal.com.br youtube.com youtube.com.br googleadservices.com \
googlesyndication.com doubleclick.net tam.com.br googletagmanager.com \
googleapis.com )

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-a] [-d FILE_DOMAINS] [-i FILE_DNS_IPS]

Deploy user and associated SSH key to target server. Can optionally
set user as the server admin.

    -d FILE_DOMAINS     Optional. Specify the file containing the domains to
                                  check
    -i FILE_DNS_IPS     Optional. Specify the file containing the IPs of the
                                  name servers to interrogate
    -h                  Display this help and exit
    -v                  Verbosity. -v=INFO. -vv=DEBUG

EOF
}

while getopts "d:i:hv" opt; do
    case "$opt" in
        d) file_domains=$OPTARG
           ;;
        i) file_dns_ips=$OPTARG
           ;;
        h)
           show_help
           exit 0
           ;;
        v)
           #each -v should increase verbosity level
           verbosity=$(($verbosity+1))
           ;;
        \?)
           echo
           show_help >&2
           exit 1
           ;;
    esac
done

if [[ -z ${file_dns_ips} ]]; then
    dnss=$(grep ^nameserver /etc/resolv.conf | cut -d' ' -f2 | tr \\n ' ')
else
    dnss=$(cat ${file_dns_ips} | tr \\n ' ')
fi

if [[ ! -z ${file_domains} ]]; then
    sites=($(cat ${file_domains} | tr \\n " " ))
fi

for dns in $dnss; do
    found=false
    online=false
    log $debug $dns "Checks started..."
    for site in ${sites[@]}; do
        log $info $dns "Querying A record for \"${site}\""
        dns_google=$(dig +short ${site} @8.8.8.8 2>/dev/null)

        dns_ip=$(tr \\n ' ' <<< $dns_google)
        log $debug $dns "Google (8.8.8.8) answered with ${dns_ip}"
        log $csv "8.8.8.8" "${site}, ${dns_ip}"

        dns_suspicious=$(dig +short +tries=1 +time=3 $site @$dns | head -1)
        [[ "$dns_suspicious" =~ ^([0-9]{1,3}\.){3} ]] || { log $info $dns "No answer"; break; }
        online=true

        dns_ip_suspicious=$(tr \\n ' ' <<< $dns_suspicious)
        log $debug $dns "Queried server answered with ${dns_ip_supicious}"

        # Handling exceptions for Google, Akamai and Caixa
        whois $dns_suspicious 2>/dev/null |
         grep -qE 'Ref:.*http://whois\.arin\.net/rest/org/(GOGL|AKAMAI)|owner:.*AKAMAI|address:.*Akamai Technologies|e-mail:.*dominio\.administrativo@caixa\.gov\.br' &&
        {
            log $debug $dns "Good IP owner found";
            log $csv $dns "${site}, ${dns_ip_suspicious}, good"
            continue;
        }

        if [[ $dns_google = *$dns_suspicious* ]]; then
            found=true;
            log $csv $dns "${site}, ${dns_ip_suspicious}, good"
        else
            found=true;
            log $normal $dns "oddly resolved $site to $dns_suspicious";
            log $csv $dns "${site}, ${dns_ip_suspicious}, odd"
        fi
    done
    [[ $found && $online ]] || { (( $verbosity > 0 )) && log $info $dns "Looks clean"; }
done

