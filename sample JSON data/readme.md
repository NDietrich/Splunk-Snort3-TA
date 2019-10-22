# Sample Data for Testing

This folder contains sample files for testing this Splunk TA. The sample files contain Snort 3 alerts in json format.

The **update_epochtime.sh** script can be use to update the unixtime timestamps in the sample files to current, randomized times. Just execute the script in the current directory, and you will get a second set of alert_json.txt.nnnnnnnnnn files. The unixtime on each file will be the current time, and then each additional file will be 1 hour previous. each file will contain events from the unitxime in the filename, and going backwords 1 hour.

if you have three input files 
- alert_json.txt.0000000001
- alert_json.txt.0000000002
- alert_json.txt.0000000003

and you run this script at unxitime 1000007200, you will get three new files:
- alert_json.txt.1000007200
- alert_json.txt.1000003600
- alert_json.txt.1000000000

the first file(1000007200) will contain events occuring within the past hour. The second file will contain events occuring between 1 hour and 2 hours ago (the timestamp on this file is from 1 hour ago). the third file (0000000000) will contain events occuring between 2 hours and 3 hours ago.

The original files will not be altered.