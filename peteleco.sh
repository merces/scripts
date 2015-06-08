#!/bin/bash
#
# peteleco - HTTP methods test script
#
# Copyright (C) 2012 Fernando Mercês
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

me=peteleco
ver=1.0

usage()
{
	echo -e "\n$me $ver\n\n"\
	"sends http requests to web servers using netcat\n\n" \
	"usage:\n\t$me [method] [-0] [-v] host\n\n" \
	"method can be:\n" \
	" --head\n" \
	" --trace\n" \
	" --options\n" \
	" --put\n" \
	" --delete\n" \
	" --connect\n" \
	" --get\n" \
	" --get-range\n" \
	" --post\n" \
	" --patch\n" \
	"or any combination of these.\n" \
	"by default $me sends a request for each HTTP method\n" \
	"against host (excpet --get-range, a GET with Range header)\n\n" \
	"-0\tforces HTTP 1.0 version instead of default 1.1\n\n" \
	"-v\tverbose mode, show entire requests and responses\n"
	exit
}

declare -a methods
http_ver=1.1
headers=
verbose=false

while [ "$1" != "" ]; do
	case $1 in
		-0) http_ver=1.0 ;;
		-1) ;;
		-v) verbose=true ;;
		--head)     methods[${#methods[*]}]=HEAD ;;
		--trace)    methods[${#methods[*]}]=TRACE ;;
		--options)  methods[${#methods[*]}]=OPTIONS ;;
		--put)      methods[${#methods[*]}]=PUT ;;
		--delete)   methods[${#methods[*]}]=DELETE ;;
		--connect)  methods[${#methods[*]}]=CONNECT ;;
		--get)      methods[${#methods[*]}]=GET ;;
		--get-range)
			methods[${#methods[*]}]=GET
			headers="\nRange: bytes=0-0"
			;;
		--post)     methods[${#methods[*]}]=POST ;;
		--patch)     methods[${#methods[*]}]=PATCH ;;
		*) host=$1 ;;
	esac
	shift
done

[ -z $host ] && usage

[ ${#methods} -eq 0 ] && \
methods=( HEAD TRACE OPTIONS PUT DELETE CONNECT GET POST PATCH )

for i in ${methods[*]}; do
	req="$i / HTTP/$http_ver\nHost: $host\nUser-Agent: $me$headers\n\n"
	res=$(echo -e "$req" | nc -w 1 $host 80)

	if $verbose; then
		echo -e "$req$res"
	else
		echo -ne "$i : "
		echo "$res" | grep -Eo "HTTP/1\.[01] [0-9]{3} "
	fi
done