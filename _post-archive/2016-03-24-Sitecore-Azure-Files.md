---
layout: post
title: "How to use Azure Files with Sitecore logging"
date: 2016-03-24 00:00
comments: false
author: Jimmy Rudley
authorIsRacker: true
published: true
authorAvatar: 'https://en.gravatar.com/userimage/151177997/5bed7e07ee47533cbd34b951d463bcb7.jpg'
bio: “Jimmy Rudley is an Azure Architect at Rackspace and an active member of the Azure community. He focuses on solving large and complex architecture and automation problems within Azure."
categories:
    - DevOps
    - Azure
---

Azure file storage is a great storage offering for a simple centralized file storage share that I often see go unused. A super feature is the ability to mount the share as a mapped network drive on your local machine.

<!-- more -->

When issues happen in Sitecore, where there's been a crash dump, logs need archived, you want to do a deployment, or you just need to share something with a developer, using an Azure file storage share is a great option. Let me show you how to easily setup an Azure file share and archive the Sitecore log files automatically.

Let's create the Azure resources required to set up a file share, using Azure PowerShell to provision the Azure resources.

```sh
$resourceGroupName = 'raxsitecorerg' #resource group name
$location = 'East US' #location of the resource group and storage account
$storageAccountName = 'raxsitecorest' #storage account name
$shareName = 'logs' #share name

#Flush out any stale dns entries from previous testing
ipconfig /flushdns

try
{
	$AzureRMContext = Get-AzureRMContext
}
catch
{
	Login-AzureRMAccount
}

#Create a new resource group
$rg = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

#Create a new storage account in our resource group
$st = New-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storageAccountName -Type Standard_LRS -Location $location

#grab the storage key
$key = Get-AzureRmStorageAccountKey -ResourceGroupName $rg.ResourceGroupName -Name $storageAccountName

#setup a storage context
$ctx=New-AzureStorageContext -StorageAccountName $storageAccountName $key.Key1

#Create a new file share
New-AzureStorageShare -name $shareName -Context $ctx

#Create the commands to run on vm/host to map the network drive
#persist credentials for reboot's, etc
write-host "cmdkey /add:$($ctx.StorageAccount.FileEndpoint.DnsSafeHost) /user:$($ctx.StorageAccountName) /pass:$($key.Key1)"

#map the drive
write-host "net use z: \\$($ctx.StorageAccount.FileEndpoint.DnsSafeHost)\$shareName /persistent:yes"

```

With our Azure file share provisioned, run the following commands that were generated above from the write-host output on your host. This will map the unc path to a network drive. An example looks like:

```sh
cmdkey /add:raxsitecorest.file.core.windows.net /user:raxsitecorest /pass:Oq5SiWsdsddsdsddsdsR6eujbspbQ2j4T7ODopoZr0vrK4MQe1QHAqgffgffgfgzT+ydzoA9nxV9S/YVQ==
net use z: \\raxsitecorest.file.core.windows.net\logs /persistent:yes
```

With our unc path now mapped to a drive letter, we have a lot of possibilities of what we can do. I wrote a PowerShell script to show how to zip up and move Sitecore 8.1 logs to our mapped drive letter

```sh
import-module WebAdministration
$tempFolderPath = ($env:computername+'_'+(get-date -f MM_dd_yyyy))
$mappedDrive = Get-WmiObject Win32_MappedLogicalDisk | select DeviceID #Grab our mapped network drive. I Assume 1 drive exists
$daysToGoBack = -30 #Archive anything older than X days from today

#check if file is locked
function get-FileLock($file)
{
    try
    {
        [IO.File]::OpenWrite($file).close()
        return $false
    }
    catch
    {
        #file locked
        return $true
    }
}

#zip folder
function new-Zip($dirToZip, $zipName)
{
   Add-Type -Assembly System.IO.Compression.FileSystem
   [System.IO.Compression.ZipFile]::CreateFromDirectory($dirToZip,$zipName)
}

#Look for Sitecore websites and archive the logs
foreach ($website in Get-Website)
{
$fileCheck = $website.physicalPath + "\bin\sitecore.kernel.dll"

    if (Test-Path $fileCheck)
    {
    #get data folder location
     $sitecoreConfigPath = "$($website.physicalPath)\App_Config\sitecore.config"
     $sitecoreConfig = [xml](Get-Content $sitecoreConfigPath)
     $sitecoreDataPath =  $sitecoreConfig.SelectSingleNode("sitecore/sc.variable[@name='dataFolder']").Value

     $logPath = "$sitecoreDataPath\logs"
     $logFilesToMove = gci -Path $logPath -Filter *.txt | where {$_.CreationTime -lt (Get-Date).AddDays($daysToGoBack)}
     if (!(test-path $sitecoreDataPath\logs\$tempFolderPath))
     {
     New-Item -ItemType directory -Path "$sitecoreDataPath\logs\$tempFolderPath"
     }
     foreach ($item in $logFilesToMove)
     {
         if(!(get-FileLock($Logpath+'\'+$item.Name)))
         {
            Move-Item -Path ($Logpath+'\'+$item.Name) -Destination "$sitecoreDataPath\logs\$tempFolderPath\"
         }
     }

     new-Zip  "$sitecoreDataPath\logs\$tempFolderPath\" "$($mappedDrive.DeviceID)\$tempFolderPath.zip"

     if (Test-Path "$($mappedDrive.DeviceID)\$tempFolderPath.zip")
     {
        Remove-Item -Path "$sitecoreDataPath\logs\$tempFolderPath\" -Recurse
     }
    }
}

```

We can easily add this powershell script to a task scheduler job to archive our logs. I hope this helps generate new ideas on how to use Azure file storage.
