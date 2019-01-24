---
layout: post
title: "Oracle EBS applications for disaster recovery"
date: 2019-01-24 00:00
comments: true
author: Ajay Sharma
published: true
authorIsRacker: true
categories:
  - database
  - Oracle
metaTitle: "Oracle EBS Applications disaster recovery"
metaDescription: "Oracle EBS Applications disaster recovery set up."
ogTitle: "Oracle EBS Applications disaster recovery"
ogDescription: "Oracle EBS Applications disaster recovery set up."
---

This blog covers the creation and maintenance of disaster recovery (DR) systems
for Oracle&reg; Enterprise Business Suites (EBS) applications and describes a
generic process to create a version 12.2 applications DR system by using version
12.2.5 systems in the test area.

<!-- more -->

### Introduction

The steps to create a DR application site are similar to the ones used to create
a clone system. In case of a disaster, you need to make a few changes to XML
files, such as host names, and the system will be ready to run. To keep the
system in sync, run any synchronizing scripts, such as`rsync`, which update the DR
site with any changes. Apply patches to the DR DB databases as well as to the
DR site application nodes.

In the following steps, notice that the physical standby database is already
configured with the primary database server and that they both are in sync.

### DR configuration steps

This article explores the following high-level steps to configure the DR system:

1.	Disable archiving and convert the DR system from *physical standby* mode to
   *snapshot standby* mode.
2. Copy the applications from the primary site to the DR site by running
   `preclone`.
3.	Configure node1 with `dualfs`.
4.	Add extra nodes to match the PROD site.
5. Check the services by starting  and shutting down node1.
6.	Set the DR system back to physical standby mode after the applications
   DR is set up.

#### 1. Set the DR system to snapshot standby mode

Run the following code to disable log apply and set the DR database to standby
snapshot mode:

    $ dgmgrl /
    $ edit database "TESTDR" set state=apply-off;

Run the following code to configure the standby database to use flashback
logging for flashback database operations:

    SQL> alter system set db_recovery_file_dest_size=1000G scope=both;
    SQL> alter system set db_recovery_file_dest='+FRA' scope=both;
    SQL> alter system set db_flashback_retention_target=1440 scope=both;

    $ Shutdown node2 DR DB
    $ sqlplus '/as sysdba'

    SQL> shutdown immediate;

Run the following code on node1 of the DR DB:

    $ sqlplus '/as sysdba'

    SQL> shutdown immediate;

    SQL> startup mount;
    SQL> alter database convert to snapshot standby;
    SQL> alter database open;
    SQL> select name, DB_UNIQUE_NAME, OPEN_MODE, DATABASE_ROLE from v$database;

    NAME      DB_UNIQUE_NAME                 OPEN_MODE            DATABASE_ROLE
    --------- ------------------------------ -------------------- ----------------
    TESTPRD  TESTDR                        READ ONLY WITH APPLY              SNAPSHOT STANDBY

Run the following code to startup node2 of the DR DB in mount mode:

    $ sqlplus '/as sysdba'

    SQL> startup  mount;

#### 2. Run preclone and clean up fnd_nodes

Run the following code to clean up the `fnd_nodes`:

    SQL> exec fnd_conc_clone.setup_clean;
    SQL> exec ad_zd_fixer.clear_valid_nodes_info;

Run `auto-config` on the DR DB nodes in the following sequence: node1, node2,
node1.

Run `preclone` on the PROD applications tier and copy the applications files
from the RUN file system (FS) node1 to the corresponding DR applications tier
node1 FS.

#### 3. Run dualfs

On the node1 DR applications tier, browse to the FS and run the following code:

    $ perl adcfgclone.pl appsTier dualfs from <APPL_BASE>/<SID>/apps/<RUN-FS>/EBSapps/comn/clone/bin

If you see the following prompt, the `adcfgclone` completed successfully and
you can ignore any autoconfiguration errors:

    Do you want to startup the Application Services for ……..? (y/n) [n] :

#### 4. Add nodes to match the PROD site

On each applications node, copy the `env` files from PROD to the equivalent
DR nodes.  Run the following code, making any required directory or file name
changes:

    $ scp prodnode1:/home/applmgr/prodprd.env /home/applmgr/proddr.env
    $ scp prodnode1:/home/applmgr/prodprd_run.env /home/applmgr/proddr_run.env
    $ scp prodnode1:/home/applmgr/prodprd_patch.env /home/applmgr/proddr_patch.env

Repeat the preceding commands for all other nodes.

Source `env` and run `auto-config` for RUN and PATCH FS. The following example
shows the expected results:

    Configuring OZF_TOP.......COMPLETED
    Configuring CSD_TOP.......COMPLETED
    Configuring IGC_TOP.......COMPLETED

    AutoConfig completed successfully.

    Configuring OZF_TOP.......COMPLETED
    Configuring CSD_TOP.......COMPLETED
    Configuring IGC_TOP.......COMPLETED

    AutoConfig completed with errors.

**Note:** Ignore any PATCH FS errors.

#### 5. Test

Run the following code to test the configuration by cycling the first node:

    $ . ./proddr.env
    $ cd $ADMIN_SCRIPTS_HOME
    $ ./adstrtal.sh apps/<passwd>

Run the following code to check the URL, login, and shutdown applications:

    $ cd $ADMIN_SCRIPTS_HOME
    $ ./adstpall.sh apps/<passwd>

Similar to the normal cloning process, add additional nodes to match the
PROD infrastructure. Run `preclone` on the target node1, RUN, and PATCH FS.
Then, add nodes. Start the admin server services for RUN and PATCH FS and run
`preclone` as shown in the following code:

    $ . ~/testdr.env
    $ cd $ADMIN_SCRIPTS_HOME
    $ ./adpreclone.pl appsTier
    $ . ~/testdr_patch.env
    $ cd $ADMIN_SCRIPTS_HOME
    $ ./adpreclone.pl appsTier
    $ cd  <RUN_FS_TOP>/EBSapps/comn/clone/bin
    $./adclonectx.pl addnode contextfile=<NODE1_RUNFS_CONTEXT.xml> pairsfile=/common_area/applcsf/testprd/pairsfile/mypairsfile.txt
    dualfs=yes

Run the following code to configure node2:

    $ cd  <RUN_FS_TOP>/EBSapps/comn/clone/bin
    $ ./adclonectx.pl addnode contextfile=<NODE1_RUNFS_CONTEXT.xml> pairsfile=/common_area/applcsf/testprd/pairsfile/mypairsfile.txt
    dualfs=yes
    $ perl $FND_TOP/patch/115/bin/txkSetAppsConf.pl \
      -contextfile=<RUN-FS-CONTEXT.xml \
      -configoption=addMS \
      -oacore=testdr2.sherwin.com:<port> \
      -oafm=testdr2.sherwin.com:<port> \
      -forms=testdr2.sherwin.com:<port> \
      -formsc4ws=testdr2.sherwin.com:<port>    -- All ports information is available in context file.

Similarly, add other nodes or external tiers to match the PROD system.

#### 6. Convert the DR system to physical standby mode

After you add all the nodes, shut down all services down on the DR
system, convert the DR DB back to physical standby mode, and set dataguard
to `ON`.

Run the following code to shut down services on the DR DB, startup the mount,
and convert the DR DR to physical standby mode:

    SQL> alter database convert to physical standby;
    DGMGRL> edit database "TESTDR" set state=apply-on;

Validate the synchronization.  You should expect to see results similar to the
following example:

    ### Monitor to see Transport Lag and Apply Lag to be:
    Transport Lag:      0 seconds (computed 0 seconds ago)
    Apply Lag:          0 seconds (computed 0 seconds ago)

### Conclusion

This blog describes how to prepare for a disaster on EBS applications with a
validated DR site. After updating a few parameters in the context file, the
system is up and running. You don't need to maintain a backup of all the
application systems and then restore the systems from the backup. You might want
to set up `rsync` processes between the PROD and DR sites and apply DB and AD
Online Patching (ADOP) patches to the DR site at the same time that you apply
them to the PROD site.

<table>
  <tr>If you liked this blog, share it by using the following icons:</tr>
  <tr>
   <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://twitter.com/home?status=https%3A//developer.rackspace.com/blog/Oracle-EBS-applications-disaster-recovery/">
        <img src="{% asset_path shareT.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.facebook.com/sharer/sharer.php?u=https%3A//developer.rackspace.com/blog/Oracle-EBS-applications-disaster-recovery/">
        <img src="{% asset_path shareFB.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.linkedin.com/shareArticle?mini=true&url=https%3A//developer.rackspace.com/blog/Oracle-EBS-applications-disaster-recovery&summary=&source=">
        <img src="{% asset_path shareL.png %}">
      </a>
    </td>
  </tr>
</table>

</br>

Learn more about our [database services](https://www.rackspace.com/dba-services).

If you have any questions on the topic, comment in the field below.

