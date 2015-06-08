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

log() { (( $verbosity >= $1 )) && echo "$(date) [$2] $3"; }

# Domains to check
sites=( itau.com.br bradesco.com.br hsbc.com.br bb.com.br caixa.gov.br \
banrisul.com.br facebook.com.br facebook.com gmail.com hotmail.com \
hotmail.com.br serasaexperian.com.br mercadolivre.com.br pagseguro.com.br \
paypal.com paypal.com.br youtube.com youtube.com.br googleadservices.com \
googlesyndication.com doubleclick.net tam.com.br googletagmanager.com \
googleapis.com )

# Calculate verbosity level
normal=0
info=1
debug=2
[[ "$1" =~ ^\-v+ ]] && { verbosity=$((${#1}-1)); shift; } || verbosity=$normal

[[ -n "$1" ]] && dnss=$@ || dnss=$(grep ^nameserver /etc/resolv.conf | cut -d' ' -f2 | tr \\n ' ')

for dns in $dnss; do
	found=false
	online=false
	log $debug $dns "Checks started..."
	for site in ${sites[@]}; do
		log $info $dns "Querying A record for $site"
		dns_google=$(dig +short $site @8.8.8.8 2>/dev/null)
		log $debug $dns "Google (8.8.8.8) answered with $(tr \\n ' ' <<< $dns_google)"
		dns_suspicious=$(dig +short +tries=1 +time=3 $site @$dns | head -1)
		[[ "$dns_suspicious" =~ ^([0-9]{1,3}\.){3} ]] || { log $info $dns "No answer"; break; }
		online=true
		log $debug $dns "Queried server answered with $(tr \\n ' ' <<< $dns_google)"

		# Handling exceptions for Google, Akamai and Caixa
		whois $dns_suspicious 2>/dev/null |
		 grep -qE 'Ref:.*http://whois\.arin\.net/rest/org/(GOGL|AKAMAI)|owner:.*AKAMAI|address:.*Akamai Technologies|e-mail:.*dominio\.administrativo@caixa\.gov\.br' && 
		 { log $debug $dns "Good IP owner found"; continue; }

		[[ $dns_google = *$dns_suspicious* ]] || { log $normal $dns "oddly resolved $site to $dns_suspicious"; found=true; }
	done
	[[ $found && $online ]] || { (( $verbosity > 0 )) && log $info $dns "Looks clean"; }
done
