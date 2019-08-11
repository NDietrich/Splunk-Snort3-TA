# Overview

This repository is a Technology Add-On (known as a TA) for Splunk that allows you to injest IDS alerts into Splunk from Snort 3 in JSON format.  This plugin normalizes these alerts conform to the "Network Intrusion Detection" model in the Splunk Common Information Model (CIM), and can be accesed within any app or dashboard that reports Intrustion Detection events (such as Splunk's Enterprise Security).

This TA is released under the GPL v3 license. Please see the [LICENSE](./TA_Snort3_json/LICENSE) file.

This TA can be installed directly from [SplunkBase](https://splunkbase.splunk.com/), or you can use this repository to modify and create a stand-alone version of this TA, or [download the TA](https://github.com/NDietrich/Splunk-Snort3-TA/releases) and install manually. You only need to use this repository if you want to modify the TA yourself, or if you don't want to download the plugin from Splunk directly. In most cases, you should donload this TA directly from [SplunkBase](https://splunkbase.splunk.com/) via your local Splunk instance.

# Important Notes
This TA works with json-formatted logs generated by Snort 3, and will not work with logs generated by Snort 2.  Snort 3 is currently a Beta product. It should not be used in production or misison-cricical enviornments, and has been made avaliable for testing purposes.  Because of this, it is possible that future modifications to Snort 3 will break this plugin. This plugin has been released before the final version of Snort 3 has been finalized to solicit feedback, including feature requests and bug reports.

# Installing This Plugin
1. Ensure that you have installed Snort 3, and it is correctly outputing alerts in JSON format.  Please see the [Snort website](https://snort.org/documents) for installation guides (make sure to install Snort 3 instead of Snort 2).  If you are unsure what platform to install Snort on (Linux, Windows, BSD), choose the platform you are most comfortable using.  I have authoried some in-depth installation guides for Ubuntu, avaliable on Snort's website, or alternately avaliable at http://SublimeRobots.com/.

2. In your json output files, make sure that the 'seconds' field is the very first field output for each alert.  The *alert_json* plugin is configured in the *snort.lua* file.  In the example below, you can see the following settings:
- *fields:*  The 'seconds' field is the first field listed (and thus the first field in the output).  The example here is also choosing to output every possible field.  You can probably remove some of these fields after testing to determine if they are necessary, such as the vlan or mpls fields.
- *file:*  We are outputing to a file (the alert_json.txt.nnnnnnnnnn file).
- *limit:*  Each json file will be 100 MB before it rolls over to a new file.

```
--- in your snort.lua file
alert_json =
{
    fields = 'seconds timestamp action class b64_data dir dst_addr dst_ap dst_port eth_dst eth_len eth_src eth_type gid icmp_code icmp_id icmp_seq icmp_type iface ip_id ip_len msg mpls pkt_gen pkt_len pkt_num priority proto rev rule service sid src_addr src_ap src_port target tcp_ack tcp_flags tcp_len tcp_seq tcp_win tos ttl udp_len vlan',
    file = true,
    limit = 100,
}
```
3. Install this plugin (TA_Snort3_json) onto all Splunk servers in your infrastructure.  For Servers, use the web-interface to install the plugin through the 'app' menu. For forwarders, you can use a deployment server, use the CLI, or copy the .spl file to $SPLUNK_HOME/etc/apps/.  Splunk's [deployment manual](https://docs.splunk.com/Documentation/AddOns/released/Overview/Distributedinstall).

4. Configuration:  You only need to configure this TA on any Splunk system where you will be collecting log files; Either on a single server (for a stand-alone installation), or where the Splunk Universal Forwarder (UF) is installed.  You need to configure the TA to identify the location your Snort 3 json log files.  Create the following file:
    `$SPLUNK_HOME/etc/apps/TA_Snort3_json/local/inputs.conf` 
that has the following content:
```
[monitor:///var/log/snort/*alert_json.txt*]
sourcetype = snort3:alert:json
```
Adjust the path above to point to the folder that stores the alert_json* log files that snort created.  In this example, the logs are stored in the the */var/log/snort* folder.  Restart Splunk only on the server where you modified this file (there is no need to restart Splunk on any of the other servers after installing the TA).

5. Advanced configuration options:  By default, this TA will search sub-directories of the directory specified above, and events are written to the 'main' index. If you need to to change these settings, modify the file you created above (`local/inputs.conf`) and modify it similaryly to the following:
```
[monitor:///var/log/snort/*alert_json.txt*]
sourcetype = snort3:alert:json
index = another-index-name
recursive = false
```

# Modifying this TA
If you want to make modifications to a git-clone of this repository, you can use the makefile located in the root of this repo to generate your own .spl file (the TA archived into a single file).
This makefile has a few different options:

- *clean:* Remove all temp working directories and created .spl files 
- *spl*: Default option. creates the .spl file in this directory, ready for submission to splunkbase.
- *install:* Same as above, but then extract the TA to the location specified by the APPDIR variable. (install this TA on your local splunk server for testing). Reboot splunk server first.      
- *local-spl:* Same as SPL, but don't reomve the contents of the 'local' folder. For internal testing.
- *local-install:* Same as 'install', but doesn't remove the contents of the 'local' folder, for testing.

To verify the TA .spl file is valid, you can use Splunk's [AppInspect](http://dev.splunk.com/view/appinspect/SP-CAAAFAM) tool.  

Once you've created the spl file, you can upload it to your Splunk Server through the [web interface](https://docs.splunk.com/Documentation/AddOns/released/Overview/Singleserverinstall), through your deployment server (if using), through the [CLI](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Managingappobjects#Update_an_app_or_add-on_in_the_CLI), or by just copying the .spl file into the app directory on your server ($SPLUNK_HOME/etc/apps/).  This last option is how the 'install' and 'local-install' MAKE targets work.  An overview of deployment options is [avaliable](https://docs.splunk.com/Documentation/Splunk/7.2.1/Admin/Deployappsandadd-ons).

# Requesting Help
Please submit bug and feature requests via Github for this project, or email Noah@SublimeRobots.com.  Please include as much information as possible with your request.  This TA is not professionally supported (it is a volunteer project), so issues may not be fixed immediately, but I will make every effort to reply.


