---
layout: post
title: "SAP HANA system replication"
date: 2020-07-08 00:01
comments: true
author: Chakrala Vinodh
authorAvatar: 'https://s.gravatar.com/avatar/72046bfed0f329b284a8992ea3fc920b'
bio: "I'm a SAP BASIS administrator with 5 years of experience. I have deep
expertise in implementation, migration, installation, and upgrades of SAP systems.
My key skills include SAP HANA administration and Error Correction Code (ECC)."
published: true
authorIsRacker: true
categories:
    - General
metaTitle: "SAP HANA system replication"
metaDescription: "Usually, you use system replication to support high availability
and disaster recovery. SAP HANA system replication lets you copy and continuously
synchronize a SAP HANA database to a secondary location on the same or another
data center."
ogTitle: "SAP HANA system replication"
ogDescription: "Usually, you use system replication to support high availability
and disaster recovery. SAP HANA system replication lets you copy and continuously
synchronize a SAP HANA database to a secondary location on the same or another
data center."
---

Usually, you use system replication to support high availability and disaster
recovery. SAP HANA&reg; system replication lets you copy and continuously synchronize
a SAP HANA database to a secondary location on the same or another data center.

<!-- more -->

### Overview

This mechanism ensures the high availability of your SAP HANA system. System
replication is the SAP recommended configuration for addressing SAP HANA outage
reduction due to planned maintenance, faults, and disasters. It supports a
recovery point objective (RPO) of 0 seconds and a recovery time objective (RTO)
measured in minutes.

### How it works

After you enable SAP HANA system replication, each server process on the secondary
system establishes a connection with its primary system counterpart and requests
a snapshot of the data. From there, SAP HANA continuously replicates all logged
changes in the primary system. At the same time that the system writes logs to
the log volumes of each service, persisting the logs, it also sends them to the
secondary system.

The primary system commits a transaction after replicating the redo logs. This
process depends on the replication mode that you selected when you set up the
system replication.

![]({% asset_path 2020-07-08-sap-hana-system-replication/Picture1.png %})

*Image source*: [https://help.sap.com/viewer/4e9b18c116aa42fc84c7dbfd02111aba/2.0.05/en-US/fb06367a182945eb9048f2b0fb788325.html](https://help.sap.com/viewer/4e9b18c116aa42fc84c7dbfd02111aba/2.0.05/en-US/fb06367a182945eb9048f2b0fb788325.html)

Replication modes and operation modes play a crucial role when configuring HANA
system replication. You need to select these modes depending on your requirements.

### Replication modes

While registering the secondary system, you need to decide which replication
mode to use. These modes generally determine how logs replicate to the secondary
system.

SAP HANA offers the following replication modes:

#### Synchronous in-memory (SYNCMEM)

The primary system commits the transaction only after receiving a reply that the
secondary system received the log and stored it in the memory. The transaction
delay in the primary system is shorter because it only includes data transmission
time.

Data loss can occur in the following situations:

- When the primary and secondary systems fail at the same time while the secondary
  system is connected, data is not written to either the primary or secondary
  system disk.

- When a takeover occurs while the secondary system is unavailable. The data that
  arrived on the secondary is outdated compared to the data on the primary.

This option is vulnerable to data loss, but it provides better performance
because it doesn't need to wait for the secondary system disk I/O.

#### Synchronous on disk (SYNC)

The primary system waits to commit the transaction until it gets a reply that
the log is persisted on the secondary system disk. When the connection to the
secondary system is lost, the primary system continues to process transactions
and writes the changes to only the local disk.

If the secondary system is connected, you won't lose any data. However, data
loss can occur when a takeover occurs while the secondary system is disconnected.

#### Synchronous full sync

Synchronous replication mode can run with a full sync option. The log write
succeeds when the system writes the log buffer to the log file of both the
primary and secondary systems. You can set the **full sync** option with the
`[system_replication]/enable_full_sync` parameter.

When the secondary system is disconnected (for example, because of network
failure), the primary system suspends the transaction processing until it
reestablishes the connection to the secondary system. No data loss occurs in
this scenario.

#### Asynchronous (ASYNC)

The primary system commits the transaction after sending the log without
waiting for a response. This process causes no delay because the data transmission
is asynchronous to the transaction in the primary system.

Because you don't need to wait for the log I/O on the secondary system, this
method offers better performance. The process guarantees database consistency
across all services on the secondary system. However, it is more vulnerable to
data loss&mdash;you might lose data changes during a takeover.

### Replication mode behavior

The following table gives a brief idea about each replication mode's behavior
when the secondary system is not available:

![]({% asset_path 2020-07-08-sap-hana-system-replication/Picture2.png %})

### Operation Modes

While registering the secondary system, you need to decide which operation mode
to use with SAP HANA system replication. Depending on the configured operation
mode, the database sends different types of data packages to the secondary system.

Choose from the following operation modes:

#### delta_datashipping

This mode performs a delta data shipping occasionally (default: every 10 minutes)
in addition to the continuous log shipping. The system does not replay the shipped
redo log on the secondary site. During a takeover, the system replays the redo
log up to the latest delta data shipment.

The following image shows this traffic on the transportation channel between the
primary and secondary systems for the **delta_datashipping** operation mode:

![]({% asset_path 2020-07-08-sap-hana-system-replication/Picture3.png %})

*Image source*: [https://help.sap.com/viewer/4e9b18c116aa42fc84c7dbfd02111aba/2.0.05/en-US/dcafdb5742314873b212ebf678d6a96a.html](https://help.sap.com/viewer/4e9b18c116aa42fc84c7dbfd02111aba/2.0.05/en-US/dcafdb5742314873b212ebf678d6a96a.html)


#### logreplay

In this operation mode, the system does a redo log shipping after you initially
configure system replication with one full data shipping. Then, the system
continuously replays the redo log on the secondary site immediately after arrival.
During a takeover, this replay process makes this step unnecessary. The
**logreplay** mode does not require delta data shipping, which helps to reduce
the amount of data transferred to the secondary system.

#### logreplay_readacess

You need to use this mode for replication to an Active/Active, read-enabled,
secondary system. It is similar to the **logreplay** operation mode in the
following ways:

- It has continuous log shipping.
- It uses the redo log replay on the secondary system.
- It requires an initial full data shipping and a takeover.

This mode reduces the load on the primary system because it allows read-only
access from the secondary system.

The following figure shows this traffic on the transportation channel between
the primary and the secondary system for the **logreplay** and
**logreplay_readaccess** operation modes:

![]({% asset_path 2020-07-08-sap-hana-system-replication/Picture4.png %})

*Image source*: [https://help.sap.com/viewer/4e9b18c116aa42fc84c7dbfd02111aba/2.0.05/en-US/dcafdb5742314873b212ebf678d6a96a.htm](https://help.sap.com/viewer/4e9b18c116aa42fc84c7dbfd02111aba/2.0.05/en-US/dcafdb5742314873b212ebf678d6a96a.html)

### Configure SAP HANA replication

You can configure SAP HANA system replication by using the following tools:

- SAP HANA cockpit

- SAP HANA studio

- `Hdbnsutil` (a command-line tool)

Perform the following steps to configure replication by using SAP HANA studio:

#### Step one: Enable system replication

<br/>

1. Start the primary system.

2. Perform an initial data backup or storage snapshot on the primary system.

3. Enable system replication on the primary system by using the following steps
   in SAP HANA studio:

     a. In the **Systems** view, right-click the primary system and choose
     **Configuration and Monitoring -> Configure System Replication**.

     b. The **Configure System Replication** dialog opens
     and selects the **Enable System Replication** option by default. Click **Next**.

     c. Enter the logical name used to represent the primary system and click **Next**.

     d. Review the configured information and choose **Finish**.

     e. To stop the secondary system, right-click on the secondary system and choose **Configuration and Monitoring -> Stop System**.

4. To prepare the secondary system for authentication, copy the system PKI SSFS
   **.key** and the **.dat** file from the primary system to the secondary system.
   For more information, see [SAP Note 2369981](https://launchpad.support.sap.com/#/notes/0002369981).

5. Use the following steps to register the secondary system with the primary
   system in SAP HANA Studio:

     a. To stop the secondary system if it is still running, right-click the
     secondary system and choose **Configuration and Monitoring ->Stop System**.

     b. In the **Systems** view, right-click the secondary system and choose
     **Configuration and Monitoring -> Configure System Replication**.

     c. In the **Configure System Replication** dialog, choose
     **Register Secondary System** and click **Next**.

     d. Enter the system information and the logical name for the secondary system.

     e. Specify the log replication mode and operation mode.

     f. Review the configured information and click **Finish**.

6. The secondary system requests an initial full data replica from the primary system.

The system replication is enabled and the secondary system is registered with a
primary system now


#### Step two:  Disable system replication

<br/>

1. Use the following steps to unregister the secondary system in SAP HANA studio:

     a. In the **Systems** view, right-click the primary system and choose
     **Configuration and Monitoring -> Configure System Replication**.

     b. In the **Configure System Replication dialog**, choose
     **Unregister secondary system** and click **Next**.

     c. Enter the required system information and click **Next**.

     d. Review the configured information and click **Finish**.

2. Use the following steps to disable replication system on the primary system:

     a. In the **Systems** view, right-click the primary system and choose
     **Configuration and Monitoring -> Configure System Replication**.

     b. Choose **Disable system replication** and click **Next**.

     c. Review the configured information and click **Finish**.

#### Step three: Takeover the secondary system

<br/>

The takeover process switches your active system from the current primary system
to the secondary system. If you perform a takeover as part of a planned downtime,
you should first make sure that the primary system has completely stopped before
performing a takeover to the secondary system.

1. Perform a takeover in the secondary system at data center **B** by using the
   following steps in SAP HANA studio:

     a. In the **Systems** view, right-click the secondary system and choose
     **Configuration and Monitoring -> Configure System Replication**.

     b. Choose **Perform Takeover** from the actions list.

     c. Enter the required system information and click **Next**.

     d. Review the information and click **Finish**.

2. At this point, the Secondary system becomes the production system. If the
   system is running, it leaves the recovery mode and becomes fully operational,
   replaying the latest transaction logs and accepting queries. If the system is
   offline, start it, and it will take over production operations.

#### Step four: Failback to the original primary system

<br/>

1. To failback, you must attach your former primary system as the new secondary
   system to the current primary system by using the following steps in SAP HANA
   studio:

     a. In the **Systems** view, right-click the primary system and choose
     **Configuration and Monitoring -> Configure System Replication**.

     b. In the **Configure System Replication** dialog, choose
     **Register Secondary System** and click **Next**.

     c. Enter the system information and the logical name for the system.

     d. Specify log replication mode and operation mode as required.

     e. Review the configured information and click **Finish**.

2. The former primary system is now registered as the secondary system with the
   current primary system, formerly the secondary system. Because the system
   cannot use the data in the former primary system, it carries out a complete
   initialization. A full data replication runs until the previous primary system
   is entirely in sync.

3. Verify that the secondary system replication status in All Services is active
   and in sync. You can see this status in the Administration editor on the
   **Overview** tab.

### Conclusion

By using system replication, you can ensure high availability and enable disaster
recovery for your SAP HANA system. Achieve this by continuously replicating the
data from a primary to a secondary system, including in-memory loading. System
replication facilitates rapid failover in the event of a disaster. The main
advantage of SAP HANA replication is a zero-second RPO and a RTO of mere minutes.

<a class="cta purple" id="cta" href="https://www.rackspace.com/sap">Learn more about our SAP services.</a>

Use the Feedback tab to make any comments or ask questions.
