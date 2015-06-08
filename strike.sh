#!/bin/bash

authlog=/var/log/auth.log
outfile=$(hostname)-userlist.txt

[ $EUID -eq 0 ] || echo "Running as non-root user. I assume you have permission to read at $(dirname $authlog)"

if ! grep -qF 'invalid user' $authlog*; then
    echo 'No luck with your logs. Sorry.'
    exit 1
fi

(cat $authlog $authlog.[0-9]; zcat $authlog*gz) 2>/dev/null |
 sed -n 's/^.*invalid user \([a-zA-Z0-9\.\-]*\) .*$/\1/p' |
 sort -u > "$outfile"

echo "$(wc -l $outfile) user names written to $outfile"

# additional check
echo "existent users matches:"
grep -Fxf <(cut -d: -f1 /etc/passwd) "$outfile"
