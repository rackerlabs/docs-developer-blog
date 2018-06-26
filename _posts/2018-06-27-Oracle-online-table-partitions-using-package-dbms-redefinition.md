---
layout: post
title: "Oracle online table partitions using the DBMS_REDEFINITION package"
date: 2018-06-27 00:00
comments: true
author: Pradeep Rai
published: true
authorIsRacker: true
categories:
    - Oracle
---

Starting with Oracle&reg; 10g, you can partition tables online without any
application downtime by using the DBMS\_REDEFINITION package.

Use the following steps to change a non-partition table to a partition table by
using DBMS\_REDEFINITION. This example changes the non-partition table, TABLEA,
to a range interval partition table.

<!-- more -->

### Step 1: Backup the unpartition table

Run the following code to create a full export backup of the table, TABLEA.

    expdp  \"/ as sysdba\" directory=EXPDP_DIR dumpfile=tableA_UNPAR.dmp logfile=tableA_UNPAR.log TABLES=TEST.TABLEA

    expdp  \"/ as sysdba\"  directory=EXPDP_DIR dumpfile=tableA_metaunpar.dmp logfile=tableA_metaunpar.log TABLES=TEST.TABLEA content=metadata_only


### Step 2: Examine the database objects

The following dependent (D) database objects can be dropped when a table is
dropped:

- CONSTRAINT (Constraints)   D

- INDEX (Indexes)            D

- MATERIALIZED\_VIEW\_LOG (Materialized view logs)   D

- OBJECT\_GRANT (Object grants)   D

- TRIGGER (Triggers)   D

Run the following SQL commands and save the output in a spool file, such as
``cons_trig_indx.txt``:

    set LINESIZE 500
    set PAGESIZE 1000
    SQL> spool cons_trig_indx.txt
    SQL> select name, type, owner from all_dependencies where referenced_owner = 'TEST' and referenced_name = 'TABLEA';

    NAME                TYPE              OWNER
    --------------      --------------    -------
    PROC_TABLEA         PROCEDURE         TEST
    TABLEA_TRIGG        TRIGGER           TEST
    PKG_TABLEA          PACKAGE BODY      TEST


    SQL> select OWNER, INDEX_NAME, TABLE_OWNER, TABLE_NAME, STATUS, TABLESPACE_NAME
    from dba_indexes where TABLE_OWNER='TEST' and TABLE_NAME='TABLEA';

    OWNER   INDEX_NAME       TABLE_OWNER  TABLE_NAME   STATUS   TABLESPACE_NAME
    ---------------------------------------------------------------------------
    TEST    TABLEA_IDX_ID01    TEST        TABLEA      VALID    TABLEA_TBL
    TEST    TABLEA_IDX_ID04    TEST        TABLEA      VALID    TABLEA_TBL
    TEST    TABLEA_IDX_PK      TEST        TABLEA      VALID    TABLEA_TBL


    SQL> select STATUS, OBJECT_TYPE, OBJECT_NAME  from dba_objects
    where OWNER='TEST' and OBJECT_TYPE = 'TRIGGER' and STATUS='INVALID';

    no rows selected

    SQL> select CONSTRAINT_NAME, CONSTRAINT_TYPE from dba_constraints
    where TABLE_NAME='TABLEA' and owner='TEST';
    SQL> spool off

    CONSTRAINT_NAME     C
    ------------------  -----
    SYS_C002004601      C
    SYS_C002004602      C
    SYS_C002004603      C
    IDX_PK              P
    FK01                R


### Step 3: Capture the DDL of TABLEA

Run the following commands to capture the data definition language (DDL) of
TABLEA and save scripts in spool file ``DEF_TABLEA.sql`` before you create
the partition table:

    set echo off
    set feedback off
    set linesize 160
    set long 2000000
    set pagesize 0
    set trims on
    column txt format a150 word_wrapped
    SQL> spool DEF_TABLEA.sql
    SQL> select DBMS_METADATA.GET_DDL('TABLE','TABLEA','TEST') txt FROM dual;
    SQL> spool off

### Step 4: Copy the DDL script

Run the following command to copy the DDL script that you created in step 3.

    cp DEF_TABLEA.sql DEF_TABLEA_PAR.sql

### Step 5: Review the dates in the non-partition table

Run the following command to find the dates in TABLEA:

    SQL> select * from (select DT from TEST.TABLEA where rownum <15 order by DT DESC);

### Step 6: Edit DEF_TABLEA_PAR.sql file

Edit ``DEF_TABLEA_PAR.sql`` to make the following changes:

- Change all occurrences of **TABLEA** to **TABLEA_PAR**.

- Delete all the constraints, like NOT NULL or any other constraints.

- Insert the following command so that the table is created in a new tablespace:

        TABLESPACE "TABLEA_TBL_PAR" LOGGING

- Insert the following commands to add the partition definition based on the
  dates identified in Step 5:

        PARTITION BY RANGE(DT)
        interval (numtoyminterval(1,'MONTH'))
        (partition TABLEA_2004  values less than  (to_date('01/01/2005','DD/MM/YYYY')),
         partition TABLEA_2005 values less than  (to_date('01/01/2006','DD/MM/YYYY')));

The ``DEF_TABLEA_PAR.sql`` file should now look like the following example:

    CREATE TABLE "TEST"."TABLEA_PAR"
    (    "ID" NUMBER(6,0),
         "CEID" NUMBER(6,0),
         "DT" DATE,
         "AMT" NUMBER(14,4),
         "RET" NUMBER(14,4),
         "CNT" NUMBER(4,0),
         "VCNT" NUMBER(4,0),
         "EXEDT" DATE,
         "LASTUPDBY" VARCHAR2(15),
         "VENUM" NUMBER(6,0),
         "LASTUPDDT" TIMESTAMP (6))
    TABLESPACE "TABLEA_TBL_PAR" LOGGING
    PARTITION BY RANGE(DT)
    interval (numtoyminterval(1,'MONTH'))
    (partition TABLEA_2004  values less than  (to_date('01/01/2005','DD/MM/YYYY')),
     partition TABLEA_2005  values less than  (to_date('01/01/2006','DD/MM/YYYY')));

### Step 7: Create the partition table

Create the partition table by running the following steps to run the
``DEF_TABLEA_PAR.sql`` script:

    SQL> spool DEF_TABLEA_PAR.outp.txt
    SQL> @DEF_TABLEA_PAR.sql

    Table Created.

    SQL> spool off

### Step 8: Verify the partition table

Run the following commands to verify the partition table and return the
defined partitions:

    SQL> spool verify_partition.txt
    SQL> select partition_name from DBA_tab_partitions where table_name ='TABLEA_PAR' and table_owner = 'TEST';
    SQL> spool off

    PARTITION_NAME
    -----------------
    TABLEA_2004
    TABLEA_2005

### Step 9: Gather statistics on the non-partition table

Run the following commands to gather statistics on the non-partition table
and save them to a spool file.

    SQL> SPOOL gather_stats.txt
    SQL> exec dbms_stats.gather_table_stats ('TEST', 'TABLEA',cascade => TRUE);
    SQL> spool off

### Step 10: Check redefinition feasibility

Run the following commands to see if redefinition is possible, and save the
results to a spool file:

    SQL> spool check_the_redefinition.txt
    SQL> EXEC DBMS_Redefinition.can_redef_table ('TEST', 'TABLEA');
    SQL> spool off

### Step 11: Start redefinition

If no errors are listed in ``check_the_redefinition.txt``, start the redefinition
by using the following long-running command:

    SQL> spool start_redef_table.txt
    SQL>begin
        dbms_redefinition.start_redef_table
        (
         uname => 'TEST',
         orig_table => 'TABLEA',
         int_table => 'TABLEA_PAR');
         end;
       /
    SQL> spool off

### Step 12: Watch for tablespace errors during redefinition

The redefinition operation in step 11 might result in tablespace alerts like
the following example:

    ERROR at line 1:
    ORA-12008: error in materialized view refresh path
    ORA-01688: unable to extend table TEST.TABLEA_PAR
    partition SYS_P42 by 1024 in tablespace TABLEA_TBL
    ORA-06512: at "SYS.DBMS_REDEFINITION", line 52
    ORA-06512: at "SYS.DBMS_REDEFINITION", line 1646
    ORA-06512: at line 2

    ERROR at line 1:
    ORA-12008: error in materialized view refresh path
    ORA-14400: inserted partition key does not map to any partition
    ORA-06512: at "SYS.DBMS_REDEFINITION", line 52
    ORA-06512: at "SYS.DBMS_REDEFINITION", line 1646
    ORA-06512: at line 2

If you see tablespace errors similar to the preceding example, then you should
take the following steps:

1. Run the following command to stop the redefinition process.

        SQL> spool abort_redef_table.txt
        SQL> begin
             dbms_redefinition.abort_redef_table
             (
             uname => 'TEST',
             orig_table => 'TABLEA',
             int_table => 'TABLEA_PAR');
             end;
            /
        SQL> spool off

2. Drop the partition table and the materialized view.

3. Increase the size of tablespace. In this example, you should increase the
   size of the tablespace TABLEA_TBL.

4. Rerun step 11.

### Step 13: Check for redefinition errors

After the redefinition process completes successfully, run the following
commands to check for any errors:

    SQL> spool copy_table_dependents.txt
    SQL> SET SERVEROUTPUT ON
         DECLARE
         l_num_errors PLS_INTEGER;
         BEGIN
           DBMS_REDEFINITION.copy_table_dependents(
               uname             => 'TEST',
               orig_table        => 'TABLEA',
               int_table         => 'TABLEA_PAR',
               copy_indexes      => DBMS_REDEFINITION.cons_orig_params, -- Non-Default
               num_errors        => l_num_errors);
               DBMS_OUTPUT.put_line('l_num_errors=' || l_num_errors);
         END;
    /
    SQL> spool off

If the redefinition was successful, you should see results similar to the
following in the ``copy_table_dependents.txt`` file:

    l_num_errors=0
    PL/SQL procedure successfully completed.

### Step 14: (Optional) Resynchronize the partition table

If you like, run the following commands to resynchronize the partition
table with an interim name:

    SQL> spool sync_interim_table.txt
    SQL>
         BEGIN
           DBMS_REDEFINITION.sync_interim_table
           (
               uname => 'TEST',
               orig_table => 'TABLEA',
               int_table => 'TABLEA_PAR');
          END;
    /
    SQL> spool off

### Step 15: Gather statistics on the partition table

Run the following commands to gather statistics on the partition table:

    SQL> spool gather_statistics_par.txt
    SQL> exec dbms_stats.gather_table_stats ('TEST', 'TABLEA_PAR',cascade => TRUE);
    SQL> spool off

### Step 16: Create constraint script

Run the following commands to prepare a script to enable the validate constraint.


    SQL> spool constraint_enable_validate.txt
    SET LINESIZE 500
    SET PAGESIZE 1000

    SQL> select 'alter table' ||' '||OWNER||'.'||TABLE_NAME||' enable validate constraint'||' '||CONSTRAINT_NAME||';' from dba_constraints where TABLE_NAME = 'TABLEA_PAR' and OWNER='TEST';

    'ALTERTABLE'||''||OWNER||'.'||TABLE_NAME||'ENABLEVALIDATECONSTRAINT'||''||CONSTR
    --------------------------------------------------------------------------------
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_SYS_C002004601;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_SYS_C002004602;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_SYS_C002004603;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_IDX_PK;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_FK01;

    SQL> spool off

### Step 17: Enable the validate constraint

 Run the script and commands produced by step 16, as shown in the following
 example:

    SQL> spool constraint_enable_execute.outp.txt
    SQL>@constraint_enable.sql

    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_SYS_C002004601;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_SYS_C002004602;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_SYS_C002004603;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_IDX_PK;
    alter table TEST.TABLEA_PAR enable validate constraint TMP$$_FK01;

    SQL> spool off

### Step 18: Compare non-partition and partition tables

Compare the original, non-partition table with the new, partition table to
verify that all attributes are the same.

### Step 19: Rename the tables

Run the following commands to set the interim table as the real table to switch
the table names:

    SQL> spool finish_redef_table.txt
         BEGIN
           DBMS_REDEFINITION.finish_redef_table
          (
            uname => 'TEST',
            orig_table => 'TABLEA',
            int_table => 'TABLEA_PAR');
         END;
    /

    --------------------------------------------
    @?/rdbms/admin/utlrp.sql
    --------------------------------------------

    SQL>spool off

### Step 20:  Compare the tables

Run the following commands to compare the record counts of both tables and make
sure they match:

    SQL> spool table_count.outp.txt
    SQL> select count(*) from TEST.TABLEA;

     COUNT(*)
    ----------
      890540

    SQL> select count (*) from TEST.TABLEA_PAR;

     COUNT(*)
    ----------
      890540

    SQL> spool off

### Step 21: Verify partition success

Run the following commands to verify that the partition process was successful:

    SQL> spool check_partition.txt
    SQL> select partitioned from dba_tables where table_name = 'TABLEA' and owner='TEST';

    PAR
    ------
    YES

    SQL> select partition_name , SUBPARTITION_COUNT, TABLESPACE_NAME from dba_tab_partitions where table_name='TABLEA' and table_owner='TEST';
    SQL> select table_name, partition_name, high_value, partition_position from DBA_tab_partitions where table_name='TABLEA' and table_owner='TEST';
    SQL> spool off

### Step 22: Reexamine the database objects

Run the following commands to examine the database objects and compare the
results to step 2:

    SET LINESIZE 500
    SET PAGESIZE 1000
    SQL> spool cons_indx_trigg.txt
    SQL> select name, type, owner from all_dependencies where referenced_owner = 'TEST' and referenced_name = 'TABLEA';

    NAME                TYPE              OWNER
    ----------------    ---------------   ------------
    PROC_TABLEA         PROCEDURE         TEST
    TABLEA_TRIGG        TRIGGER           TEST
    PKG_TABLEA          PACKAGE BODY      TEST

    SQL> select OWNER, INDEX_NAME, TABLE_OWNER, TABLE_NAME, STATUS, TABLESPACE_NAME from dba_indexes where TABLE_OWNER='TEST' and TABLE_NAME='TABLEA';

    OWNER  INDEX_NAME       TABLE_OWNER TABLE_NAME  STATUS   TABLESPACE_NAME
    ------------------------------------------------------------------------
    TEST   TABLEA_IDX_ID01  TEST        TABLEA      VALID    TABLEA_TBL
    TEST   TABLEA_IDX_ID04  TEST        TABLEA      VALID    TABLEA_TBL
    TEST   TABLEA_IDX_PK    TEST        TABLEA      VALID    TABLEA_TBL

    SQL> select STATUS, OBJECT_TYPE, OBJECT_NAME  from dba_objects where OWNER='TEST' and OBJECT_TYPE = 'TRIGGER' and STATUS='INVALID';

    no rows selected

    SQL> select CONSTRAINT_NAME, CONSTRAINT_TYPE from dba_constraints where TABLE_NAME='TABLEA' and owner='TEST';

    CONSTRAINT_NAME        C
    -------------------		----------
    SYS_C002004601         C
    SYS_C002004602         C
    SYS_C002004603         C
    IDX_PK                 P
    FK01                   R

    12 rows selected.

    SQL> spool off

### Step 23: Rebuild the indexes

Run the following commands to rebuild the indexes on the new tablespace:

    SQL> spool rebuild_indx.txt
    SQL>@rebuild_index.sql

    ALTER INDEX TEST.TABLEA_IDX_ID01 REBUILD TABLESPACE TABLEA_TBL_PAR ONLINE;
    ALTER INDEX TEST.ITABLEA_IDX_ID04 REBUILD TABLESPACE TABLEA_TBL_PAR ONLINE;
    ALTER INDEX TEST.TABLEA_IDX_PK REBUILD TABLESPACE TABLEA_TBL_PAR ONLINE;

    SQL> spool off

### Step 24: Validate the indexes

Run the following commands to verify that the status is ``valid`` and that the
tablespace for all indexes is TABLEA\_TBL\_PAR:

    SQL> spool verify_indx.outp.txt
    SQL> select OWNER, INDEX_NAME, TABLE_OWNER, TABLE_NAME, STATUS, TABLESPACE_NAME from dba_indexes where TABLE_OWNER='TEST' and TABLE_NAME='TABLEA';

    OWNER  INDEX_NAME       TABLE_OWNER  TABLE_NAME   STATUS   TABLESPACE_NAME
    ---------------------------------------------------------------------------
    TEST   TABLEA_IDX_ID01  TEST         TABLEA       VALID   	 TABLEA_TBL_PAR
    TEST   TABLEA_IDX_ID04  TEST         TABLEA       VALID   	 TABLEA_TBL_PAR
    TEST   TABLEA_IDX_PK    TEST         TABLEA       VALID     TABLEA_TBL_PAR

    SQL>spool off

### Step 25: Drop original non-partition table

After the DBAs have confirmed that everything looks good, execute the following
command to remove the original table, which now has the name of the interim
table, TEST.TABLEA_PAR:

    SQL> DROP table TEST.TABLEA_PAR cascade constraints;

### Conclusion

The preceding steps used the interim table, TEST.TABLEA_PAR, to partition the
table, TEST.TABLEA, into a range interval table without any application downtime.

If you have any questions on this topic, comment in the field below.

