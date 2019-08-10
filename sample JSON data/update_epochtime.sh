#!/bin/bash

epochtime=$(date +%s)
filetime=$epochtime


FILES="*alert_json.txt*"
# echo "$FILES"

for f in $FILES; do
	echo input file is $f, and output filename is alert_json.txt.$filetime
	while IFS= read -r line; do
    	echo "$line" | sed "s/[0-9]\{1\},\|[0-9]\{10\},/$epochtime,/" >> alert_json.txt.$filetime
    	epochtime=$(( epochtime - 1 ))
    done < "$f"
    filetime=$(( filetime - 1 ))
done
