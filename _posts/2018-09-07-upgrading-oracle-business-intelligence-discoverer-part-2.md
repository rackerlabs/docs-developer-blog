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
---

Originally published by Tricore: May 17, 2017

Oracle&reg; Business Intelligence Discoverer is a toolset for ad hoc querying,
reporting, data analysis, and web publishing for the Oracle database environment.

<!-- more -->

### Introduction

This two-part blog series covers the steps required to install or upgrade
Discoverer within an existing E-Business Suite (EBS) R12 instance.
[Part 1](https://developer.rackspace.com/blog/upgrading-oracle-business-intelligence-discoverer-part-1/)
discussed the installation of the software required for the Discoverer 11.1.1.7
upgrade. This blog, part 2, covers the details of integration and the Discoverer
End User Layers (EUL) upgrade.

### Integration with Discoverer 11g

This section describes how to integrate e-Business Suite R12 with Discoverer 11g
by using the database connector (dbc) file, which uses a **.dbc** extension, and
the `tnsnames.ora` configuration.

On your Discoverer node, include the tnsnames entry to connect to your EBS R12
database in file `$ORACLE_INSTANCE/config/tnsnames.ora`.

Use the same entry that exists in the `tnsnames.ora` file on your Oracle
E-Business Suite Release 12 application tier server node. The database name must
match the two_task entry in the dbc file.


### Upgrade or create Discoverer EUL

If you already have an existing Discoverer End User Layer, you may need to to
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

If you don’t have an existing EUL, you must create one for new Discoverer 11.1.1.
Fresh installations of E-Business Suite r12 Vision database does contain a
pre-installed Discoverer EUL, but other versions do not come with the EUL.

Run the following command to create an EUL:

    % sqlplus /NOLOG
     SQL> connect sys/<sys_password> as sysdba
     SQL> create tablespace DISCOVERER datafile \
     '[DB_ORACLE_HOME]/dbf/discoverer01.dbf' size 200M reuse \
     extent management local uniform size 128K;
     SQL> /
    Statement Processed












Use the following steps for the Oracle WebLogic Server 11gR1 (10.3.6) installation.

1. Run the following command to start the installation:

      <JDK_PATH>/bin/java -d64 -jar -Djava.io.tmpdir=<temp_dir_loc> ./wls1036_generic.jar -log=<loc/filename>

2. Click **Next** on the **Welcome** screen.

3. Create the new Middleware home by specifying the location.

4. Provide Oracle support credentials (if required).

5. Choose the install type, either typical (recommended) or custom.

6. Select local JDK installed, as shown in the following image.

   ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture1.png %})

<ol start=7>
    <li>Choose the product installation directories. Specify the WebLogic server
   location and the  Oracle Coherence location, as shown in the following image.</li>
</ol>

   ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture2.png %})

<ol start=8>
    <li>Review the installation summary and size.</li>
</ol>

<ol start=9>
    <li>Review the installation log to check progress and verify completion.</li>
</ol>

<ol start=10>
    <li>Click **Done** after installation completed.</li>
</ol>


#### RCU installation

The RCU download package should be about 350 MB. This utility creates two
new users and three new tablespaces, which are used to store metadata for
Middleware and Discoverer.

Use the following steps for the installation process:

1. Click **Next** on the **Welcome** screen.

2. Choose **Create** to create the repository.

3. Provide the database connection details.

4. Select **Create new prefix**. Provide the prefix name and select the component,
   such as **Discoverer**, under the Portal & BI label.

5. Enter the schema password.

6. Ensure that the correct default and temporary (temp) tablespaces are showing.
   If the tablespaces are incorrect, modify them.  The following image shows
   this step:

   ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture3.png %})

<ol start=7>
    <li>Review the summary and click **Create**.</li>
</ol>


#### Discoverer installation 11.1.1.2

Use the following steps for the Discoverer installation:

1. Start the run installer. You can optionally use the ``-ignoreSysPreReqs``
   parameter.

2. Click **Next** on the **Welcome** screen.

3. Select the **Install Software** install type. Do not modify the configuration
   settings.

4. Specify the location for the Oracle Middleware home directory and the Oracle
   home directory.

5. Provide Oracle support details under **Security Updates**.

6. Review the installation summary and click on **Install**.

7. Review the logs to check on installation progress. When prompted, run ``root.sh``.

8. When installation is complete, review the details and click **Finish**, as
   shown in the following image:

   ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture4.png %})

####  Upgrade Discoverer 11.1.1.2 installation to 11.1.1.7

Use the following steps to upgrade Discoverer from version 11.1.1.2 to
11.1.1.7:

1. Start the run installer.

2. Click **Next** on the **Welcome** screen.

3. Provide details of Middleware home directory and the current Discoverer
   directory, where we installed 11.1.1.2 in the preceding section.

4. Provide the Oracle support details in **Security Updates**.

5. Review the summary and click **Install**.

6. Review the logs to check installation progress. When prompted, run ``root.sh``.

7. When installation is complete, review the details and click **Finish**, as
   shown in the following image:

   ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture5.png %})

#### Configure the Discoverer instance

Use the following steps to configure the Discoverer instance:

1. Run ``config.sh``.

2. Click **Next** on the **Welcome** screen.

3. Choose **Create domain** and provide the username (``weblogic``), password, and
   domain name, as shown in the following image:

   ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture6.png %})

<ol start=4>
    <li>Provide the Oracle support details in **Security Updates**.</li>
</ol>

<ol start=5>
    <li>Provide the WebLogic server location, the Oracle instance location, and the
   Oracle instance name.</li>
</ol>

<ol start=6>
    <li>Select the **Oracle Discoverer** component to configure, as shown in the
   following image:</li>
</ol>

   ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture7.png %})

<ol start=7>
    <li>Select **Auto port config** to configure ports.</li>
</ol>

<ol start=8>
    <li>Provide the connection string and schema details, which were created by using
   RCU, to specify the schema.</li>
</ol>

<ol start=9>
    <li>If you are using Application Object Identifier (OID), provide the hostname,
   port, username, and password to specify the OID. If you are not using OID,
   deselect the **Use Application level identity store** option.</li>
</ol>

<ol start=10>
    <li>Review the summary and click **Configure**.</li>
</ol>

<ol start=11>
    <li>Review the logs and **Status** tab on the **Installer** screen to check
    installation progress. Click **Next** when it finishes.</li>
</ol>

<ol start=12>
    <li>Review the installation details and click **Finish**, as shown in the
    following image:</li>
</ol>

    ![]({% asset_path 2018-07-16-upgrading-oracle-business-intelligence-discoverer-part-1/Picture8.png %})

### Conclusion

Using the preceding information, you can install Discoverer 11.1.1.7 and the
various required components on RHEL 6. Part 2 of this blog series has more
information on how to configure the Discoverer instance for Oracle R12 instances.

If you have any questions on this topic, comment in the field below.
