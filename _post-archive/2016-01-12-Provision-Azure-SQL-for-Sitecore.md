---
layout: post
title: "Provision an Azure SQL server for Sitecore with PowerShell"
date: 2016-01-12 10:45
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


In my previous blog post on running Sitecore in a Docker container, I used Azure SQL to host my Sitecore databases. Wanting a clean enviornment each time I develop, I needed a quick way to provision to Azure. With that requirement, I wrote a PowerShell script that makes this task repeatable for development and testing.

<!-- more -->

Investigating the Azure PowerShell cmdlets, Microsoft is in a state of removing Switch-AzureMode cmdlet. Reading the [Azure github wiki](https://github.com/Azure/azure-powershell/wiki/Deprecation-of-Switch-AzureMode-in-Azure-PowerShell), Microsoft announced they are renaming cmdlet's from verb-Azure[noun] to verb-AzureRM[noun]. This seems to be an ongoing effort, so you will see a mix of cmdlet's in my script.

You can download my [PowerShell script](https://github.com/jrudley/azureSitecoreBlobSqlUploader), and edit the following variables:


```sh
$bacpacLocation = 'C:\Users\jrudley\Downloads\sitecore8.1bacpacs\'

#Resource group to create. Must be unique
$Location = 'East US'
$resourceGroupName = 'raxsitecore11'

#storage account information
$storageAccountName = 'sitecoredockerfiles11' #Storage account names must be between 3 and 24 characters in length and use numbers and lower-case letters only
$Type = 'Standard_LRS' #-- Standard_LRS (locally-redundant storage),Standard_ZRS (zone-redundant storage),Standard_GRS (geo-redundant storage),Standard_RAGRS (read access geo-redundant storage),Premium_LRS (normally used for high I/O vm's)
$containerName = 'sitecoreblobcontainer11'

#azure sql server information
$credential = Get-Credential
$sqlServerName = 'raxcontsqlsvr11' #It can only be made up of lowercase letters 'a'-'z', the numbers 0-9 and the hyphen. The hyphen may not lead or trail in the name.
```

The **$bacpacLocation** variable is the location of your exported Sitecore databases with the .bacpac extension. Microsoft has provided instructions for how to do a bacpac export [here](https://azure.microsoft.com/en-us/documentation/articles/sql-database-cloud-migrate-compatible-export-bacpac-ssms/)

The **$Location** and **$resourceGroupName** variables specify where we will create and name our resource group to contain and manage the lifecycle of all our Azure resources.

The **$storageAccountName**, **$Type** and **$containerName** variables specify the Azure blob storage account name, the type of redundancy, and the container name to create inside the storage account.

The **$credential** and **$sqlServeName** variables specify the username and password to use for the Azure SQL Server and the name for the Azure SQL Server to provision.

I first check to see if we have any metadata from Azure. If this returns account information, we are already logged in. If an exception is thrown, I catch it and run **Login-AzureRMAccount** cmdlet to setup our connection. Next, I run the **New-AzureRmStorageAccount** cmdlet to create our Azure resource group to hold the Azure components we will provision. Then I will create a new storage account by typing **New-AzureRmStorageAccount**. With our storage account provisioned, we need to store our storage accounnt key in a variable and create a new Azure storage context. Once we have our context variable, we can then create a new Azure storage container to hold our blob files inside our Azure storage account.

```sh
PS C:\Users\jrudley> $myStorageAccountKey = Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroupName
$myStoreContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $myStorageAccountKey.Key1
New-AzureStorageContainer $containerName -Permission Container -Context $myStoreContext

   Blob End Point: https://sitecoredockerfiles11.blob.core.windows.net/

Name                    PublicAccess LastModified
----                    ------------ ------------
sitecoreblobcontainer11 Container    1/12/2016 6:36:43 PM +00:00
```

We have our storage provisioned inside our resource group, so now we can upload our Sitecore bacpac files. The first variable we set was the folder location of our bacpac files. I pass in all the child items of our **$bacpacLocation** and store the results in **$files**. We can run a simple foreach loop that runs the **Set-AzureStorageBlobContent** cmdlet to upload the files to our Azure storage container.

Now that we have our Sitecore bacpac files in our Azure storage container, we need to provision an Azure SQL Server. Running the following will provision our Azure SQL Server with the SQL server name and credentials we specified at the beginning of our script.

```sh
PS C:\Users\jrudley> New-AzureRmSqlServer -ServerName $sqlServerName -SqlAdministratorCredentials $credential -Location $location  -ResourceGroupName  $resourceGroupName

ResourceGroupName        : raxsitecore11
ServerName               : raxcontsqlsvr11
Location                 : East US
SqlAdministratorLogin    : jrudley
SqlAdministratorPassword :
ServerVersion            : 2.0
Tags                     :
```

By default, our Azure SQL server has a firewall enabled, and we need to allow our public IP, and all Azure IPs, to talk to our SQL server. I can create a new .net.webclient object and return my public ip by running the following PowerShell code

```sh
$wc=New-Object net.webclient
$ip = $wc.downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]".Trim()
```

Now that we have our public ip in the $ip variable, we need to set our two firewall rules.

```sh
PS C:\Users\jrudley> #allow access from my remote IP
New-AzureRmSqlServerFirewallRule -FirewallRuleName 'myIP' -StartIpAddress $ip -EndIpAddress $ip -ServerName $sqlServerName -ResourceGroupName $resourceGroupName
#allow access to the sql server within Azure
New-AzureRmSqlServerFirewallRule -ServerName $sqlServerName -ResourceGroupName $resourceGroupName -AllowAllAzureIPs

ResourceGroupName : raxsitecore11
ServerName        : raxcontsqlsvr11
StartIpAddress    : 555.555.555.555
EndIpAddress      : 555.555.555.555
FirewallRuleName  : myIP

ResourceGroupName : raxsitecore11
ServerName        : raxcontsqlsvr11
StartIpAddress    : 0.0.0.0
EndIpAddress      : 0.0.0.0
FirewallRuleName  : AllowAllAzureIPs
```

You can see we added my public ip (removed the real ip for privacy) to connect in remotely via management studio and allowed Azure instances to talk to my Azure SQL Server. With those rules in place, we can now tell Azure to read from my Azure storage container and to restore the bacpac files. Before Azure can start the import, we need to create an Azure sql database server context and to grab our storage container we created above.

```sh
PS C:\Users\jrudley> $ServerNameFQDN = $sqlServerName + '.database.windows.net'
$sqlContext =  New-AzureSqlDatabaseServerContext -FullyQualifiedServerName $serverNameFQDN -Credential $credential
$Container = Get-AzureStorageContainer -Name $containerName -Context $myStoreContext
```

We can run a foreach loop that reads our variable **$files**, which we pass the variables we built above into the **Start-AzureSqlDatabaseImport** cmdlet. I also created a variable called **$Targets** to hold the request id's from my import. Since this is an asynchornous import, we can pass these request id's into another cmdlet and check the status.

```sh
$Targets = @()
foreach ($file in $files)
{

$importRequest = Start-AzureSqlDatabaseImport -SqlConnectionContext $sqlContext -StorageContainer $Container -DatabaseName $file.ToString().Substring(0,$file.ToString().IndexOf('.')) -BlobName $file -Edition Standard

$file
$importRequest.RequestGuid
$Targets += $importRequest

#sleep for X seconds as sometimes the sql server reports back that an operation is in progress
Start-Sleep -s 5

}
```

The cmdlet **Get-AzureSqlDatabaseImportExportStatus** lets us check our import status. It expects a string and not a credential object. I found a [snippet of code](http://stackoverflow.com/questions/21741803/powershell-securestring-encrypt-decrypt-to-plain-text-not-working) that will convert the object back to a string. This will loop and check every 30 seconds until all the database imports are finished.

```sh
#Get-AzureSqlDatabaseImportExportStatus expects a string for password.
write-host "Waiting for Database import to finish" -ForegroundColor Yellow
$sw = [Diagnostics.Stopwatch]::StartNew()
do
{
   $allOK = $true
   foreach ($item in $Targets)
   {

   $dbstatus = Get-AzureSqlDatabaseImportExportStatus -RequestId $item.Requestguid -ServerName $sqlServerName -Username $credential.UserName -Password ((New-Object System.Management.Automation.PSCredential 'N/A', $credential.Password).GetNetworkCredential().Password)
   write-host $dbstatus.databasename $dbstatus.status -ForegroundColor Yellow
       if ($dbstatus.status -ne 'Completed')
       {
       write-host "DB import still going..." -ForegroundColor Yellow
          $allOK = $false
       }
    }
    write-host "We finished importing?  $allOK" -ForegroundColor DarkYellow
    if ($allOK -eq $false)
    {
    start-sleep -s 30
    }
}
until ($allOK -eq $true)
$sw.Stop()
write-host $sw.Elapsed
write-host "All sitecore db's imported!" -ForegroundColor Green
```
