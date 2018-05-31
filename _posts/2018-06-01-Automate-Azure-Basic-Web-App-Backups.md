---
layout: post
title: "Automate Azure Basic Web App Backups"
date: 2018-06-01 00:00
comments: true
author: Jimmy Rudley
published: true
authorIsRacker: true
categories:
    - General
---

Azure provides backup and restore functionality when using a Standard or Premium App Service plan. That leaves web apps using a Basic App Service plan without a backup solution. In a perfect world, you would have everything in source control and deploy to get back up and running, but we do not live in a perfect world. Let's examine the Azure App Service KUDU API to learn how to build our own backup  and restore solution.

<!-- more -->

We need to create a function that zips the files from the wwwroot folder and stores the zip file in an Azure Storage Account. In the [KUDU API](https://github.com/projectkudu/kudu/wiki/REST-API),the ZIP API section shows a GET operation that can be called to zip a folder. This is great, because it lets us backup our wwwroot folder. Let's look at the following code that can be placed into an Azure Automation Runbook to do our backup.

```
function get-zip {
    param( 
        [Parameter(Mandatory = $true)]
        [string]$resourceGroup,
        [Parameter(Mandatory = $true)]
        [string]$siteName,
        [string]$folderPathToDownloadFile = 'c:\temp\'
    )  
    
    try {
        [xml]$publishSettings = Get-AzureRmWebAppPublishingProfile -Format WebDeploy  -ResourceGroupName $resourceGroup -Name $siteName
        $creds = $publishSettings.SelectSingleNode("//publishData/publishProfile[@publishMethod='MSDeploy']")
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $creds.userName, $creds.userPWD)))

        if (!(Test-Path $folderPathToDownloadFile)) {
            New-Item -ItemType Directory -Path $folderPathToDownloadFile
        }

        #include trailing slash
        Invoke-RestMethod -Uri "https://$siteName.scm.azurewebsites.net/api/zip/site/wwwroot/" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)} `
            -OutFile "$($folderPathToDownloadFile)\wwwroot.zip" -Method Get -ContentType 'multipart/form-data' -Verbose
    }
    catch {
        $_ 
    }
}
```
This function stores the publishing profile into a variable, extracts the credentials out, and then makes a REST call to the ZIP API for the website, which was passed into the variable **$siteName**. The ZIP API outputs the zip file to the location that was passed into the function variable **$folderPathToDownloadFile**. I have not seen any documented limits for the ZIP API because the Standard App Service backup has limits for scheduled backups [App Service Limits](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits#app-service-limits). Here's something to note: if you run this code in an Azure Automation Runbook to download the zip, the available drive space is limited. I confirmed with Microsoft that there is a 1GB workspace and that they will be updating their public documents with this information.

When I initially looked into this way of doing backups, it was to create a multi-region diaster recovery solution without needing the customer to do deployments to multiple web apps. The following function that I wrote takes the backup from **get-zip**, then restores it on another webapp in another region using **set-zip**.

```
function set-zip {
    param( 
        [Parameter(Mandatory = $true)]
        [string]$resourceGroup,
        [Parameter(Mandatory = $true)]
        [string]$siteName,
        [Parameter(Mandatory = $true)]
        [string]$zipFile,
        [switch]$detailedDebug,
        [int]$extractSleepTimeInSeconds = 15
    ) 

    try {      
        [xml]$publishSettings = Get-AzureRmWebAppPublishingProfile -Format WebDeploy  -ResourceGroupName $resourceGroup -Name $siteName
        $creds = $publishSettings.SelectSingleNode("//publishData/publishProfile[@publishMethod='MSDeploy']")
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $creds.userName, $creds.userPWD)))


        $Headers = @{
            Authorization = $base64AuthInfo
        }
      
        $headers = Invoke-WebRequest -Uri "https://$siteName.scm.azurewebsites.net/api/zipdeploy?isAsync=true" -Method Post  -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)} -InFile $zipFile -ContentType  'multipart/form-data'  | 
            Select-Object -expand Headers
       
        $status = Invoke-RestMethod -Uri $headers.Location -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
        
        #looked through kudu api source and it seems 4 means success. 
        while ($status.status -ne 4) {   
            Write-Output "Not finished unzipping..sleeping $extractSleepTimeInSeconds seconds"
            $status = Invoke-RestMethod -Uri $headers.Location -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)} 
            if ($detailedDebug) {
                Write-Output $status
            }
            start-sleep -s $extractSleepTimeInSeconds
        }           
        
        $status = Invoke-RestMethod -Uri $headers.Location -Method Get -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
        if ($status.status -eq 4) {
            Write-Output "Finished unzipping $zipFile"
            $status
        }
        else {
            Write-Output "Something did not go right unzipping $zipfile. Please investigate..."
        }
    }
    catch {
        $_
    }
}
```
This function calls the ZIPDEPLOY API and passes a query string of **isAsync=true** to make this an asynchronous deployment. Using an ``Invoke-WebRequest``, we can see the response header, which contains a location of a log file that can be queried to see the status of the zip deployment. I'll do a simple while loop to keep checking until the status shows ``Success``. There are some benefits of using the ZIPDEPLOY call as opposed to the ZIP call, because ZIP overwrites only those files with different timestamps on files, and locking occurs on the webapp to prevent additional deployments during extraction. For a complete list, please see [Benefits of Zip Deployment](https://github.com/projectkudu/kudu/wiki/Deploying-from-a-zip-file). At this point, a runbook can do automated backups of basic web apps and optionally restore the backup to another webapp. I have placed the entire powershell script and readme file at [Script Repo](https://github.com/jrudley/basicWebAppBackupRestore).
