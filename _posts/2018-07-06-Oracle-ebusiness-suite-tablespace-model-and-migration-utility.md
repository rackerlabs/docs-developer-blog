---
layout: post
title: "Oracle E-Business Suite Tablespace Model and migration utility"
date: 2018-07-06 00:00
comments: true
author: Dilip Singh
published: true
authorIsRacker: true
categories:
  - Oracle
  - database
---

This blog covers the process for converting a version 11i database
to an Oracle&reg; Applications Tablespace Model (OATM) by using an OATM
migration utility that has 12 locally managed tablespaces for all products.

<!-- more -->

### Introduction

OATM was introduced in Oracle Applications and is also referred to as a
consolidated tablespace model. It utilizes 12 consolidated tablespaces (including
three system tablespaces: temporary, system, and undo segments) and provides
support for locally managed tablespaces. OATM was introduced in Release 11i.10.
Prior to 11i releases of Oracle E-Business Suite, each product was allocated
two tablespaces, one for data and one for indexes.

The migration utility is a menu-based PERL program and a series of sizing
estimate reports that enables conversion of Oracle E-Business Suite application
schemas in either a single comprehensive migration or a phased, schema-by-schema
migration. Oracle recommends performing a single comprehensive migration, but
this requires significant down time and disk space. Oracle does not support the
partial migration of tablespaces. When performing a phased schema-by-schema
migration, you must still migrate all schemas.

The following list shows some benefits of OATM:

-   Fewer and more consolidated tablespaces
-   Locally-managed tablespaces
-   Accounts for the I/O characteristics of an object
-   Reclaims space after migration
-   Real Application Cluster (RAC) support

The following sections cover prerequisites for the migration, installation of
the OATM migration utility, and running the migration.

### Prerequisites for OATM migration

Before starting an OATM migration, take the following actions:

-  Ensure that your Oracle database version is RDBMS 9.2.0.4 or higher.
-  If your database Version is 9.2.0.6, run this commmand: ``$FND_TOP/patch/115/sql/fndupglb.sql``
-  Unregister any custom schemas that you don’t want to migrate, such as
   non-Oracle schemas that are registered with Oracle Applications, by disabling
   those schemas.  Other schemas that you might want to disable include ``XXBOL``
   and ``XXCON``.
-  Because the CTXSYS schema is not an APPS schema, register it by using the
   following steps:

   1) From the menu, select **System Administrator Responsibility -> Security -> ORACLE -> Register**.
   2) Select ``Schema CTXSYS`` and set the privilege to ``Enabled``.

### Install the OATM migration utility

This section provides the installation steps.

#### Step 1: Apply the patch and settings

Perform the following steps to begin the installation:

-  Apply the patch ``3942506`` to get and save the script for OATM migration,
   ``$FND_TOP/bin/fndtsmig.pl``.

-  Get the required parameters as identified in Oracle
   [Note 404954.1](https://support.oracle.com/epmos/faces/DocumentDisplay?id=404954.1).

-  Place database in ``no archive log`` mode.

#### Step 2: Update the database parameters

Before starting the OATM migration, increase the following parameter values:

-  undo\_retention=10200
-  job\_queue\_processes=0
-  aq\_tm\_processes=0
-  db\_files=1500 (required for OATM)

To do this, run the following code:

    $ sqlplus '/as sysdba'
    SQL> alter system set undo_retention=10200 scope=spfile;
    SQL> alter system set job_queue_processes=0 scope=spfile;
    SQL> alter system set aq_tm_processes=0 scope=spfile;
    SQL> alter system set db_files=1500 scope=spfile;

Shut down the database and restart it to confirm the parameter settings.

#### Step 3: Resize the temporary tablespace and clean the database

To complete the installation, resize the temporary (temp) tablespace to 50
gigabytes (GB) or higher, and then clean up the database, including the tools,
undo, and other tablespaces.

### Invoke the OATM migration utility

To conduct the migration, perform the steps in this section.

#### Step 1: Run the migration script

To start the migration, run the following command:

    $FND_TOP/bin> perl fndtsmig.pl

    Main Menu

    1. Migration Sizing Reports
    2. Create New Tablespaces
    3. Generate Migration Commands
    4. Execute Migration Commands
    5. Run Migration Status Reports
    6. Run Post Migration Steps
    7. Run Customization Steps
    8. Run Migration in Batch Mode

    Please enter your option -

#### Step 2: Determine the space required for the new tablespaces

Choose ``1. Migration Sizing Reports`` from the main menu to determine how
much space is needed to complete the OATM migration.

    1. Generate a Report with the list of all the Oracle
       Application product schemas that can be migrated
    2. Calculate total space required by each new tablespace to
       Migrate all Oracle Application product schemas (relevant
       for a complete migration)
    3. Calculate total space required by each new tablespace to
       migrate each Oracle Application product schema (relevant
       for a schema-by-schema migration)
    4. Calculate total space required by each Oracle Applications
       schema, with details for each object
    5. Display Sizing Exception report

    Please enter your option -
    Press Return key to continue...

From this menu, choose ``2. Calculate total space required ...`` to get the
space requirements.  Based on the Sizing report, get the necessary storage space
and continue.

These reports are provided to help you gauge the space requirements needed for
the new tablespaces. Additionally, they help you to determine which migration
approach best suits your needs.

#### Step 3: Create tablespace script

Choose ``2. Create New Tablespaces`` from the main menu to create the new
tablespaces.

    Create New Tablespaces

    1. Generate new tablespace creation script
    2. Create new tablespaces
    Please enter your option -

    Press Return key to continue...

From this menu, choose ``1. Generate new tablespace creation script`` to create
the script.

#### Step 4: Generate the Invalid Indexes report

To generate the Invalid Indexes report, first choose ``3. Generate Migration Commands``
from the main menu.

    Generate Migration Commands

    Generation of Migration commands including disable/enable
    commands for triggers, constraints, policies, stop/start for queues.

    1. Invalid Indexes Report. Please correct/drop these before
       generating migration commands
    2. Generate migration commands for all schemas
    3. Generate migration commands for a list of schemas

    [Q]uit        [B]ack        [N]ext

    Please enter your option -

    Press Return key to continue.

Then choose ``1. Invalid Indexes Report.`` to generate the Invalid Indexes report.

    Report created /oracldb/oracledbappl/admin/oracldb/log/fndinvld.txt

#### Step 5: Disable custom schemas and enable CTXSYS schema

If you did not previously disable custom schemas and enable the CTXSYS schema,
as described the preceding "Prerequisites" section, do this now.

#### Step 6: Generate the migration scripts for all schemas

From the **Generate Migration Commands** menu, select
``2. Generate migration commands for all schemas`` to generate migration
scripts.

    Generating Migration commands for all schemas. This may take upto 30min. Please wait...

    Press Return key to continue...

#### Step 7: Generate the migration commands for CTXSYS

From the **Generate Migration Commands** menu, select
``3. Generate migration commands for a list of schemas`` to generate the
migration commands for the CTXSYS schema.  When prompted, enter ``CTXSYS``.

    Please enter your option -  3
    Enter a comma separated list of Schema names: CTXSYS

#### Step 8: Set autoextend option

To avoid migration issues, set autoextend to ``ON`` for all newly create files
by executing the following commands:

    SQL> spool autoextend_ts.sql
    SQL> select 'alter database datafile ''' || file_name || ''' ' || ' autoextend on;' from dba_data_files;
    SQL> spool off

    $ autoextend_ts.sql

#### Step 9: Run the migration commands and status report

From the main menu, select ``4. Execute Migration Commands`` to run the migration
commands.

    Execute Migration Commands

    Execution of Migration commands including disable
    commands for triggers constraints, stop/start for queues.

    PLEASE TAKE A COMPLETE BACKUP OF THE DATABASE BEFORE MIGRATION

    1. Migrate all Schemas
    2. Migrate a list of Schemas
    3. Migrate CTXSYS Schema

    Note: Migrate CTXSYS schema when no other migration process is in progress.
    Please enter your option -

    Press Return key to return to the menu...

From this menu, choose ``1. Migrate all Schemas``.  When prompted, enter ``Y``
to migrate all schemas and enter ``8`` for the number of parallel processes.

    Are you sure you want to migrate all schemas[N]: Y
    Enter the maximum number of parallel processes for oracledb[8]: 8
    Starting the Migration process for all schemas. Please wait...


### Conclusion

OATM is more efficient and easier to manage with fewer tablespaces and provides
benefits like efficient space utilization. The efficiency comes from supporting
locally managed tablespaces rather than a dictionary-managed tablespace, which
other migration models use.

OATM is mandatory for version R12, but you should upgrade to OATM before you
upgrade to version R12.

OATM provides additional benefits when implementing Real Application Clusters (RAC).

For more information about OATM migration utility, see
[Note 248857.1 - OATM Release 11i - Tablespace Migration Utility](https://docs.oracle.com/cd/E18727_01/doc.121/e12893/T174296T432724.htm).

If you have any questions on this topic, comment in the field below.
