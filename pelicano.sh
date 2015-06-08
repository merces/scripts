#!/bin/bash
#
#   pelicano.sh - gather live Linux system information
#   
#   Copyright (C) 2012 Fernando Mercês
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
#

# TODO
# - gerar html se o nome do relatorio for .html
# - separar comandos por categoria
# - fazer versão para windows
# - arquivos abertos e mapas de memória por processo (talvez um .html para cada processo)

if [ $EUID -ne 0 ]; then
	read -n 1 -p 'WARNING: running without root permissions. Continue (y/N)? ' answer
	[ "$answer" = 'y' ] || exit 1
fi

(for i in \
"date" \
"id" \
"uname -a" \
"dmidecode" \
"ip a" \
"ip r" \
"ip r s cached" \
"ip n" \
"ss -putan" \
"ps aux" \
"ps -ef" \
"env" \
"set" \
"w" \
"who -a" \
"lastlog" \
"dmesg" \
"lsmod" \
"mount" \
"fdisk -l" \
"cat /proc/cpuinfo" \
"free -m" \
"df -h" \
"cat /proc/version" \
"uptime" \
"cat /proc/interrupts" \
"cat /etc/issue" \
"cat /proc/cmdline" \
"iptables -t filter -S" \
"iptables -t nat -S" \
"iptables -t mangle -S" \
"iptables -t raw -S" \
"iptables -t security -S" \
"hostname" \
"lspci" \
"lsusb"  \
"lsof"
do
	echo -e "$i\n-----------------------------------"
	eval $i 2> /dev/null || echo ERROR
	echo
done)
