---
layout: post
title: "Upgrading Oracle Business Intelligence Discoverer: Part 2"
date: 2018-09-07 00:00
comments: true
author: Abhishek Shukla
published: true
authorIsRacker: true
categories:
  - Oracle
  - database
---

Originally published by TriCore: May 17, 2017

Oracle&reg; Business Intelligence Discoverer is a tool for ad hoc querying,
reporting, data analysis, and web publishing for the Oracle database environment.

<!-- more -->

### Introduction

This two-part blog series covers the steps required to install or upgrade
Discoverer within an existing E-Business Suite (EBS) R12 instance.
[Part 1](https://developer.rackspace.com/blog/upgrading-oracle-business-intelligence-discoverer-part-1/)
discussed the installation of the software required for the Discoverer 11.1.1.7
upgrade. This blog, Part 2, covers the details of integration and the Discoverer

End User Layers (EUL) upgrade.

### Integration with Discoverer 11g

This section describes how to integrate e-Business Suite R12 with Discoverer 11g
by using the database connector (dbc) file, which uses a **.dbc** extension, and
the `tnsnames.ora` configuration.

On your Discoverer node, include the tnsnames entry to connect to your EBS R12
database in file `$ORACLE_INSTANCE/config/tnsnames.ora`.

Use the same entry that exists in the `tnsnames.ora` file on your Oracle
E-Business Suite Release 12 application tier server node. The database name must
match the TWO_TASK entry in the dbc file.


### Upgrade or create Discoverer EUL


If you already have an existing Discoverer EUL, you might need to upgrade to
upgrade. The upgrade steps depend on your Discoverer version.  See the following
sections for details.

#### Existing EUL and Discoverer 10.1.2

If you have an existing Discoverer EUL and it is from Discoverer 10.1.2, you are
not required to upgrade. Discoverer Version 11.1.1 uses the same EUL version as
Discoverer 10.1.2. The dbc file is not transferred during the upgrade. After the
upgrade, you must copy the dbc file manually.

#### Existing EUL and version older than Discoverer 10.1.2

If you have an existing Discoverer EUL and its version predates Discoverer
10.1.2, upgrade it to Discoverer 11g by using the following commands on the
standalone application server where Oracle Fusion Middleware Discoverer 11g is
installed:

    $ source $ORACLE_INSTANCE/Discoverer/Discoverer_<ias-instance>/util/discenv.sh
    $ $ORACLE_HOME/bin/eulapi -CONNECT <EUL User>/<Password>@<db> -AUTO_UPGRADE

#### Create new EUL for Discoverer 11.1.1

If you don’t have an existing EUL, you must create one for the new Discoverer 11.1.1.
Fresh installations of the E-Business Suite R12 Vision database do contain a
preinstalled Discoverer EUL, but other versions do not come with the EUL.

Run the following command to create an EUL:

    % sqlplus /NOLOG
     SQL> connect sys/<sys_password> as sysdba
     SQL> create tablespace DISCOVERER datafile \
     '[DB_ORACLE_HOME]/dbf/discoverer01.dbf' size 200M reuse \
     extent management local uniform size 128K;
     SQL> /
    Statement Processed

To create the Discoverer EUL before running command line scripts, you must run
the following command to source the environment script:

    $ source $ORACLE_INSTANCE/Discoverer/Discoverer_<ias-instance>/util/discenv.sh

### Configure platform-specific environment settings

If you are using Discoverer on 64-bit platforms (such as Oracle Solaris on SPARC&reg;
64 bit, HP-UX&reg; PA-RISC 64 bit, HP-UX Itanium 64 bit, IBM&reg; AIX 64 bit,
Linux x86-64), find the line in `$ORACLE_INSTANCE/Discoverer/Discoverer_<ias-instance>/util/discenv.sh`
that defines variable `LIB_PATH` and set it by using the following code:

    LIB_PATH=$OH/discoverer/lib:$OH/lib:/usr/lib:$OH/lib32

If you are using Discoverer on 64-bit platform Linux x86-64, find the line that
defines variable `LD_ASSUME_KERNEL` and comment it out as shown in the following
code:

    #export LD_ASSUME_KERNEL=2.4.19

    $ORACLE_HOME/bin/eulapi \
     -CREATE_EUL \
     -APPS_MODE \
     -CONNECT system/<password>@<db> \
     -USER <EUL_User_Prefix>_US \
     -PASSWORD <password> \
     -DEFAULT_TABLESPACE <default tablespace> \
     -TEMPORARY_TABLESPACE <temp tablespace> \
     -EUL_LANGUAGE US \
     -APPS_GRANT_DETAILS <FNDNAM>/<FNDNAM password>

### Apply patch containing adupdeul.sh and adrfseul.sh

Apply one of the following patches by using the `adpatch` option:

- For version 12.1, use Patch 9394002
- For version 12.0, use Patch 9384228

### Set applications profile options for Discoverer by using autoconfig

To set the applications profile options for Discoverer, update the variable
`s_disco_url` in `CONTEXT_FILE` and run `autoconfig`.

### Set applications profile options in Oracle EBS

To set the applications profile options in EBS, navigate to the **Profile > System**
form.

Query the Discoverer profile options looking for the following items:

- Inter-Cartridge eXchange(ICX): Discoverer Launcher - The URL that points to
  the Discoverer Plus servlet.
- ICX: Discoverer Viewer Launcher - The URL that points to the Discoverer Viewer
  servlet.
- ICX: Discoverer use Viewer - Specify whether the Discoverer Viewer should be
  launched instead of Discoverer Plus (default).
- ICX: Discoverer Default EUL schema prefix - The EUL prefix in
  combination with the Language code make up the EUL owner at runtime. For
  example, EUL owner `EUL_US` has the EUL prefix `EUL`.
- ICX: Discoverer EUL language override - Because the EUL content is
  currently available in US English only, it is possible to override the user's
  general language preference for the Discoverer EUL using this profile option.
  The specified EUL language is used regardless of the individual user's language
  preferences.
- ICX: Discoverer Release - This profile can be used to optionally pass
  additional URL parameters to Discoverer.
- Discoverer DBC filename override - This profile can be used to specify the
  DBC Filename that Discoverer should use to connect to the E-Business Suite
  database.

The following image shows these settings:

![]({% asset_path 2018-09-07-upgrading-oracle-business-intelligence-discoverer-part-2/Picture1.png %})

### Run the "Generate Business Views by Application" concurrent program

To regenerate your business views, run the `Generate Business Views by Application`
concurrent program, as indicated in the following steps:

- Log on to Oracle E-Business Suite as `SYSADMIN`.
- Choose the **Business Views Setup** responsibility.
- Navigate to **Reports > Run > Pick Single Request > "Generate ALL Business Views"**.

If you don't have "Business Views Setup" responsibility assigned to the `SYSADMIN`
user, do the following:

- Log on to Oracle E-Business Suite as `SYSADMIN`.
- Choose the **System Administrator** responsibility.
- Navigate to **Security > User > Define** and add responsibility
  **Business Views Setup** to user `SYSADMIN`.

### Recompile APPS objects

Recompile all objects in the **APPS** schema by using `adadmin`.

### Check the Business Intelligence system views

Ensure that the Business Intelligence system views exist and that they are valid
by issuing the following command in SQL*Plus:

    % sqlplus apps/<password>@<db>
    SQL> select object_name from user_objects
    where object_type = 'VIEW' and
    status = 'INVALID' and
    ( object_name like '%FV_%' or object_name like '%FG_%' or
    object_name like '%BV_%' or object_name like '%BG_%' )and
     object_name in (select sobj_ext_table from eul_us.eul5_objs);

### Grant EUL administration privileges

Grant EUL administrative privileges by running the following command:

     sh eulapi > -CONNECT EUL_US/EUL_US@SID > -GRANT_PRIVILEGE > -USER SYSADMIN > -PRIVILEGE administration > -PRIVILEGE all_admin_privs > -LOG admin_priv.log
    -connect <**********>
    -grant_privilege
    -user SYSADMIN
    -privilege administration
    -privilege all_admin_privs
    -log <logfilename>

#### Provide security access

Ensure that user `SYSADMIN` has full security access to all business areas by
running the following command:

     sh $ORACLE_HOME/bin/eulapi > -CONNECT EUL_US/***@sid > -GRANT_PRIVILEGE > -USER SYSADMIN > -BUSINESS_AREA_ADMIN_ACCESS % > -WILDCARD > -LOG full_sec_acc.log
    -connect <**********>
    -grant_privilege
    -user SYSADMIN
    -business_area_admin_access %
    -wildcard
    -log <logfilename>

### Import EBS Discoverer content

Access the `$AU_TOP/discover` directory on your EBR R12 instance from the
Discoverer 11g BI instance. This directory was copied to the Discoverer server.

Start the import process of the Discoverer loader files (.eex files) by using
the following command:

    sh adupdeul.sh connect=sysadmin/sysadmin@SID resp="System Administrator"
    gwyuid=APPLSYSPUB/*** fndnam=APPS secgroup="Standard" topdir=<loc>
    language=US eulprefix=EUL iashome=loc eultype=OLTP mode=complete logfile=<logfilename>

Review the import log file and ignore the warnings during the import as described
in [DOC ID - 1074326.1](https://support.oracle.com/rs?type=doc&id=1074326.1).

### Refresh the Discoverer 11.1.1 EUL

Refresh the Discoverer EUL by running the following command:

    sh adrfseul.sh connect=sysadmin/*******@SID resp="System Administrator" gwyuid=APPLSYSPUB/*** fndnam=APPS secgroup="Standard" eulschema=EUL_US eulpassword=***** twotask=sid iashome=<loc> logfile=<logfilename>

### Conclusion

This blog showed you how to configure or upgrade Discoverer to 11.1.1.7 on Red
Hat&reg; Enterprise Linux (RHEL) 6, which supports Discoverer versions 11.1.1.6.0
and 11.1.1.7.0.

<table>
  <tr>If you liked this blog, share it by using the following icons:</tr>
  <tr>
   <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://twitter.com/home?status=https%3A//developer.rackspace.com/blog/applications-monitoring-creating-a-smoother-financial-close/">
        <img src="{% asset_path shareT.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.facebook.com/sharer/sharer.php?u=https%3A//developer.rackspace.com/blog/applications-monitoring-creating-a-smoother-financial-close/">
        <img src="{% asset_path shareFB.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.linkedin.com/shareArticle?mini=true&url=https%3A//developer.rackspace.com/blog/applications-monitoring-creating-a-smoother-financial-close&summary=&source=">
        <img src="{% asset_path shareL.png %}">
      </a>
    </td>
  </tr>
</table>

If you have any questions on this topic, comment in the field below.
