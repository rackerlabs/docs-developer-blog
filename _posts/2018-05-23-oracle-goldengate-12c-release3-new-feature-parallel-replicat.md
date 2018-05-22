---
layout: post
title: "Oracle GoldenGate 12c release 3 - New feature parallel Replicat"
date: 2018-05-23 00:00
comments: false
author: Ravi Sharma
published: true
authorIsRacker: true
categories:
    - General
---

Parallel Replicat is one of the new features introduced in GoldenGate 12c
Release 3 (12.3.0.1). This new Replicat is designed to help users to quickly
load data into their environments by using multiple parallel mappers and threads.

<!-- more -->

### What is parallel Replicat?

Parallel Replicat is a highly scalable apply engine for the Oracle database that
can automatically parallelize the apply workload and take dependencies between
transactions into account. Parallel Replicat provides all the benefits of
integrated Replicat by performing the dependency computation and parallelism
outside of the database. It parallelizes the reading and mapping of trail files
and provides the ability to apply large transactions quickly. The dependency
computation, parallelism of the mapping, and apply are performed outside of the
database and can be off-loaded to another server. The transaction integrity is
maintained in this process.

In addtiion, the SPLIT\_TRANS_RECS parameter splits a larger transaction into
logically smaller pieces to run parallelly. Dependencies are managed and
maintained as well.


### Parallel replication architecture

The following image illustrates the parallel Replicat architecture:

![List cell command results]({% asset_path 2018-05-23-oracle-goldengate-12c-release3-new-feature-parallel-replicat/Replicat1.png %})
Image source: https://bit.ly/2wsPZVv

The architecture starts by reading a single trail file but provides a wider road
with multiple lanes for reading (mappers) and writing (appliers). The Replicat
ensures that all the transactions are ordered based on the key dependencies
(primary key (PK), foreign key (FK) and unique key (UK)). This is a huge
difference from the integrated Replicat, where the dependency and writing are
done within the database.

Additionally, the parallel Replicat can be configured to run in one of the
following two modes:

- Integrated mode.  This is similar to the integrated Replicat except that the
readers and writers are not external to the database with the integrated mode
of parallel Replicat. This mode still uses the internals of the database to
manage the processes.

- Non-integrated mode. In this mode, the Replicat still runs in parallel;
however, now it is completely outside of the database.

### Parallel Replicat key features

The following features are key for parallel Replicat:

- Is up to 5X faster than integrated Replicat.
- Provides the option to apply a single large transaction in parallel.
- Can parallelize a single large transaction
  –	Processes large transactions faster in parallel
  –	Still considers dependencies while paralleling large transactions
- Can control processing by using the SPLIT\_TRANS_RECS parameter, which
  specifies the transaction split size (in records). The default is 100,000.

### Basic parallel Replicat parameters

The following parameters can be used in parallel Replicat processing:

**MAP_PARALLELISM** - Configures the number of mappers. This parameter controls
the number of threads used for reading the trail file. The minimum value is
``1``, maximum value is ``100``, and the default value is ``2``.

**APPLY_PARALLELISM** - Configures the number of appliers. This parameter
controls the number of connections in the target database that are used for
applying the changes. The default value is ``4``.

**MIN_APPLY_PARALLELISM and MAX_APPLY_PARALLELISM** - The Apply parallelism
function is auto-tuned. You can set a minimum and maximum value to define the
ranges in which the Replicat automatically adjusts its parallelism. There are
no defaults. Do not use this parameter at the same time as the APPLY_PARALLELISM
parameter.

**SPLIT_TRANS_REC** - Specifies that large transactions should be broken into
pieces of a specific size and applied in parallel. Dependencies between pieces
are still honored. This parameter is disabled by default.


### Add non-integrated parallel Replicat with the admin client

Perform the following steps to add non-integrated parallel Replicat with the
admin client:

1. Enter the following commands to open AdminClient:

        $ cd $OGG_HOME/bin
        $ bin> ./adminclient

2. Enter the following command to connect to the Service Manager deployment source:

        adminclient> connect http://<host&gt;:<port> deployment <deploment> as <security user> password <password>

3. Enter the following command to create the parallel Replicat process:

        adminclient> add replicat <group name>, integrated, parallel, exttrail <trail name> checkpointtable ggadmin.ggcheckpoint

**Note**: After the Replicat is created, it automatically shows up in the
associated Administration Service.

4. Enter the following command to edit the parameter file:

        adminclient> edit params <replicat name>

5. Enter the following command to start the parallel Replicat process:

        adminclient> start replicat <replicat name>

After the Replicat starts, the number of threads that you specified for readers
(mappers) and writers (appliers) are shown in the report files.

### Sample parameter file

The following code is a sample parameter file for parallel Replicat:

    replicat REP1
    userid ggadmin, password ****
    INSERTUPDATES
    REPERROR(1, DISCARD)
    MAP_PARALLELISM 2
    MIN_APPLY_PARALLELISM 2
    MAX_APPLY_PARALLELISM 8
    SPLIT_TRANS_RECS 100
    MAP *.*, TARGET  *.*;

### Conclusion

GoldenGate is already a great replication tool from Oracle that provides
heterogeneous replication between different types of databases or platforms.
Oracle has added  an extra advantage to the GoldenGate technology with parallel
Replicate.

Parallel Replicat is a new variant of Replicat that applies transactions in
parallel to improve system performance. Parallel Replicat provides all the
benefits of integrated Replicat by performing the dependency computation and
parallelism outside the database. It reads  and maps  all trail files in
parallel and provides the ability to apply large transactions quickly in Oracle
Database version 11g (11.2.0.4) and above.

