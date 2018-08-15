---
layout: post
title: "Rollback of OMS from 13c to 12c"
date: 2018-08-16 00:00
comments: true
author: Amit Kumar Srivastava
published: true
authorIsRacker: true
categories:
    - General
---

Originally published by TriCore: January 17, 2017

SUMMARY  

<!-- more -->

### Introduction

Change can occur in many different ways. It might come forcefully like a tidal
wave, or creep along incrementally like a glacier. Technology advances in both
of these ways. Although change can be difficult, it’s often for the best.
Accomplishing great things requires us to push beyond our comfort zones.

The Oracle Management Service (OMS), Oracle Management Repository (OMR), and
Agent restoration and recovery rollback is one such change. While it might be
a challenge in the short-term, it will yield positive results in the long
run.  

![A visualization of the OMS rollback from 13c
to 12c]({% asset_path 2018-08-16-oms-rollback/picture1.png %})

### Details  

We have upgraded Oracle&reg; Enterprise Manager Cloud Control 13c (OEM13c) to a new environment by using the direct upgrade method. We came to this decision after some time using the current version because we feel that it's not stable. For example, we've experience certain issues that we never encountered on version 12cR5. As a result, we decided to rollback completely to the existing 12cR5 environment.

We use the old OMR backup for repository restoration. For OMS, we use the
backup configuration file for OMS12c to roll back the changes.

We can achieve this task in three phases.

### Phase 1

Here we use Recovery Manager (RMAN) to restore the approach.

We need to restore the OMR backup that we took before the upgrade to version 13c. Steps include: Configure listener, TNS alias and services as per our existing setup.

Once we have restored the existing OMR backup, it has all configuration related to OMS like emkey…. etc.  The next step is to install the OMS 12cR5 binary and recover the OMS configuration via OMSCA to achieve the goal.

After that we just need to repoint the centralized agent and deployed target agent on all server.

In this scenario we are using OMR and OMS on same server. We can change the repository server if we want.

Restoring Repository Database from Backup, we can choose any below mentioned approach as per our convenience.

1. RMAN Backup restoration and recovery
2. Export and Import
3. Data Guard with broker
4. Cold Backup

#### Phase 2

Use the following steps to complete phase 2.

OMS Movement and Configuration Agent to New Host

Repository Configuration:

In new server we have to restore the OMR repository database and configure the listener and TNS alias/services.

We ensure that latest and required plugins has been copied and installed and same directory structure has been created on new server. Because we are reverting the OMS then we choose the Installed Software Only. After binary installation run the orainstRoot.sh co complete the installation task.  

Copy the OMS Configuration backup file to this server.

[oracle@oem251 ~]$ cp /ora_global_nfs/BACKUP/REPDB_BACKUP/opf_ADMIN_20160303_105032.bka /backup/opf_ADMIN_20160303_105032.bka  

Recreate the OMS with OMSCA

Shutdown everything on your old 13c.

Recovering/recreating OMS using backup configuration via omsca  

oms:/u02/app/oracle/Middleware/oms:N
REPDB:/u01/app/oracle/product/12.1.0.2/DB_1:N

[oracle@oem251 ~]$ omsca recover -as -ms -nostart -backup_file /ora_global_nfs/BACKUP/REPDB_BACKUP/opf_ADMIN_20160303_105032.bka

### Phase 3

Use the following steps to complete phase 3.

Configure the Central Agent on the New Host  

[oracle@oem251 agent_inst]$ /u02/app/oracle/Agent12c/core/12.1.0.5.0/sysman/install/agentDeploy.sh
AGENT_BASE_DIR=/u02/app/oracle/Agent12c AGENT_INSTANCE_HOME=/u02/app/oracle/Agent12c/agent_inst AGENT_PORT=3872 -configOnly OMS_HOST=oem251.ora.com EM_UPLOAD_PORT=4903 AGENT_REGISTRATION_PASSWORD=********


Run the root.sh script to complete the central agent creation part.


[oracle@oem251 agent_inst]$ sudo /u02/app/oracle/Agent12c/core/12.1.0.5.0/root.sh

Log in to OMS using emcli and sync the repository.

Relocate the repository target to the new OMS host.

[oracle@oem251 agent_inst]$ emctl config emrep -agent oem251.ora.com:3872



Repointing/Reconfiguring (Agent) deployed target from old host to new host

Reconfigure existing agents to re-secure them against the new OMS. Since it’s a large environment we can de done through a shell script.


[oracle@vm212 bin]$ ./emctl secure agent -emdWalletSrcUrl "https://oem251.ora.com:4903/em"

Step through each of your existing agents to re-secure them against the new OMS. If you have A large environment, then this can be done through a  shell script in one go.

![A visualization of the three phases involved in the
rollback ]({% asset_path 2018-08-16-oms-rollback/picture2.png %})

### Validations

Verify the agent status after the re-pointing to new host. Once all agents are repointing to new OMS, verify the details on EM web console.

Also verify the migrated Administration group from OLD OMS to NEW OMS.

### Conclusion  

Oracle Enterprise Manager12c provides the most comprehensive management solution for Oracle environments, including traditional as well as cloud computing architectures. It also provides the monitoring and administration.  
Post new technology upgrades in an environment, it is not easy to revert the changes without proper planning and can be daunting. However, with the above methodology you can best plan to revert changes with minimal impact. Oracle provides best service levels for traditional approach for cloud applications through business-driven monitoring application management.  

If you run into problems, you can contact Oracle Support and file service requests.    
