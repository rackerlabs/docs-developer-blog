---
layout: post
title: "Configure the Azure Diagnostic Extension for Storing Linux Log Files"
date: 2020-07-15 00:00
comments: true
author: Jimmy Rudley
published: true
authorIsRacker: true
authorAvatar: 'https://www.gravatar.com/avatar/fb085c1ba865548f330e7d4995c0bf7e'
bio: "Jimmy Rudley is an Azure&reg; Architect at Rackspace and an active member of the Azure community. He focuses on solving large and complex architecture and automation problems within Azure."
categories:
    - Azure
metaTitle: "Configure the Azure Diagnostic Extension for Storing Linux Log Files"
metaDescription: "Configure the Azure Diagnostic Extension for Storing Linux Log Files"
ogTitle: "Configure the Azure Diagnostic Extension for Storing Linux Log Files"
ogDescription: "Configure the Azure Diagnostic Extension for Storing Linux Log Files"
---

A colleague of mine was trying to figure out a cheap and simple way to store log files from their application and have the functionality to search through it. The first thing that came to mind was using an Azure&reg; monitor to read the logs, but another option that most people forget is the Azure Linux Diagnostic Extension. This extension can collect metrics from the virtual machine (VM), read log events from the syslog, customize collected data metrics, collect specific log files that you can store in a storage table, and send metrics and log events to EventHub endpoints. The Azure portal lets the end-user configure all the preceding settings except collecting specific log files. Let me show you the steps required and a *gotcha* that sent me on a troubleshooting mission.

<!-- more -->

### Configuration

Let's use the following code to create a simple Linux&reg; VM, install Nginx&reg;, open up port `80`, and create a storage account to store our logs in a table:

```
$rgName = 'jrlinux2'
$vmName = 'jrlinux2'
$stgName = 'jrladtest2'
$location = 'eastus'
$vmPassw0rd = 'azuremyp@ssw0rd!'

az group create --name $vmName --location $location 
$vm = az vm create `
  --resource-group $rgName `
  --name $vmName `
  --image UbuntuLTS `
  --admin-username jrudley `
  --admin-password $vmPassw0rd 

#install nginx
az vm run-command invoke -g $rgName -n $vmName --command-id RunShellScript --scripts "sudo apt-get update && sudo apt-get install -y nginx"

#open up nsg
az vm open-port --port 80 --resource-group $rgName --name $vmName

#create storage account for log table storage
az storage account create -n $stgName -g $rgName -l $location --sku Standard_LRS
```

To configure what log file to store in an Azure table, you need to push two JSON files to the VM. Download the **PrivateConfig.json** and **PublicSettings.json** from my repo [here](https://github.com/jrudley/azurelinuxfilelog). Open up the **Public Settings.json** file and add your storage account name and ResourceID of the VM that you created. To quickly get the VM ResourceID, run the following command:

```
($vm | ConvertFrom-Json).id
```

In **PrivateConfig.json**, add the storage account name and generate a shared-access signature token. After you generate the token, copy everything except the first character, which should be a question mark. Copy that token into the **storageAccountSasToken** field.

Use the following command to deploy the Linux diagnostic extension into the VM:

```
az vm extension set --publisher Microsoft.Azure.Diagnostics --name LinuxDiagnostic --version 3.0 --resource-group $rgName --vm-name $vmName --protected-settings .\PrivateConfig.json --settings .\PublicSettings.json
```

To generate traffic to populate the Nginx log file, run the following command:

```
curl "http://$(($vm | ConvertFrom-Json).publicIpAddress)"
```

### The gotcha

At this point, I expected the diagnostic agent to tail the log entries and create an Azure storage table that we configured in the JSON files. I waited for 15 minutes, and nothing happened. I reviewed the log directory at **/var/log/azure/Microsoft.Azure.Diagnostics.LinuxDiagnostic/**, and everything was looking good. I saw the log file path I set and that everything successfully started. After poking around, I found this path **/var/opt/microsoft/omsagent/LAD/log/omsagent.log** and noticed this error:

    #2020-07-10 21:20:44 +0000 [error]: Permission denied @ rb_sysopen - /var/log/nginx/access.log***

I opened a support case to Microsoft because I thought the Agent ran under `root`, but I actually needed to use `chmod` on the log file to give additional permissions. In my support case, Microsoft mentioned they plan to add more documentation on this step.

```
az vm run-command invoke -g $rgName -n $vmName --command-id RunShellScript --scripts "sudo chmod o+r /var/log/nginx/access.log"
```

I used curl against the Nginx endpoint again to generate new log entries and noticed in the **omsagent.log** file that I now have an INFO message **2020-07-10 21:50:04 +0000 [info]: following tail of /var/log/nginx/access.log**. 

In the Azure table storage, Azure automatically created a table and populated new entries successfully ![]({% asset_path 2020-07-15-linux-diagnostic-extension-file-logs/table.png %})

### Parting thought

While using the diagnostic agent is a cheap and easy way to parse log files, just remember that you might need to modify each log file's permission to successfully read it.

