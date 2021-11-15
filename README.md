# lsi_check
Script for monitoring storage on LSI raid controllers.

## Overview:
* The script connects to the server via ssh and communicates with the disks controller via storcli.
* Duplicates the output of the storage logs to the mail.
* Ability to enable sending notifications only when the raid array is in bad condition.

### Example script output logs:
```
[07:00:01]: --- 27-10-2021 - START: 172.16.10.5 ---
[07:00:04]: [+] Condition [RAID10], virtual drive [1/0], name [ssd-raid] - Good!
[07:00:04]: [+] Condition [RAID10], virtual drive [0/1], name [hdd-raid] - Good!
[07:00:06]: --- 27-10-2021 - END: 172.16.10.5 ---
```

## How-to:
Create separate accounts for interacting with storcli via ssh.
```
Sample storcli commands:
 - Drive Information:
./storcli /c0 /eall /sall show
 - Detailed Information:
./storcli /c0 /eall /sall show all
 - Info controller + TOPOLOGY + Virtual Drives + Physical Drives
./storcli /c0 show
 - Virtual Drives:
./storcli /c0 /vall show

./lsi_check.sh '1/0 0/1' 2|n esxi|linux ip login 'pass'
```
