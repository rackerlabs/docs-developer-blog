---
layout: post
title: Filtering backups in Azure App service
date: 2016-12-08 10:22
comments: false
author: Jimmy Rudley
published: true
authorIsRacker: true
categories:
    - DevOps
    - Azure
---

With Azure App Service, backing up your web app is available depending which App Service plan is choosen. With the introduction of larger applications moving to the cloud, certain files or folders do not need backed up. This is not something an end user can do in the Azure portal, so let's investigate how we can accomplish filtering of files or folders during the backup process.

<!-- more -->

In the Azure portal, select your web app and in the blade under settings, there will be a backup option.

![backup blade]({% asset_path 2016-12-08-Filtering-backups-in-Azure-App-Service/blade.png %})

From here, select configure to choose your storage settings.  This will be a storage account and a container to dump the backup files to. Optionally, you can then select schedule settings and set a reoccuring backup. If you are doing an on-demand backup, please note that doing more than 1 backup will overwrite your existing on demand backup. It does not append any timestamp or naming suffix to make the backup unique. If doing a scheduled backup, Azure will append the timestamp onto the file name.
![files]({% asset_path 2016-12-08-Filtering-backups-in-Azure-App-Service/files.png %})

For example, I am using a Sitecore PaaS deployment, focusing on the content delivery node. I want to make sure I filter out the Sitecore and temp folders in my backup. For this, let's create a new file and call it ```_backup.filter``` In this file, specify the full path of the file and folders to exclude.
```
/site/wwwroot/sitecore
/site/wwwroot/temp
```
Upload this file to your webroot directory.
```
/site/wwwroot
```
When starting an on-demand or scheduled backup, those folders are excluded to reduce the size of your zip. Because the storage account is  billed based on the amount of space, we exclude files we need so that we can save space and reduce costs.
