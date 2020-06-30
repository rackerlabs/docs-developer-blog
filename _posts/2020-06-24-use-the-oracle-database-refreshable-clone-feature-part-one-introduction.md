---
layout: post
title: "Use the Oracle Database refreshable clone feature&mdash;Part One: Introduction"
date: 2020-06-24 00:01
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
metaTitle: "Use the Oracle Database refreshable clone feature&mdash;Part One: Introduction"
metaDescription: "This post describes the practical use of refreshable clones
with manual and automatic switchover cases."
ogTitle: "Use the Oracle Database refreshable clone feature&mdash;Part One: Introduction"
ogDescription: "This post describes the practical use of refreshable clones with
manual and automatic switchover cases."
---

The Oracle® Database 18c for Enterprise Edition on Cloud bundles
engineered systems (Exadata) with many new and improved features. Release 18c
improves the refreshable clone feature from the 12c release 2 by adding a quick
switchover or failover facility. You can also create a snapshot carousel to clone
or replicate pluggable databases (PDBs) in a multitenant environment.

<!-- more -->

For production environments, use a snapshot carousel with the refreshable clone
PDB feature to make database administration (DBA) activities easy, such as
safeguarding against an unforeseen outage or troubleshooting logical corruption
issues. This post describes the practical use of refreshable clones with manual
and automatic switchover cases. You can use it with the snapshot carousel feature
to identify and handle the following database health problems:

- Production database unavailable

- Performance issues

- Logical corruption in the Oracle database

This post is part one of a two-part blog post series. Read on to learn about the
refreshable clone PDB, how it works, and when to use it.

The second part of the series describes how to create, configure, maintain,
and drop a refreshable clone PDB.

### Cloning and snapshot questions

This section provides answers to some basic questions about clone and
snapshot carousels.

#### What is cloning?

When you clone an instance, you take a backup of it and restore the backup
elsewhere. Typically, you restore it on another machine with the same directory
structure. You can also restore it on the same machine by changing the Oracle
System ID (SID) and the database name. You can use a clone of a production
instance on a test machine to try out what-if scenarios, such as changing the
`init.ora` parameter or altering your code, and so on.

#### How does PDB cloning work?

You can use PDB cloning to clone a PDB in a multitenant environment. For local
or remote PDBs, use a refreshable clone or snapshot carousel to create PDB clones
in a local container database.

For remote PDB cloning, consider the following:

- To use a refreshable clone, you need to have a database link for the PDB and
  disable the cloned database.

- To use a snapshot carousel, you need to create a typical PDB clone by using a
  snapshot. Then, use the database links or unplug and plug into another
  container database. You can also create a refreshable clone from a cloned PDB.

#### What is a PDB snapshot?

A PDB snapshot is a point-in-time copy of a PDB. Create snapshots manually by
using the `SNAPSHOT` clause of `CREATE PLUGGABLE DATABASE`
(or `ALTER PLUGGABLE DATABASE`) command, or automatically by using the `EVERY`
interval clause.

#### What is a PDB snapshot carousel?

A PDB snapshot carousel maintains a library of recent PDB snapshots that you can
use to perform a point-in-time recovery and to clone a PDB.

### Refreshable clone PDB

You can clone the PDB by using the refreshable clone feature, which protects
the database from data corruption and disasters with minimal data loss, depending
on the refresh interval and redo generation rate. You can use the refreshable
clone database as a replica on which to resume certain low-load, non-critical
applications. You can set the refreshable clone database to update automatically
at set intervals or manually by using redo log application.

Figure 1 shows the architecture of refreshable clone processing. It shows the
main components and processes and illustrates the relationship between the
production database and the refreshable clone database. This diagram shows cloning
the pluggable database **PDB1** of container database **CDB1** to another
container database **CDB2**. This action results in a hot-cloned version of
**PDB1** named **PDB1\_REF\_CLONE**.

![Figure 1]({% asset_path 2020-06-24-use-the-oracle-database-refreshable-clone-feature-part-one-introduction/Picture1.png %})

**Figure 1**

### Refresh mode options

You can change refresh modes by setting up an environment with the following modes:

- `MANUAL`

- `AUTOMATIC` (using `EVERY` *n* `MINUTES`)

- `NONE`

### Create and work with a refreshable clone

Use the following statement to clone the source PDB and configure the clone to
be refreshable. Refreshing the clone PDB updates it with redo data accumulated
since the last redo log apply.

    CREATE PLUGGABLE DATABASE ... REFRESH MODE [ MANUAL / AUTOMATIC (using EVERY n MINUTES) / NONE ] ;

Use the following statement to change the current mode of a refreshed or
disabled refreshable clone and convert it to a fully functional PDB:

    ALTER PLUGGABLE DATABASE ... REFRESH MODE [ MANUAL / AUTOMATIC (using EVERY n MINUTES) / NONE ] ;

If you don't clone PDBs frequently to avoid performance degradation, the clone
data gets stale. A refreshable clone PDB solves this problem. When a refreshable
clone gets stale, you can quickly refresh it with a recent redo.

Typically, you maintain a *master* refreshable clone of a production PDB and
then take snapshot clones of the master for development and testing.

Use the following statement to reverse the roles for source and clone PDBs:

    ALTER PLUGGABLE DATABASE ... SWITCHOVER;

You can simplify this switchover process, as shown in the following figures:

![Figure 2]({% asset_path 2020-06-24-use-the-oracle-database-refreshable-clone-feature-part-one-introduction/Picture2.png %})

**Figure 2**

![Figure 3]({% asset_path 2020-06-24-use-the-oracle-database-refreshable-clone-feature-part-one-introduction/Picture3.png %})

**Figure 3**

This switchover capability is useful in the following situations.

#### Planned switchover of a refreshable clone

In Figure 3, **CDB1**, which hosts the source PDB, **PDB1**, might experience
significantly more overhead than **CDB2**, which hosts the clone PDB,
**PDB1\_REF\_CLONE**. To achieve better load balancing, you can reverse the roles
of PDBs by converting the clone to the new source PDB and the source PDB into
the new clone.

Execute this role transition by using the following command on the current
primary database:

    ALTER PLUGGABLE DATABASE PDB1 REFRESH MODE EVERY 2 MINUTES FROM PDB1_REF_CLONE@DBLINK2CDB2 SWITCHOVER;

After this command completes, **PDB1\_REF\_CLONE** in **CDB2** assumes the
primary role. **CDB1** now maintains the replica. All connections to production
connect to the new primary, which is now **CDB2**. You lose no more than two
minutes of transactions, assuming that the refreshes kept up with the redo
generation rate from the source.

#### Unplanned switchover of a refreshable clone

If the source PDB has an unplanned failure, you can switch the clone PDB to the
new source PDB and resume the normal operations.

Be sure to test your environment by using realistic transaction volumes to ensure
that the process of refreshing the replica can keep up with the redo generation
rate.

### How do refreshable clones differ from Data Guard?

Oracle introduced the high availability feature with Data Guard and standby
databases. The following elements distinguish refreshable clones from Data Guard:

- Data Guard provides high availability to protect the database from disasters
  and data corruption in real-time provided switchover and failover to standby
  databases. You can also use a Data Guard standby database for load sharing by
  using the refreshable clone PDB feature. Data Guard works at a CDB level, and
  you can't have a switchover or failover at the PDB level.

- Because of the lag between the initiation and completion of the switchover,
  Data Guard is more effective than just maintaining a refreshable clone. During
  this lag, transactions to the primary database might not be applied to or
  synced with the read-only database before you switch the roles. As a result,
  you might lose those transactions.

- Data Guard has a maximum limit of 30 standby databases, but you can have as
  many refreshable clones as you need.

To strengthen the refreshable clone PDB feature for high availability and have
almost no data loss, set the `REMOTE_RECOVERY_FILE_DEST` parameter to archive
the source PDB's log location.

### Conclusion

You should not consider the refreshable clone PDB feature as a replacement for
Data Guard from the perspective of high availability. However, you can use a
refreshable clone to maintain a replica database on another server.

This post described how to use refreshable PDBs as replicas so that you can
resume certain low-load, non-critical applications operations, whether the
switchover is a planned or an unplanned event. Keep in mind that you should consider
the switchovers from the point of view of Recovery Time Objectives (RTOs, time
to resume operations) and Recovery Point Objectives (RPOs, such as achieving
minimal data loss).

[Part Two of the series](https://developer.rackspace.com/blog/use-the-oracle-database-refreshable-clone-feature-part-two-demonstration/)
demonstrates the refreshable clone feature.

Use the Feedback tab to make any comments or ask questions. You can also
[chat now](https://www.rackspace.com/#chat) to start the conversation.

<a class="cta teal" id="cta" href="https://www.rackspace.com/dba-services">Learn more about Databases.</a>
