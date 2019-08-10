Overview
###################################

You must configure Snort 3 to output alerts in JSON format using the alert_json output plugin for this TA to work.  There are two components to doing this right, 1) enabling the alert_json plugin correctly in your snort.lua configuration file, and 2) ensuring that you are using the correct flags when running Snort 3 in order to generate the JSON files correctly.

This guide assumes you have Snort 3 installed and working correctly (if you can run **sudo snort -V** without any errors, you should be good).  This guide is platform-agnostic, as configuring the alert_json output plugin should be the same on any platform that Snort 3 can be run on.



Configuring the alert_json Output Plugin 
#########################################################################
You first need to locate the **snort.lua** configuration file. This file is traditionally installed at /usr/local/etc/snort/snort.lua, although you will need to verify this location.

Once you have located this file, you will need to edit it (usually with elevated privileges using sudo or su) to enable the **alert_json** plugin.  You will want to scroll down to the section of this file where the output plugins are located, often around line 262.  You will want to verify that the following section exists (or add it):
```
alert_json =
{
    file = true,

    limit = 100,

    fields = 'seconds timestamp action class b64_data dir dst_addr \
    dst_ap dst_port eth_dst eth_len eth_src eth_type gid icmp_code \
    icmp_id icmp_seq icmp_type iface ip_id ip_len msg mpls pkt_gen \
    pkt_len pkt_num priority proto rev rule service sid src_addr \
    src_ap src_port target tcp_ack tcp_flags tcp_len tcp_seq \
    tcp_win tos ttl udp_len vlan',
}
```
We are setting three fields here:

1. **File:**  This enables output to a file rather than to the screen.  This must be *true**.

2. **Limit:** This number determines when Snort will stop writing alerts to a json file, and roll over to a new file.  100 MB is a good staring number, but you may want to increase this number depending on how you want to handle log rotation.

3. **Fields:**: This lists all the fields that Snort will print for each alert that is generated. In the example above we have specified every possible field.

You can probably remove a few of these fields if your internal testing indicates that you don't need them, such as the *mpls* or *vlan* fields.  The *timestamp* field can be removed since it's essentially a duplicate of the *seconds* field.  

The *b64_data* field holds the packet payload in Base-64 format and increases the size of each alert by 25% to 35%. If you're concerned about your license usage, you could consider removing these fields, although this field can contain a lot of useful information when investigating alerts.

A few things to note:
- All indents are made up of four spaces (not tabs).
- Lines that continue onto the next line have a backslash without any spaces after them.
- Make sure each line ends with a comma.

After modifying this file, you should test that Snort can properly read it and check it for problems:
```bash
snort -c /usr/local/etc/snort/snort.lua
```
make sure you see *Snort successfully validated the configuration.* before you continue to the next section.


Running Snort 3 with the correct flags
#########################################################################
After ensuring that you have configured the alert_json plugin properly in your snort.lua, you need to run Snort 3 with the correct flags to ensure the logs are output correctly with the right permissions. You can run Snort from the command line or from a startup script, but the flags you start Snort with will be the same.

At a Minimum, your snort will need the following flags:
-------------------------------------------------------------------------------
Flag                                Description
---------------------------------   -------------------------------------------
−c /usr/local/etc/snort/snort.lua   The path to the configuration file (the snort.lua file you added the alert_json configuration to).  Change this path to match whatever you did above.

−l /var/log/snort                   The path to the directory where you want Snort to write the log files. If you are running snort with non-elevated credentials (recommended), make sure that user has the ability to write to that folder.  You will use this file path when configuring the TA to read these log files.

−D                                  Run snort as a Daemon (if in a script)

−i eth0                             The interface to listen on. change to match your interface.

−m 0x1b                             This sets the umask for the log files created by snort to 033, so that the files can be read by the Splunk user.

-------------------------------------------------------------------------------

There are numerous other flags you may want to use, but that will depend on your installation. For example, I recommend the following command when running snort as a Daemon:
```bash
/usr/local/bin/snort −c /usr/local/etc/snort/snort.lua −s 65535 −k none \
    −l /var/log/snort −D −u snort −g snort −i ens160 −m 0x1b
```
You can get a full explanation of this installation by looking at the install guides on my website: [SublimeRobots.com](https://SublimeRobots.com)



Check your output
#########################################################################
Run snort and verify that you have log files being generated in your log directory identified above.  For example:
```
noah@snort3:~$ ls -lh /var/log/snort
total 100M
-rwxr--r-- 1 root root 10M Dec 11 16:36 alert_json.txt.1544564202
-rwxr--r-- 1 root root 10M Dec 11 16:37 alert_json.txt.1544564272
-rwxr--r-- 1 root root 10M Dec 11 16:38 alert_json.txt.1544564301
-rwxr--r-- 1 root root 10M Dec 11 16:38 alert_json.txt.1544564305
-rwxr--r-- 1 root root 10M Dec 11 16:38 alert_json.txt.1544564309
-rwxr--r-- 1 root root 10M Dec 11 16:39 alert_json.txt.1544564344
-rwxr--r-- 1 root root 10M Dec 11 16:39 alert_json.txt.1544564351
-rwxr--r-- 1 root root 10M Dec 11 16:39 alert_json.txt.1544564393
-rwxr--r-- 1 root root 10M Dec 11 16:40 alert_json.txt.1544564426
-rwxr--r-- 1 root root 10M Dec 11 16:41 alert_json.txt.1544564481
```

Here you see that everyone has read rights to the files (so Splunk can read these files), and the **limit** option is set to 10 MB. Each file is created with the current unixtime.