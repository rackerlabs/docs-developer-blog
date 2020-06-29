---
layout: post
title: "Use the Oracle Database refreshable clone feature&reg;Part Two: Demonstration"
date: 2020-06-30 00:01
comments: true
author: Tejaskumar Patel
published: true
authorIsRacker: true
authorAvatar: 'https://s.gravatar.com/avatar/93f8a2afa4b179946cc23ac18a0ff8a5'
bio: "I am a Database Administrator with more than a decade of experience in
various RDBMSs, Big Data and NoSQL database technologies, and the cloud platform."
categories:
    - Oracle
    - database
metaTitle: "Use the Oracle Database refreshable clone feature&mdash;Part Two: Demonstration"
metaDescription: "In this post, I demonstrate how to set up, configure, maintain,
and drop a refreshable clone pluggable database (PDB) in Oracle&reg; 18c"
ogTitle: "Use the Oracle Database refreshable clone feature&mdash;Part Two: Demonstration"
ogDescription: "In this post, I demonstrate how to set up, configure, maintain,
and drop a refreshable clone pluggable database (PDB) in Oracle&reg; 18c"
---

[Part one of the series](https://developer.rackspace.com/blog/use-the-oracle-database-refreshable-clone-feature-part-one-introduction/)
provides an introduction to Oracle&reg; refreshable clones, including when and why
to use them. In this post, I demonstrate how to set up, configure, maintain, and
drop a refreshable clone pluggable database (PDB) in Oracle 18c.

<!-- more -->

### Prerequisites for a refreshable clone PDB

To follow along with this demonstration, complete the following prerequisites:

1. Have a database link for newly created refreshable clone pointing to a local
   or a remote container.

2. Set `archive_log_mode` to `enabled`.

3. Use an engineered system or Enterprise Edition (EE) Oracle Cloud. If it's not available in the same
   platform or version, set the hidden parameter, `_exadata_feature_on`, to `True`
   for this demonstration.

4. Set `local_undo_mode` to `enabled`.

You can set the refreshable PDB in either **CLOSED** or **OPEN READ ONLY** mode
and in **OPEN READ ONLY** mode for queries after a refresh.

### Environment

For this demonstration, make sure your environment conforms to the following
specifications:

- Install Oracle 18c and perform the prerequisites on the machine and database.

- For the role of the production database:

     - Set the container database (CDB) name: **YCDB1**

     - Set the PDB Name: **PURCH_PDB**

- For the role of refreshable clone PDB:

     - Set the CDB Name: **XCDB1**

     - Set the PDB Name: **PDB2_REFRO**

     - Set the PDB to refresh automatically every 30 minutes

- Create a public database link by using `create_pdb` on **XCDB**. The link
  should point to **PURCH_PDB** on **YCDB**.

-Execute the following Transparent Network Substrate (TNS)commands:

    purch_pdb=(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = tejashost2.localdomain)(PORT = 1521))
    (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = purch_pdb)))

    XCDB1=(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = tejashost2.localdomain)(PORT = 1521))
    (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = XCDB1)))

    YCDB1=(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = tejashost2.localdomain)(PORT = 1521))
    (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = YCDB1)))

### Demonstration

This demonstration performs the following activities:

- Sets up the environment.

- Finds the refresh mode of the production database.

- Shows how to the refresh mode of the refreshable clone, including disabling
  refresh on the refreshable clone.

- Switch between production and the refreshable clone.

#### Set up the refreshable clone environment:

For the refreshable clone environment, take the following actions.

##### Actions to take on YCDB1:

1)  Create a production database and open it.

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture1.png %})

2) Import the data from the **EXPDP** dumps that you took by using the `impdb`
   utility or importing an HR schema into **PURCH\_PDB**. For this example,
   import an HR schema by running the following script on the database:

        @?/demo/schema/human_resources/hr_main.sql

After it finishes, validate the HR schema details, as shown in the following figure:

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture2.png %})

##### Actions to take on XCDB1:

1. Create a database link to point to the production database, **PURCH\_PDB**.

2. Create a refreshable PDB, set the refresh period to every 30 minutes, and
   validate that the data refreshed.

You can use all the attributes when you create a PDB that you plan to use to
create a database in another location. For example, to modify a PDB datafile
location, use **CREATE\_FILE\_DEST** or **FILE\_NAME\_CONVERT**.


The only addition is the **REFRESH MODE** attribute. To simplify this demonstration,
I did not add any of the optional attributes.

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture3.png %})

#### Find the refresh mode and production database details

You can query table **DBA_PDBS** to check details of the refreshable PDB mode,
status, last refresh SCN, and its parent production database details. For
**PDB2\_REFRO** PDB, check the output as shown in the following example:

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture4.png %})

After you complete your task, you should convert the refreshable PDB back to
**MOUNTED** mode for a continuous refresh according to the schedule. Use the
following commands to do this activity. The **open_mode.sql** used here is a
query to check the current open_mode of the database.

You might see the following error if you did not close the database instance
for refresh:

`ORA-65025: Pluggable database is not closed on all instances`

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture5.png %})

#### Change the refresh mode of the refreshable clone

You can change the mode of a refreshable clone as follows:

- Change manual refresh to automatic refresh.

- Change automatic refresh to manual refresh.

- Disable refresh from automatic or manual refresh mode.

##### Convert a manual refresh to an automatic refresh and vice versa

**Note**: You cannot change the PDB refresh mode when logged into one other PDB.
For example, you can't change the mode of **XPDB** while logged into **YPDB**.
If you try, the following error occurs:

    ORA-65118: operation affecting a pluggable database cannot be performed from
    another pluggable database.

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture6.png %})

In manual refresh mode, you can refresh your cloned PDB as needed by using the
following command:

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture7.png %})

##### Disable PDB refresh and convert a read-only clone to a read-write-enabled database

You can disable the refresh mode of a PDB to convert your refreshable clone into
read-write mode.

**Note**: After you disable refresh for your pluggable database, you cannot
enable it again. You must re-create the PDB to have it be a refreshable PDB. If
you try to convert from the **NONE** refresh mode to refresh mode, you get the
following error:

    ORA-65261: pluggable database PDB2_REFRO3 not enabled for refresh.

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture8.png %})

After you disable refresh, the PDB has read-write access.

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture9.png %})

#### Switch from production to the refreshable clone and vice versa.

Before Oracle 18c, you needed to perform all the steps to switchover the role,
including shutting the primary and opening it as read-only.

In this demonstration, I do the following:

1) Create user **C##SWITCHUSER** on the container databases XCDB1 and YCDB1 by
   using grant connect, `sysoper`.

2) Create a database link, **dblink**, pointing to another container database.
   In **YCDB1**, create the dblink, **XCDB1SYSOPER**, to connect **XCDB1**.
   Use database views, **DBA\_DB\_LINKS and V$DATABASE** to collect database details
   after creating the database link.

3) Open the refreshable clone database as read-only.

4) Run the switchover command.

5) Validate the database status and open mode after switching the production and
   refreshable clone databases.

##### Actions to take on YCDB1:

Complete prerequisites 1 through 3 before executing the switchover command.

Database link details:

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture10.png %})

##### Actions to take on XCDB1

Check the database link details and find the database **open mode** by using
**DBA\_DB\_LINKS** and **V$DATABASE**.

![]({% asset_path 2020-06-30-use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/Picture11.png %})

After the switchover completes, the original source PDB **PURCH\_PDB** became
the refreshable clone PDB. This PDB is currently in **MOUNT** status, and from
now on, you can open it only in **READ ONLY** mode. In contrast, the original
refreshable clone, PDB **PDB2\_REFRO** is now open in **READ** or **WRITE** mode
and functions as a source PDB.

### Conclusion:

You should not consider the refreshable clone PDB feature as a replacement for
Data Guard from the perspective of high availability. However, you can use a
refreshable clone to maintain a replica database on another server.

This post describes how to use refreshable PDBs as replicas so that you can
resume certain low-load, non-critical applications operations, whether the
switchover is a planned or an unplanned event. Keep in mind, you should consider
the switchovers from the point of view of Recovery Time Objectives (RTOs, time
to resume operations) and Recovery Point Objectives (RPOs, such as achieving
minimal data loss).

Use the Feedback tab to make any comments or ask questions. You can also
[chat now](https://www.rackspace.com/#chat) to start the conversation.

<a class="cta teal" id="cta" href="https://www.rackspace.com/dba-services">Learn more about Databases.</a>
