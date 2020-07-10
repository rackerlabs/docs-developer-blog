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

A colleague of mine was trying to figure out a cheap and simple way for to store log files from their application and have the functionality to search through it. First thing that comes to mind is using Azure monitor to read the logs, but another option that most people forget is the Azure Linux Diagnostic Extension. This extension can collect metrics from the VM, read log events from syslog, customize data metrics that are collected, collect specific log files that can be stored in a storage table and send metrics and log events to EventHub endpoints. The Azure portal can let the end user configure all the above settings except collecting specific log files. Let me show you the steps required and the gotcha that sent me into a troubleshooting mission.

<!-- more -->

Let's create a simple Linux VM, intall nginx, open up port 80 and create a storage account to store our logs in a table

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
In order to configure what log file to store in an Azure table, 2 json files need pushed into the virtual machine. Download the PrivateConfig.json and PublicSettings.json from my repo [here](https://github.com/jrudley/azurelinuxfilelog). Open up the Public Settings.json file and add your storage account name and ResourceID of the virtual machine created above. To quickly get the VM resource id, run the command below
```
($vm | ConvertFrom-Json).id
```
In the PrivateConfig.json, add the storage account name and generate a Shared Access Signature token. Once generated, copy everything except the first character which should be a question mark. Copy that token into **storageAccountSasToken** field.

Deploy the Linux diagnostic extension into the virtual machine.
```
az vm extension set --publisher Microsoft.Azure.Diagnostics --name LinuxDiagnostic --version 3.0 --resource-group $rgName --vm-name $vmName --protected-settings .\PrivateConfig.json --settings .\PublicSettings.json
```

To generate traffic to populate the nginx log file, run
```
curl "http://$(($vm | ConvertFrom-Json).publicIpAddress)"
```
At this point, you would expect the diagnostic agent to tail the log entries and create an Azure storage table that we configured in the JSON files. After waiting 15 minutes, nothing happened. I reviewed the log directory at ***/var/log/azure/Microsoft.Azure.Diagnostics.LinuxDiagnostic/***, but everything was showing good. I saw the log file path I set and everything successfully start. After poking around, I found this path ***/var/opt/microsoft/omsagent/LAD/log/omsagent.log*** and noticed ****#2020-07-10 21:20:44 +0000 [error]: Permission denied @ rb_sysopen - /var/log/nginx/access.log***

I opened a support case to Microsoft as I thought the Agent ran under root, but it looks like you need to chmod the log file to give additional permissions. In my support case, Microsoft mentioned they will be adding more documentation around this step.
```
az vm run-command invoke -g $rgName -n $vmName --command-id RunShellScript --scripts "sudo chmod o+r /var/log/nginx/access.log"
```

I used curl against the nginx endpoint again to generate new log entries and noticed in the omsagent.log file, I now have an INFO message ***2020-07-10 21:50:04 +0000 [info]: following tail of /var/log/nginx/access.log*** In the Azure table storage, a table was automatically created and new entries are being populated successfully ![]({% asset_path 2020-07-15-linux-diagnostic-extension-file-logs/table.png %}) While using the diagnostic agent is a cheap and easy way to parse log files, just remember that the permission of each log file may need to be modified in order to be successfully read.

