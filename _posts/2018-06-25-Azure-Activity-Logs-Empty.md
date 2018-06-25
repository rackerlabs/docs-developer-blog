---
layout: post
title: "Azure Activity Logs Showing Empty in the Portal"
date: 2018-06-25 00:00
comments: true
author: Jimmy Rudley
published: true
authorIsRacker: true
categories:
    - General
---

I ran into an odd issue where I was issuing a backup for an App Service Web App using PowerShell and the activity log entries all disappeared in the portal. The only thing left was an exclamation mark wrapped in curly braces. 

<!-- more -->

I thought maybe it was just the portal having issues or my browser playing tricks on me, but after testing in multiple browsers and Azure subscriptions, I was able to reproduce this. I realized that if I queried using the cmdlet **Get-AzureRmLog**, I could still retrieve my log entries. At this point, I knew this had to be a bug with the portal. I opened a case and after troubleshooting with Microsoft, they did confirm it is a bug. This issue happens when some of the on-going operations don't have an operation name in the history events, but this is a required field for it to be displayed in the activity logs. The two PowerShell cmdlets I was able to repo this were **New-AzureRmWebAppBackup** and **Restore-AzureRmWebAppBackup**

There is no timeframe on a fix, but Microsoft is working towards a resolution.



