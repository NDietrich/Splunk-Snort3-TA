#!/bin/bash

# This script will iterate over all snort 3 json alert files in the local directory and
# modify the unixtime for each result to occur in the recent past.

# This script is to help modify input files for splunk to make testing easier
# (events with randomized recent timestamps makes searching easier)

# each input file will cover the range of one hour, starting from the curren time and
# working backwards.  New output files will be created with the unixtime (moving back
# by hour increments).


# get the current epochtime
currentTime=$(date +%s)


# list all input files that contain snort 3 json alerts
FILES="*alert_json.txt*"

# interate over each input file. on output: The first file will cover the time range from now to
# 60 minutes ago. The second file will cover the time range from 60 minutes to 120 mintues
# ago, and so on.
for f in $FILES; do
	echo input file is $f, and output filename is alert_json.txt.$currentTime

	# iterate over each line in the file (each event)
	while IFS= read -r line; do
		# get random time in past hour 
		rnd=$RANDOM
		let "rnd %= 3600";
		randTime=$(( $rnd + $currentTime - 3600 ))

		# modify event in-place with new time
    	echo "$line" | sed "s/[0-9]\{1\},\|[0-9]\{10\},/$randTime,/" >> alert_json.txt.$currentTime
    	
    done < "$f"

	# sort the file in-place
	sort -o alert_json.txt.$currentTime alert_json.txt.$currentTime

	# change $currentTime back 1 hour for next iteration
	currentTime=$(( $currentTime - 3600))

done

