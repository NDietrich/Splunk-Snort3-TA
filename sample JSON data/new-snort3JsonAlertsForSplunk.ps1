# new-snort3JsonAlertsForSplunk
# this powershell script takes a set of files that contain Snort 3 alerts in json format,
# and outputs a new set of files with randomized sourc IP addresses, and with times spread
# over the past 24 hours.

# timing
# 700 MB of events input -> filtering out 5 types of events (GID 116 mostly), resulted in 40,000 alerts output to a 95mb file in 126 seconds

<#
.SYNOPSIS
Generate modified snort 3 alert files in json format for testing with Splunk
.DESCRIPTION
takes a set of files that contain Snort 3 alerts in json format, and outputs a new set of files with randomized sourc IP addresses, and with times spread over the past 24 hours.  Tested with powershell on windows and Linux.
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
.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder c:\log\snort -outputFolder c:\test
.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder /var/log/snort -rulesToIgnore @("124:1:1", "116:434:1", "124:5:1", "116:424:1", "116:425:1") 
.EXAMPLE
new-snort3JsonAlertsForSplunk -inputFolder /var/log/snort -randomizeSourceIP -remove
.LINK
https://SublimeRobots.com
#>
Function new-snort3JsonAlertsForSplunk {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0,HelpMessage="Enter the folder that contains the snort json alert files")][System.IO.DirectoryInfo]$inputFolder,
        [Parameter(HelpMessage="Enter the folder where the output will be written.")][System.IO.DirectoryInfo]$outputFolder =$inputFolder,
        [Parameter(HelpMessage="Enter an array of strings of rules to omit from the output in GID:SID:REV format")][string[] ]$rulesToIgnore = "",
        [Parameter(HelpMessage="Delete the source json files after sucessfully writing the output file")][switch]$remove = $false,
        [Parameter(HelpMessage="replace source ip addresses with randomized addresses.")][switch]$randomizeSourceIP = $false

    )

    # Load all our snort3 Json alert files
    try { 
        $jsonFiles = get-childItem "$inputFolder$([IO.Path]::DirectorySeparatorChar)*alert_json.txt*"
    
    } catch {
        write-warning "Fatal Error getting snort3 files from $inputFolder"
        return $false
    }



    # get the current GMT  Unixtime
    $currentTime = [int][double]::Parse($(Get-Date -date (Get-Date).ToUniversalTime()-uformat %s))

    # convert our Rules to ignore from an array of strings to a regex
    $regexRulesToRemove = $rulesToIgnore -join "|"

    # make sure our output file doesn't exist already
    $outFile = "$outputFolder$([IO.Path]::DirectorySeparatorChar)alert_json.txt.$currentTime"

    # make sure our outifle doesn't already exist
    if ( test-path "$outfile" ) {
        write-warning "Fatal Error output file already exists: $outFile."
        return $false
    }    

    write-host "-----------------------------------------------"
    write-host "Input Folder is    :        $inputFolder"
    write-host "output Folder is   :        $outputFolder"
    write-host "Rules to Ignore are:        $rulesToIgnore"
    write-host "         as a regex:        $regexRulesToRemove"
    write-host "Remove source files:        $remove"
    write-host "Randomize Source IP:        $randomizeSourceIP"
    write-host
    write-host "current Time (unix):        $currentTime (UTC)"
    write-host "OutFile            :        $outFile"

    Get-Content $jsonFiles |
        # remove any obviously malformed events
        Select-String -Pattern '^{ "seconds" : ' |

        # remove events that match our 'rules to remove' regex
        % {
            if (-not [string]::IsNullOrEmpty($regexRulesToRemove) ) {
                Select-String -InputObject $_ -Pattern $regexRulesToRemove -NotMatch 
            } else {$_}
        } |

        # generate a random time in the past 24 hours
        % { 
            $randTime = Get-Random -Maximum $currentTime -Minimum ($currentTime - (86400 ) )    # 86400 = seconds in 24 hours
            $_ -replace '^{ "seconds" : (\d{10}),' , "{ `"seconds`" : $randTime,"
        } |
        

        # generate a random IP address for the source fields
        # requires that scr_addr be followed by src_ap in the string
        % { 
            if ($randomizeSourceIP) {
                $ip = [IPAddress]::Parse([String] (Get-Random) ).IPAddressToString
                $_  -replace 'src_addr" : "(\b(?:\d{1,3}\.){3}\d{1,3}\b)", "src_ap" : "(\b(?:\d{1,3}\.){3}\d{1,3}\b):', "src_addr`" : `"$IP`", `"src_ap`" : `"$($IP):"
            } else {$_}
        } |
                 
        Sort-Object |
        Set-Content $outfile

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
                Write-Host "cleanup: trying to delete $file"
                Remove-Item $file -Force
            }
        } catch {
            Write-Warning "Error: not able to delte $file, exiting"
            return $false
        }

    }

    Write-Host "Script complete."

}


