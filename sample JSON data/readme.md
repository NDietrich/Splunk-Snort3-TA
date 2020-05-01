# Sample Data for Testing

This folder contains sample files for testing this Splunk TA. The sample files contain Snort 3 alerts in json format.

There are two scripts here that can help you generate new sample files from current sample files for testing Splunk. The older file is **update_epochtime.sh**, a bash script that creates new alert files similar to the current files you have. The more advanced script is **new-snort3JsonAlertsForSplunk.ps1** and has a lot more features compared to the bash script. This PowerShell script has been tested on both windows and on Linux, and is recomended over the bash script.

## PowerShell Script
This script will take all snort 3 alert files in json format in a directory, and will output a single file of those same alerts, with events randomly spread out across the past 24 hours. You can choose to modify the alerts in the output file to have random source IP addresses, delete the source files, and provide a list of GID:SID:REV rules not to include in the output file.  See the help and examples included with the file.

This script has been tested with PowerShell 5.1 on Windows 10, and PowerShell 7.0.0 on Unbuntu.

## Batch file
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
