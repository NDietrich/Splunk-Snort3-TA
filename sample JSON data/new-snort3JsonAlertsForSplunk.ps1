# new-snort3JsonAlertsForSplunk
# this powershell script takes a set of files that contain Snort 3 alerts in json format,
# and outputs a new set of files with randomized sourc IP addresses, and with times spread
# over the past 24 hours. This script is to help create test files for importing into Splunk


<#
.SYNOPSIS
Generate modified snort 3 alert files in json format for testing with Splunk.
.DESCRIPTION
Takes a set of files that contain Snort 3 alerts in json format, and outputs a new set of files with optionally randomized sourc IP addresses, randomized times spread over the past 24 hours.  
This script is useful if you are testing a SIEM (like Splunk) that inputs Snort 3 alerts in JSON format, and you want to generate a set of different new test data over the past 24 hours (most dashboards are set to this timeframe).

Performance:  With 700 MB of events input, and filtering out 5 types of events (GID 116 mostly), resulted in 40,000 alerts output to a 95mb file in 175 seconds.

Tested with PowerShell 5.1 on windows and PowerShell 7.0.0 Linux.

.PARAMETER inputfolder
Specifies the directory name where the source json files are
.PARAMETER outputFolder
Where the single modified json file will be saved. if not specified will use $inputFolder
.PARAMETER rulestoIgnore
an array of strings that represent rules to omit from the output in GID:SID:REV format.  You can specify a partial rule (GID:SID or just GID) but may omit too many rules.
.PARAMETER remove
delete the input json files after an output file is sucessfully written.
.PARAMETER randomizeSourceIP
generate random ip addresses for the src_ip and src_ap fields in the events.
.INPUTS
inputFolder can be piped in to the input
.OUTPUTS
none. new-snort3JsonAlertsForSplunk will generate a json file in the directory specified as a parameter
or file name.
.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder /var/log/snort 

the output file will be written to the same folder as the input folder.  IP addresses will not be randomized, and source files will not be deleted

.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder c:\log\snort -outputFolder c:\test
save output file to a different location

.EXAMPLE
new-snort3JsonAlertsForSplunk c:\log\snort
The -inputFolder option is default if you don't supply a parameter

.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder /var/log/snort -rulesToIgnore @("124:1:1", "116:434:1", "124:5:1", "116:424:1", "116:425:1") 
save the output file to the same location as the input files.  ignore any rules with the GID:SID:REV in that list.
Note on rulesToIgnore: this match uses a string regex match, so if you wan to ignore all rules starting with GID of 10, you must put "10:" (NOT "10"), otherwise you'll also remove rules witha GID of 100 for example.

.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder /var/log/snort -randomizeSourceIP
Generate random source IP addresses for each event.

.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder /var/log/snort -remove
Delete source files after the output file has been sucesfully written.  Use this carefully

.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder /var/log/snort -outputFolder /tmp -rulesToIgnore @("124:1:1", "116:434:1", "124:5:1", "116:424:1", "116:425:1")  -randomizeSourceIP -remove
All flags enabled.  Input from /var/log/snort, output results to /tmp.  Ignore any alerts that match the rules in teh list, generate random ip addresses for the source field, and delte files from /var/log/snort when complete

.EXAMPLE
get-item /var/log/snort | new-snort3JsonAlertsForSplunk
you can pass $inputFolder via the pipeline. Must be a single folder, not an array, and of type System.IO.DirectoryInfo

.LINK
https://SublimeRobots.com
#>
Function new-snort3JsonAlertsForSplunk {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0,HelpMessage="Enter the folder that contains the snort json alert files")][System.IO.DirectoryInfo]$inputFolder,
        [Parameter(HelpMessage="Enter the folder where the output will be written.")][System.IO.DirectoryInfo]$outputFolder =$inputFolder,
        [Parameter(HelpMessage="Enter an array of strings of rules to omit from the output in GID:SID:REV format")][string[] ]$rulesToIgnore = $null,
        [Parameter(HelpMessage="Delete the source json files after sucessfully writing the output file")][switch]$remove = $false,
        [Parameter(HelpMessage="replace source ip addresses with randomized addresses.")][switch]$randomizeSourceIP = $false

    )

    # verify input and output folders are not arrays 
    if ($inputFolder -is [System.Array]) {
        write-warning "Fatal Error: Input folder must be a single folder, not an array: $inputFolder"
        return
    }

    if ($outputFolder -is [System.Array]) {
        write-warning "Fatal Error: Output folder must be a single folder, not an array: $inputFolder"
        return
    }

    # Load all our snort3 Json alert files
    try { 
        $jsonFiles = get-childItem "$inputFolder$([IO.Path]::DirectorySeparatorChar)*alert_json.txt*" 
    } catch {
        write-warning "Fatal Error getting snort3 files from $inputFolder"
        return 
    }
    if ([System.String]::IsNullOrEmpty($jsonFiles)){
        write-warning "Fatal Error no snort 3 alert_json.txt files found in $inputFolder"
        return 
    }



    # get the current GMT Unixtime
    $currentTime = [int][double]::Parse($(Get-Date -date (Get-Date).ToUniversalTime()-uformat %s))

    # convert our Rules to ignore from an array of strings to a regex
    if (($rulesToIgnore.Count) -gt 0) {
        $regexRulesToRemove = 'rule" : "(' + $($rulesToIgnore -join "|") + ')'
    } 

    # We will output to a single file
    $outFile = "$outputFolder$([IO.Path]::DirectorySeparatorChar)alert_json.txt.$currentTime"

    # make sure our outifle doesn't already exist
    if ( test-path "$outfile" ) {
        write-warning "Fatal Error output file already exists: $outFile."
        return
    }    

    write-host "-----------------------------------------------"
    write-host "Input Folder is    :        $inputFolder"
    write-host "output Folder is   :        $outputFolder"
    write-host "Rules to Ignore are:        $rulesToIgnore"
    write-host "         as a regex:        $regexRulesToRemove"
    write-host "Remove source files:        $remove"
    write-host "Randomize Source IP:        $randomizeSourceIP"
    write-host "current Time (unix):        $currentTime (UTC)"
    write-host "OutFile            :        $outFile"

    Get-Content $jsonFiles |
        # remove any obviously malformed events
        Select-String -Pattern '^{ "seconds" : ' |

        # remove events that match our 'rules to remove' regex
        ForEach-Object {
            if (-not [string]::IsNullOrEmpty($regexRulesToRemove) ) {
                Select-String -InputObject $_ -Pattern $regexRulesToRemove -NotMatch 
            } else {$_}
        } |

        # generate a random time in the past 24 hours
        ForEach-Object { 
            $randTime = Get-Random -Maximum $currentTime -Minimum ($currentTime - (86400 ) )    # 86400 = seconds in 24 hours
            $_ -replace '^{ "seconds" : (\d{10}),' , "{ `"seconds`" : $randTime,"
        } |
        

        # generate a random IP address for the source fields
        # requires that scr_addr be followed by src_ap in the string
        ForEach-Object { 
            if ($randomizeSourceIP) {
                $ip = [IPAddress]::Parse([String] (Get-Random) ).IPAddressToString
                $_  -replace 'src_addr" : "(\b(?:\d{1,3}\.){3}\d{1,3}\b)", "src_ap" : "(\b(?:\d{1,3}\.){3}\d{1,3}\b):', "src_addr`" : `"$IP`", `"src_ap`" : `"$($IP):"
            } else {$_}
        } |
                 
        Sort-Object |
        Set-Content $outfile

    write-host "`nScript Completed writing output file."

    # Cleanup
    if($remove) {
        # check that we've output results
        if (-not ( test-path "$outfile") ) {
            write-warning "Error: Oufile does not exist, not removing source files."
            return $false
        } 

        if ( ((Get-Item $outFile).length) -eq 0){
            write-warning "Error: Oufile has no content, not removing source files."
            return $false
        }

        try { 
            foreach ($file in $jsonFiles) {
                Write-Host "cleanup: trying to delete    $file"
                Remove-Item $file -Force
            }
        } catch {
            Write-Warning "Error: not able to delte $file, exiting"
            return $false
        }
    }

    Write-Host "Script complete."

}

