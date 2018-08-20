---
layout: post
title: "Rolling back OMS 13c to version 12c"
date: 2018-08-20 00:00
comments: true
author: Amit Kumar Srivastava
published: true
authorIsRacker: true
categories:
    - General
---

Originally published by TriCore: January 17, 2017

This blog post discusses why Oracle&reg; Enterprise Manager 13c (OEM 13c) users
might want to consider rolling back to version 12c, and how to make the
transition successful.

<!-- more -->

### Introduction

Change can occur in many different ways. It might come forcefully like a tidal
wave, or creep along incrementally like a glacier. Technology advances in both
of these ways. Although change can be difficult, it’s often for the best.
Accomplishing great things requires us to push beyond our comfort zones.

Rolling back a system after an upgrade is one such change. For example,
TriCore, which Rackspace acquired in 2017, implemented a restoration and
recovery rollback for Oracle Management Service (OMS), Oracle Management
Repository (OMR), and Oracle Management Agent (OMA) in 2017.

TriCore came to this decision after using version 13c for some time
because they felt that it wasn't stable. For example, they experienced
certain issues that didn't occur on version 12cR5. As a result, they
decided to roll back completely to the 12cR5 environment.

You might be having a similar experience with OEM 13c. If you are, know that
while rolling back can be painful in the short-term, it will yield positive
results in the long run.  

![A visualization of the OMS rollback from 13c
to 12c]({% asset_path 2018-08-20-oms-rollback/picture1.png %})

### Details on TriCore's rollback

TriCore upgraded OEM 13c to a new environment by using the direct upgrade
method. They used the old OMR backup for repository restoration. The backup
configuration file for OMS 12c was used to roll back the changes to OMS.

If you want to roll back in the same way, you can complete the process in three
phases.

### Phase 1: Use Recovery Manager (RMAN) to restore the system

Restore the OMR backup that you took before the upgrade to version 13c.

Use the following steps to accomplish this task:

1. Configure the listener, Transparent Network Substrate (TNS) alias, and
   services with the pre-migration setup that you had for version 12c.

    After you've restored the existing OMR backup, OMS configuration is also
    restored (such as `emkey` and other parameters).

2. Next, install the OMS 12cR5 binary and use Oracle Management Server
   Configuration Assistant (OMSCA) to recover the OMS configuration.

3. Finally, re-point the centralized agent and deployed the target agent on all
   servers.

This example uses OMR and OMS on the same server. If you want, you can change
the repository server.

You can use any of the following methods to restore the repository database
from the backup:

- RMAN backup restoration and recovery
- Export and import
- Oracle Data Guard with broker
- Cold backup

### Phase 2: Move OMS and agents to a new host

This section describes how to move OMS and agents to a new host.

**Configure the repository**

Use the following steps to configure the repository:

1. On the new server, restore the OMR repository database and configure the
   listener and the TNS alias and services.

    **Note**: Ensure that you copy and install the latest required plugins and
    that you recreate the same directory structure on the new server.

2. Because you're reverting the OMS, choose ``Installed Software Only``.

3. After the binary installation is complete, run the `orainstRoot.sh` script
   to complete the installation.  

4. Enter the following command to copy the OMS configuration backup file to
   this server:

       ```
       [oracle@oem251 ~]$ cp /ora_global_nfs/BACKUP/REPDB_BACKUP/opf_ADMIN_20160303_105032.bka /backup/opf_ADMIN_20160303_105032.bka  
       ```

**Recreate the OMS with OMSCA**

Use the following steps to recreate the OMS:

1. Shut down everything on your old 13c server.

2. Use the backup configuration and the following OMSCA command to
   recreate the OMS:  

       ```
       oms:/u02/app/oracle/Middleware/oms:N
       REPDB:/u01/app/oracle/product/12.1.0.2/DB_1:N

       [oracle@oem251 ~]$ omsca recover -as -ms -nostart -backup_file /ora_global_nfs/BACKUP/REPDB_BACKUP/opf_ADMIN_20160303_105032.bka
       ```

### Phase 3: Configure the central agent on the new host

Use the following steps to configure the central agent on the new host:

1. Enter the following command to set up the central agent on the new
   host:  

       ```
       [oracle@oem251 agent_inst]$ /u02/app/oracle/Agent12c/core/12.1.0.5.0/sysman/install/agentDeploy.sh
       AGENT_BASE_DIR=/u02/app/oracle/Agent12c AGENT_INSTANCE_HOME=/u02/app/oracle/Agent12c/agent_inst AGENT_PORT=3872 -configOnly OMS_HOST=oem251.ora.com EM_UPLOAD_PORT=4903 AGENT_REGISTRATION_PASSWORD=********
       ```

2. Enter the following command to run the `root.sh` script and finish creating
   the central agent:

       ```
       [oracle@oem251 agent_inst]$ sudo /u02/app/oracle/Agent12c/core/12.1.0.5.0/root.sh
       ```
3. Log in to OMS by using the Oracle Enterprise Manager command-line interface
   (emcli) and sync the repository.

4. Use the following command to relocate the repository target to the new OMS
   host:

       ```
       [oracle@oem251 agent_inst]$ emctl config emrep -agent oem251.ora.com:3872
       ```

**Point the deployed target to the new host**

Use the following command to reconfigure existing agents to re-secure them
against the new OMS. If you're working with a large environment, you can do
this with a shell script.

    ```
    [oracle@vm212 bin]$ ./emctl secure agent -emdWalletSrcUrl "https://oem251.ora.com:4903/em"
    ```

Step through each of your existing agents to re-secure them against the new
OMS. Again, if you have a large environment, you can use a shell script to
perform this task on all of your agents at the same time.

![A visualization of the three phases involved in the
rollback ]({% asset_path 2018-08-20-oms-rollback/picture2.png %})

### Verify that everything is working correctly

Verify the status of each agent after re-pointing it to the new host. After all
agents are re-pointing to the new OMS, verify the details through the OEM web
console.

Also verify that the administration group has been migrated from the old OMS
to the new OMS.

### Conclusion  

Oracle Enterprise Manager 12c provides the most comprehensive management
solution for Oracle environments, including both traditional and cloud
computing architectures. It also offers monitoring and administration
capabilities.  

While a rollback can be daunting, careful planning will make things go more
smoothly. Using the methods described in this blog post will help you revert
changes with minimal impact. 

If you run into problems during your rollback, contact [Oracle
Support](https://support.oracle.com/) and submit a service request.
