#!/bin/bash
#
# esx2usb 1.1
#
# Copyright (C) 2013 Fernando Mercês
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

echo -e \
"\nesx2usb - makes a bootable USB key of an ESXi installation
----------------------------------------------------------\n"

m='/mnt'
mntiso="$m/mntiso"
mntpart="$m/mntpart"
syslnx='syslinux-3.86'
esx=false

verm='\e[0;31m'
verde='\e[0;32m'
amar='\e[0;33m'
def='\e[0m'

function print {
	echo -ne "$1\t\t";
	return 22;
}

function test {
	r=$?
	if [ $r -eq 0 ]; then
		echo -e "$verde[OK]$def"
	elif [ $r -eq 22 ]; then
		echo -e "$amar[SKIPPED]$def"
	else
		echo -e "$verm[FAIL]$def"
		exit 1
	fi
}

function bye {
	echo "$1"
	exit 1
}

function usage {
	echo "usage: $0 <esx_iso> <dst_disk>"
	exit 1
}

function depends {
	if ! which "$1" &> /dev/null; then
		echo "$1 missing. Please install first."
		exit 1
	fi
}

if [ ! -d "$syslnx" ]; then
	echo -e "$syslnx directory is missing. Set the syslnx variable on line 23 and/or
download it from http://www.kernel.org/pub/linux/utils/boot/syslinux/3.xx/
and extract it here.\n"
	exit 1
fi 

[ $UID -eq 0 ] || bye "got root?"
[ $# -eq 2 ] || usage
depends parted

iso="$1"
drive=${2//[0-9]}
part="$drive"1
fs=fat32

umount "$mntiso" 2> /dev/null
umount "$mntpart" 2> /dev/null
umount "$part" 2> /dev/null

osiz=$(parted "$drive" print unit MB | grep "$drive" | cut -d' ' -f3)
aux=$(echo ${osiz//[1-9]/0})
siz=${osiz:0:1}${aux:1}

print "cleaning $drive ($osiz)..."
dd if=/dev/urandom bs=1 count=1 of="$drive" 2> /dev/null
test
(for i in {1..10}; do parted "$drive" rm "$i"; done) > /dev/null

print "creating $part ($siz)..."
parted "$drive" mkpart primary "$fs" 2048s "$siz" > /dev/null
test
parted "$drive" set 1 boot on > /dev/null

print "formatting $part ($fs)..."
mkfs.vfat -F 32 -n boot "$part" > /dev/null
test

print "installing syslinux ${syslnx: -4}..."
chmod +x "$syslnx/linux/syslinux"
"$syslnx/linux/syslinux" "$part"
test

print "writing master boot record..."
cat "$syslnx/mbr/mbr.bin" > "$drive"
test

print "creating mount points..."
mkdir -p "$mntiso" "$mntpart"
test

print "mouting source target..."
mount -o ro,loop "$iso" "$mntiso"
test

print "mouting destination target..."
mount "$part" "$mntpart"
test

print "copying files from iso image..."
cp -r "$mntiso"/* "$mntpart"/
test

print "renaming isolinux.cfg..."
mv "$mntpart/isolinux.cfg" "$mntpart/syslinux.cfg" 2> /dev/null
test

print "patching syslinux.cfg..."
sed -i 's/APPEND -c boot.cfg/APPEND -c boot.cfg -p 1/' "$mntpart/syslinux.cfg"
test

echo -n "waiting synchronization"
sleep 1; echo -n .; sleep 1; echo -n .; sleep 1; echo -ne ".\t\t"
test

print "umounting all targets..."
umount "$mntiso"
umount "$mntpart"
test

print "removing mount points..."
rmdir "$mntiso" "$mntpart"
test

echo done.
