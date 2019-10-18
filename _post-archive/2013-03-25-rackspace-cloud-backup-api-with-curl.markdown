---
layout: post
title: Rackspace Cloud Backup API with cURL
date: '2013-04-01 08:00'
comments: true
author: Oz Akan
categories: []
---

> **WARNING:** this blog post contains information that is not up to date. Consult [this](https://docs.rackspace.com/rcbu/api/v1.0/rcbu-getting-started/content/createWorkWithBackups-d1e01.html) guide for authoritative and up to date information.

Insurance can help to manage risks of relatively rare but expensive events that you will be responsible for covering. Still, insurance doesn't eliminate the risks of unlikely events from happening; instead it provides a mechanism to get out of that event with minimal loss.
 
If you swap the word "insurance" with "backup" in the paragraph above it still makes sense. With insurance, you would like to make the smallest investment but still be covered for any possible event. Cloud Backup does just that - no tapes, no rotation, no physical requirements. Just a few calls and with little effort you are covered.
 
Rackspace has a powerful, easy-to-use service called [Cloud Backup](https://www.rackspace.com/cloud/backup/) which can back up [Cloud Servers](https://www.rackspace.com/cloud/servers/) at file level. It supports encryption, compression and de-duplication, which are important for data security at rest and cost control. For more information, take a look at [Cloud Backup:FAQs](https://www.rackspace.com/knowledge_center/product-faq/cloud-backup)

<!-- more --> 

Here, I will go over a number of calls to configure a backup, run it manually and restore to a different location. 
 
## Terminology
 
* Agent: It is the application that is installed on the server. It knows how to perform backups and restores.
* Backup: Group of folders and/or files stored on Cloud Backup for a particular server and configuration
* Backup Configuration: A definition about what is going to be backed up and when.
* Restore: It is a process of bringing your system back to a previously saved state.
* Restore Configuration: A definition about what is going to be restored and where.
 
## Get Authentication Token
 
To be able to talk to Cloud Backup API, the very first thing to do is get a token from the authentication service. We need two pieces of information: a username and an api-key. You can find these on [mycloud.rackspace.com](https://mycloud.rackspace.com), under your account name, under API Keys link.
 
On my Linux server, I set these as variables (I changed actual values);
 
    $ USERNAME=myusername
    $ APIKEY=my-long-api-key
    $ echo $USERNAME
    myusername
    $ echo $APIKEY
    my-long-api-key
 
Now I can get the Auth Token;
 
    $ curl -s -I -H "X-Auth-Key: $APIKEY" -H "X-Auth-User: $USERNAME" https://auth.api.rackspacecloud.com/v1.0 | grep "X-Auth-Token:" | awk {'print $2'}
 
It is better to assign it to a variable so I can use in the following calls;
 
    $ TOKEN=`curl -s -I -H "X-Auth-Key: $APIKEY" -H "X-Auth-User: $USERNAME" https://auth.api.rackspacecloud.com/v1.0 | grep "X-Auth-Token:" | awk {'print $2'}`
    $ echo $TOKEN
    791b478f-3ab1-5ab2-816b-ba204a70d7fc
 
## A Real Life Scenario
 
The agent is an important piece of the equation in Cloud Backup. I have to install the agent on all servers that I want to backup. This is an easy process documented on my cloud control panel and can be easily automated. Once I have my agent installed on one or many servers, I can use the web interface to configure my backups or use the RESTful API.
 
Assuming that I initially know nothing about the environment, to do anything with the backups, I will need to list my agents. When I have them listed, I will choose the one I want to work with. I will create a backup configuration where I will define what I want to backup, when and how often. I can also list my current backup configurations and modify them. I can check if my previous backup jobs ran properly and what the errors were if they did not.
 
Let’s go over these steps and a few others that will be useful in the pursuit of happiness, I mean, automation.
   
## List All Agents
 
I am listing all agents to choose the one I want to work on.
 
    $ curl -s -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/user/agents | python -m json.tool | grep 'MachineAgentId\|MachineName'
    "MachineAgentId": 157512,
    "MachineName": "dev02",
 
## Check If Agent Is Online
 
I want to work on dev02 so I will set its machine id as a variable;
 
    $ AGENTID=157512; echo $AGENTID
    157512
 
Now let’s check if the agent is online. If it is not online, it won't run backup jobs.
 
    $ curl -s -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/agent/$AGENTID | python -m json.tool | grep Status
    "Status": "Online",
 
## List Current Backup Configurations
 
I am listing backup configurations for dev02 server:
 
    $ curl -s -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup-configuration/system/$AGENTID | python -m json.tool
    []
 
It appears that I don't have any backup configurations yet. Let’s create one.
 
## Create Backup Configuration
 
This part is a bit tricky as it requires a json with quite a few values to be posted. Basically, I give a name to my backup configuration, set some important values that define where, how and when this backup job will run. Have a careful look at inclusions and exclusions sections:
 
    $ curl -s -X POST -d '{
       "MachineAgentId": '$AGENTID',
       "BackupConfigurationName": "Home Folder Daily Backup",
       "IsActive": true,
       "VersionRetention": 30,
       "MissedBackupActionId": 1,
       "Frequency": "Daily",
       "StartTimeHour": 7,
       "StartTimeMinute": 30,
       "StartTimeAmPm": "PM",
       "DayOfWeekId": null,
       "HourInterval": null,
       "TimeZoneId": "Eastern Standard Time",
       "NotifyRecipients": "test@my-email-address.com",
       "NotifySuccess": true,
       "NotifyFailure": true,
       "Inclusions": [
           {
             "FilePath": "/home",
             "FileItemType": "Folder"
           }
       ],
       "Exclusions": [
           {
             "FilePath": "/home/test", 
             "FileItemType": "Folder"
           }
       ]
    }' -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup-configuration | python -m json.tool
 
Response from Cloud Backup which indicates that request was successfully processed:
 
    {
    "BackupConfigurationId": 29831,
    "BackupConfigurationName": "Home Folder Daily Backup",
    "BackupConfigurationScheduleId": 29727,
    "DayOfWeekId": null,
    "Exclusions": [
        {
            "FileId": 83064,
            "FileItemType": "Folder",
            "FilePath": "/home/test",
            "Filter": "Exclude",
            "ParentId": 29831
        }
    ],
    "Flavor": "RaxCloudServer",
    "Frequency": "Daily",
    "HourInterval": null,
    "Inclusions": [
        {
            "FileId": 83063,
            "FileItemType": "Folder",
            "FilePath": "/home",
            "Filter": "Include",
            "ParentId": 29831
        }
    ],
    "IsActive": true,
    "IsDeleted": false,
    "IsEncrypted": false,
    "LastRunBackupReportId": null,
    "LastRunTime": null,
    "MachineAgentId": 157512,
    "MachineName": "dev02",
    "MissedBackupActionId": 1,
    "NextScheduledRunTime": "/Date(1363735800000)/",
    "NotifyFailure": true,
    "NotifyRecipients": "test@my-email-address.com",
    "NotifySuccess": true,
    "StartTimeAmPm": "PM",
    "StartTimeHour": 11,
    "StartTimeMinute": 30,
    "TimeZoneId": "Eastern Standard Time",
    "VersionRetention": 30
    }
 
I can programmatically create many configuration files like this with small changes for each server I will create.
 
 
## List All Backup Configurations For The Agent
 
I am listing all backup configurations for my agent to double check that my configuration is there:
 
    $ curl -s -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup-configuration/system/$AGENTID | python -m json.tool
 
This will give a similar output to the previous one. I will use *BackupConfigurationId* to update the configuration.
 
## Update The Configuration
 
Actually, I decided to schedule the backup one hour later, so let’s update the configuration. I will also add "v2" to the configuration name. I will send pretty much the same json content as I did the first time while creating the configuration except I will change *StartTimeHour* and *BackupConfigurationName*:
 
    $ curl -i -X PUT -d '{
       "MachineAgentId": '$AGENTID',
       "BackupConfigurationName": "Home Daily Backup v2",
       "IsActive": true,
       "VersionRetention": 30,
       "MissedBackupActionId": 1,
       "Frequency": "Daily",
       "StartTimeHour": 9,
       "StartTimeMinute": 30,
       "StartTimeAmPm": "PM",
       "DayOfWeekId": null,
       "HourInterval": null,
       "TimeZoneId": "Eastern Standard Time",
       "NotifyRecipients": "test@my-email-address.com",
       "NotifySuccess": true,
       "NotifyFailure": true,
       "Inclusions": [
           {
             "FilePath": "/home",
             "FileItemType": "Folder"
           }
       ],
       "Exclusions": [
           {
             "FilePath": "/home/test", 
             "FileItemType": "Folder"
           }
       ]
    }' -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup-configuration/29831
 
As seen above, the very last value we have in the url is the *BackupConfigurationId*
 
Let’s check if configuration is really updated:
 
    $ curl -s -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup-configuration/29831 | python -m json.tool|grep BackupConfigurationName
    "BackupConfigurationName": "Home Daily Backup v2",
 
## Start A Backup Manually
 
If I don't do anything, Cloud Backup will run the backup at the scheduled time. Still, I would like to run it at least once to be sure that it will run without errors. I am using *BackupConfigurationId* to indicate which configuration I want to run.
 
    $ curl -i -X POST -d '{
       "Action" : "StartManual",
       "Id": 29831
      }' -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup/action-requested
 
This is the response from the server; the number at the end of the response is the id of the job I ran:
 
    HTTP/1.1 200 OK
    .. skipping some lines
    Date: Tue, 19 Mar 2013 22:10:38 GMT
 
    2436516
 
As soon as backup is done, I will receive an e-mail about the status, as seen below:
 
    Rackspace Cloud Backup
    Backed Up: Home Daily Backup v2 on dev02
    Status: Completed
    Started: 19 Mar 2013 22:08 UTC
    Completed: 19 Mar 2013 22:08 UTC
    Source: dev02
    Files Searched: 14 (9 KB)
    Errors Encountered: 0
 
I can run the same backup configuration several times, which will result in several backups. I can choose any one of these to restore later on.
 
## Checking Backup Status
 
Backup runs fast, though depending on the folder size it might take a while, so it is handy to be able to check status:
 
     $ curl -s -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup/2436516|python -m json.tool
 
Response from Cloud Backup:
 
     {
     "BackupConfigurationId": 29831,
     "BackupConfigurationName": "Home Daily Backup v2",
     "BackupId": 2436516,
     "CurrentState": "Completed",
     "EncryptionKey": {
         "ExponentHex": 10001,
         "ModulusHex": "D135386925ECB8706D458709AECAEA759C95CFC5DA5BF4FA8FFE53168346
     },
     "IsEncrypted": false,
     "MachineAgentId": 157512,
     "MachineName": "dev02",
     "StateChangeTime": "/Date(1363731050000)/"
     }
 
As seen from the output it has already been completed. If I run this check fast enough I would see it in progress.
 
## List All Completed Backups For An Agent
 
I can also display all the activities for an agent so I can find if my backups ran successfully or failed. This is useful if I don't set e-mail notifications and want to create a report about state of previous backups.
 
    $ curl -s -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/system/activity/$AGENTID | python -m json.tool
 
Response from Cloud Backup:
 
    [
    {
        "CurrentState": "Completed",
        "DestinationMachineAgentId": 0,
        "DestinationMachineName": "",
        "DisplayName": "Home Daily Backup v2",
        "ID": 2437160,
        "IsBackupConfigurationDeleted": false,
        "ParentId": 29831,
        "SourceMachineAgentId": 157512,
        "SourceMachineName": "dev02",
        "TimeOfActivity": "/Date(1363735732000)/",
        "Type": "Backup"
    },
    {
        "CurrentState": "Completed",
        "DestinationMachineAgentId": 0,
        "DestinationMachineName": "",
        "DisplayName": "Home Daily Backup v2",
        "ID": 2436516,
        "IsBackupConfigurationDeleted": false,
        "ParentId": 29831,
        "SourceMachineAgentId": 157512,
        "SourceMachineName": "dev02",
        "TimeOfActivity": "/Date(1363731050000)/",
        "Type": "Backup"
    },
    {
        "CurrentState": "Completed",
        "DestinationMachineAgentId": 0,
        "DestinationMachineName": "",
        "DisplayName": "Home Daily Backup v2",
        "ID": 2436492,
        "IsBackupConfigurationDeleted": false,
        "ParentId": 29831,
        "SourceMachineAgentId": 157512,
        "SourceMachineName": "dev02",
        "TimeOfActivity": "/Date(1363730828000)/",
        "Type": "Backup"
    }
    ]
 
## Create Restore Configuration
 
Now I have the backup, so let’s try to restore it to a different location on my server. I can even restore to a different server, or to the same folder on the same server. This is achieved by setting *BackupMachineId*, *DestinationMachineId* and *DestinationPath* values properly. *BackupId* identifies which backup I want to restore. 
 
    $ curl -s -X PUT -d '{
    "BackupId": 2437160,
    "BackupMachineId": 157512,
    "DestinationMachineId": 157512,
    "DestinationPath": "/tmp/restored",
    "OverwriteFiles": false
    }' -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/restore | python -m json.tool
 
Response from Cloud Backup:
 
    {
    "BackupConfigurationId": 29831,
    "BackupConfigurationName": "Home Daily Backup v2",
    "BackupFlavor": "RaxCloudServer",
    "BackupId": 2437160,
    "BackupMachineId": 157512,
    "BackupMachineName": "dev02",
    "BackupRestorePoint": "/Date(1363735801000)/",
    "DestinationMachineId": 157512,
    "DestinationMachineName": "dev02",
    "DestinationPath": "/tmp/restored",
    "EncryptedPassword": null,
    "IsEncrypted": false,
    "OverwriteFiles": false,
    "PublicKey": {
        "ExponentHex": 10001,
        "ModulusHex": "D135386925ECB8706D458709AECAEA759C95CF..."
    },
    "RestoreId": 4939,
    "RestoreStateId": 0
    }
 
## Restore A Backup
 
I will run a restore based on a restore configuration. I use the *RestoreId* that was returned in the previous output.
 
    $ curl -s -X POST -d '{ 
      "Action": "StartManual", 
      "Id": 4939
     }' -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN"  https://backup.api.rackspacecloud.com/v1.0/restore/action-requested
 
I get this e-mail after restore was completed:
 
    Rackspace Cloud Backup
    Status: Completed
    Started: 20 Mar 2013 14:40 UTC
    Completed: 20 Mar 2013 14:40 UTC
    Destination: /tmp/restored
    Files Restored: 14 (318 bytes)
    Errors Encountered: 0
 
 
## Get Restore Report
 
Let’s check if my restore ran successfully.
 
    $ curl -s -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/restore/report/4939| python -m json.tool
    {
    "BackupConfigurationId": 29831,
    "BackupConfigurationName": "Home Daily Backup v2",
    "BackupReportId": 2437160,
    "CompletedTime": "/Date(1363790404000)/",
    "Diagnostics": "No errors",
    "Duration": "00:00:00",
    "ErrorList": [],
    "NumBytesRestored": "318 bytes",
    "NumErrors": "0",
    "NumFilesRestored": "14",
    "OriginatingComputerName": "dev02",
    "Reason": "Success",
    "RestoreDestination": "dev02",
    "RestoreDestinationMachineId": 157512,
    "RestorePoint": "/Date(1363735801000)/",
    "StartTime": "/Date(1363790404000)/",
    "State": "Completed"
    }
 
Cloud Backup reports success, still I would like to see it on my server. Below are the folder listings on my server:
 
    $ ls -l /home/
    drwx------ 2 myuser   myuser   4096 Mar 19 15:37 myuser
    drwx------ 2 test     test     4096 Mar 18 21:43 test
    
    $ ls -l /tmp/restored/home
    drwx------ 2 myuser   myuser   4096 Mar 19 15:37 myuser
 
When I check my server, I see the *test* folder was ignored from the backup as indicated in the backup configuration, and only the *myuser* folder was backed up and restored as I had indicted in the configuration file.
 
## Delete Backup Configuration
 
For the sake of this demonstration, I will delete the backup configuration file and then verify if it was really removed:
 
    $ curl -i -X DELETE -H "X-Auth-Token: $TOKEN"  https://backup.api.rackspacecloud.com/v1.0/backup-configuration/29831 
 
Let’s see if it is marked as deleted (In the output, I just left the lines that we need):
 
    $ curl -s -H "X-Auth-Token: $TOKEN" https://backup.api.rackspacecloud.com/v1.0/backup-configuration/29831 | python -m json.tool
    {
    "BackupConfigurationId": 29831,
    "BackupConfigurationName": "Home Daily Backup v2",
    .....
    "IsDeleted": true,
    ....
    }
  
## Conclusion
 
Using the Cloud Backup RESTful API, it is now easy to automate backup jobs while provisioning new servers. Merged into a Chef cookbook or in any other automation system, backups are a part of the deployment as opposed to something to be considered later or handled separately as the media and the knowledge used to be much different than what everything else was running on. 
 
_If you have questions you can find me at [Twitter](https://twitter.com/ozgurakan) or at [Google Plus](https://plus.google.com/110684487860941982359/posts)_
 
For more information on the Rackspace Cloud Backup API, refer to our [API documentation](https://docs.rackspace.com/rcbu/api/v1.0/rcbu-devguide/content/index.html).
