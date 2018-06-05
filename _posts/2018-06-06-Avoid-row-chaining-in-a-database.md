---
layout: post
title: "Avoid row chaining in a database"
date: 2018-06-06 00:00
comments: true
author: Mukesh Kumar
published: true
authorIsRacker: true
categories:
    - General
---

Row chaining is a bottleneck that causes disruption in the database performance.
We should do our best to avoid row chaining as much possible. In this blog, I
am going to discuss row chaining, how to identify it, and how to remove or avoid
it completely.

<!-- more -->

### Introduction

Normally, we encounter row chaining when the size of a database row is larger
than the size of the database block used for storing it. In this situation, the
row is split across more than one database block. When you need to access this
row, the system traverses more than one database block, resulting in more I/O
operations, as shown in the following illustration:

![]({% asset_path 2018-06-06-Avoid-row-chaining-in-a-database/Picture1.png %})

Figure 1: Block chain illustration

### Basic assumption to test the scenario:

Before we start, we need to alter an initialization parameter. Assuming the
default block size is 8KB. Execute the following code to set this parameter to
allocate a memory buffer dedicated to store database blocks of different sizes:

    ALTER SYSTEM SET DB_16K_CACHE_SIZE =16M SCOPE=BOTH;

### Row chaining demonstration

To better understanding row chaining, use the following steps to create a new
tablespace using a larger block size and move the table into the newly created
tablespace to gather the statistics.

1.	Create the table BIG\_ROWS with the following command:

        CREATE TABLE HR.BIG_ROWS (
		     Id number not null,
		     Field1 char(2000) default ‘A’ not null,
           Field2 char(2000) default ‘B’ not null,
		     Field3 char(2000) default ‘B’ not null,
		     Field4 char(2000) default ‘D’ not null,
		     Field5 char(2000) default ‘E’ not null,
		     Constraint pk_big_rows primary key (id));

2.	Populate the table with the following command:

        INSERT INTO HR.BIG_ROWS (ID) SELECT ROWNUM FROM SYS.DBA_OBJECTS WHERE ROWNUM<101;

3.	Analyze the table to refresh the statistics with the following command:

        ANALYZE TABLE HR.BIG_ROWS COMPUTE STATISTICS;

4.	Verify if there are chained rows with the following command:

        SELECT CHAIN\_CNT FROM ALL\_TABLES WHERE OWNER=’HR’ AND TBALE\_NAME=’BIG_ROWS’;

   ![]({% asset_path 2018-06-06-Avoid-row-chaining-in-a-database/screenshot.png %})

   Figure 2: Results of select command

6.	Create a tablespace with a different block size with the following command:

        CREATE TABLESPACE TS\_16K BLOCKSIZE 16K DATAFILE ‘TS_16K.DBF’ SIZE 30M EXTENT MANAGEMENT LOCAL UNIFORM SIZE 1M;

7.	Move the table BIG_ROWS to the tablespace just created with the following command:

        ALTER TABLE HR.BIG_ROWS MOVE TABLESPACE TS_16K;

8.	Rebuild the indexes as they are unusable after the move with the following command:

        ALTER INDEX HR.PK_BIG_ROWS REBUILD;

9.	Analyze the table to refresh the statistics with the following command:

        ANALYZE TABLE HR.BIG_ROWS COMPUTE STATISTICS;

10. Validate if row chain still exists with the following command:

        SELECT CHAIN\_CNT FROM ALL\_TABLES WHERE OWNER=’HR’ AND TABLE\_NAME=’BIG_ROWS’;

    ![]({% asset_path 2018-06-06-Avoid-row-chaining-in-a-database/screenshot2.png %})

    Figure 3: Results of select command

### Index rebuild after moving a table

After moving a table, such as in the preceding example, you should do an index
rebuild. An index contains the row ids of the table rows, and the row ids identify the
position of the row.  The position is composed of the objects, the datafile,
the block number, and the slot (row) number. When we move a table, the datafile
and the block number changes, so the indexes must be rebuilt.

Row chaining leads to poor performance because accessing a row in the database
requires the system to read more than once DB block, even when accessing the
table by the index lookup. When introducing different block sizes in the
database, keep in mind the pros and cons of a larger block size. The larger the
block size, the more likely that contention issues occur with on the database
block.

There are also advantages in using multiple block sizes, such as the following:

- Contention reduction
- Reduced chaining
- Faster update
- Reduced pinging
- Less disk space waste
- Less RAM Waste
- Minimum redo-generation
- Faster scan

Chained rows affect index reads and full table scans. Following are a few
points to keep in mind:

- Row chaining is typically caused by insert operations.
- SQL statements which create or query chained rows degrade performance because
  of the additional I/O operations.
- To diagnose chained or migrated rows, use the analyze command and query the
  ``V$SYSSTAT`` view.
- To remove chained rows, set a higher PCTFREE value by using the alter table
  move command.

One of the sources for this post is:
[https://www.akadia.com/services/ora_chained_rows.html](https://www.akadia.com/services/ora_chained_rows.html)

