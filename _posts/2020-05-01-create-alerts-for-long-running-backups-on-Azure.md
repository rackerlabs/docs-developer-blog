---
layout: post
title: "Create alerts for long-running backups on Azure"
date: 2020-05-01 00:01
comments: true
author: Gourav Kumar
published: true
authorIsRacker: true
authorAvatar: 'https://s.gravatar.com/avatar/ea51707a4a182959177d9b8244835571'
bio: "An Azure professional, blog writer, and community contributor with soft
corner of PowerShell. I'm learning Terraform and building my road to be on top.
For more, solve this: (65,122,117,114,101,77,97,110,\" \",\"\|\",\" \",71,111,117,114,97,118| ForEach-Object {[char]$_})-join\"\""
canonical: https://blog.topqore.com/monitor-azure-backup-with-log-analytics/
categories:
    - Azure
metaTitle: "Create alerts for long-running backups on Azure"
metaDescription: "This post explores explore how to monitor Microsoft&reg; Azure&reg;
backups and, if they run long, trigger an alert on them with the help of Log Analytics."
ogTitle: "Create alerts for long-running backups on Azure"
ogDescription: "This post explores explore how to monitor Microsoft&reg; Azure&reg;
backups and, if they run long, trigger an alert on them with the help of Log Analytics."
---

This post explores explore how to monitor Microsoft&reg; Azure&reg; server
backups and, if the backups run long, use Log Analytics to trigger an alert on
those servers.

**Teaser**: The post unveils new features of Azure **Backup Report**, and Azure
**Monitor** and offers some fancy Kusto Query Language (KQL) operations.

<!-- more -->

### Introduction

To make this topic easy to understand, I am dividing this into three parts.

1.   Enable **Backup Report**.
2.   Write a KQL query to check long-running server backups.
3.   Configure an alert (or create a signal) for long-running server backups.


### Enable Backup Report

**Note**: This post assumes you already use Recovery Services vaults to back up
your Azure infrastructure.

Use the following steps to enable an Azure Backup report:

#### 1: Log into the portal

Log into the Azure portal and click the **All services blade** to search
for **Recovery Services vaults**.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture1.png %})

#### 2: Select a vault

Select one of the recovery service vaults on which to enable Backup Report
and monitor backup duration.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture2.png %})

I selected the first vault in the preceding image.

#### 3: Chose Backup Report

The backup recovery vault has a blade, **Backup Reports**. Click
**Backup Reports**,  and configure **Backup Report** by selecting
[Diagnostics Settings](https://portal.azure.com/).

**Note**: The preview **Backup Reports** feature might not be available in
some Regions.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture3.png %})

#### 4: Configure Backup Report

To configure **Backup Report**, click on **Add diagnostic setting**.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture4.png %})

You can stream backup logs to Azure Event Hub, a storage account, or
**Log Analytics**. In this example, I chose **Log Analytics**.

To enable backup log streaming, fill in the name of the report, check
**Send to Log Analytics**, check **AzureBackupReport** in the **Log** section,
and click **Save**.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture5.png %})

The portal displays your report, as shown in the following image:

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture6.png %})

### KQL query to monitor server backups

This section introduces the following KQL query for long-running Azure server
backups:

    AzureDiagnostics
    | where TimeGenerated > ago(1d)
    | where Category == “AzureBackupReport”
    | where OperationName == “Job”
    | where todouble(DataTransferredInMB_s)>1
    | extend Report_Running_Time_UTC= TimeGenerated
    | extend Backup_Job_Start_Time = JobStartDateTime_s

    // If you want time in AM or PM format and want to make more readable, uncomment the following line by removing //

    //| where (Backup_Job_Start_Time contains “AM” or Backup_Job_Start_Time contains “PM”)

    | extend DataTransferedGB = todouble(DataTransferredInMB_s)/1024
    | extend JobDurationHour = todouble(JobDurationInSecs_s)/3600
    | where JobDurationHour > 3
    | extend Vault_Name = split(ResourceId, ‘/’)[-1]
    | extend Server_Name = split(BackupItemUniqueId_s, ‘;’)[-1]
    | project Report_Running_Time_UTC, Backup_Job_Start_Time, SubscriptionId, JobOperation_s, JobStatus_s, DataTransferedGB, JobDurationHour, ResourceGroup, Server_Name, Vault_Name, Level

In case you're not familiar with KQL, let me explain the important elements of
this query.

The query examines the last day of Azure backup data (`where TimeGenerated > ago(1d)`)
to find jobs that took longer than three hours to complete (`where JobDurationHour > 3`).

You can change the number of hours, which is three in this case, to whatever
number you consider to be too long.

### Configure an alert

Glad you made it this far&mdash;read on for the best part!

So, why should you set an alert for long-running server backups?

“In general, we have multiple virtual machines (VMs) in Azure, and being
DevOps and Azure admin engineers, we all have daily tasks and troubleshooting
to do during business hours. Due to this, we can hardly open every tab of Azure
every day; therefore, we miss unexpected behavior of Azure backup (such as one
with a long run time, which can be serious). To make ourselves sync with the
Azure portal is a smart move.”

Use the following steps to set an alert for long-running backups:

#### 1: Open Log Search

Open the **Log search** section of the **Log analytics** workspace that you
selected during the report configuration.

#### 2: Paste the KQL query

Copy and paste the preceding KQL query in the **Query** tab and click **Run**.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture7.png %})

Servers that took longer than three hours to complete display, as shown in
the following output:

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture8.png %})

#### 3: Create a new alert

To set an alert for these servers, click **New Alert Rule**.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture9.png %})

#### 4: Configure the new alert

Under **Condition*, enter the threshold value with the count. I chose `1`
because I want to create an alert on every server and result.

**Note**: You could also change the period and frequency of the alert, as needed.

![]({% asset_path 2020-05-01-create-alerts-for-long-running-backups-on-Azure/Picture10.png %})

Configure other alert requirements, such as alert name, action group (email
recipient), webhooks, and other conditions.

### Conclusion

That’s all there is to it. This post showed you how to configure an alert on
Azure VM backups that take longer than three hours. The alert sends a
notification email with all the details. With that information, you can take the
appropriate action.

<a class="cta purple" id="cta" href="https://www.rackspace.com/microsoft/managed-azure-cloud">Learn more about our managed Azure cloud.</a>

Use the Feedback tab to make any comments or ask questions. You can also
[chat now](https://www.rackspace.com/#chat) to start the conversation.

Use the Feedback tab to make any comments or ask questions.
