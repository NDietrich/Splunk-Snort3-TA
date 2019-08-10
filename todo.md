This is a list of todo items for this project


# High Priority


# Low Priority
- Create Machine Readable License file 
    https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
- modify update_epochtime script to vary event times unevenl over past 60 min.



# NOTES

# How to install, use, and verify data against the CIM
https://docs.splunk.com/Documentation/CIM/4.13.0/User/UsetheCIMtonormalizedataatsearchtime

https://docs.splunk.com/Documentation/CIM/4.13.0/User/IntrusionDetection

Manual install of Downloading Splunk Common Information Model (CIM):
https://splunkbase.splunk.com/app/1621/
install of Datasets Add-on
https://splunkbase.splunk.com/app/3245/
Search --> datasets
choose 'Intrusion Detection > IDS Attacks > Network Intrusion Detection"
time = all time
click "sumarize fields"

Or via a search:
    | datamodel Intrusion_Detection Network_IDS_Attacks search 
    | search sourcetype="snort3:alert:json" 
    | table * 
    | fieldsummary