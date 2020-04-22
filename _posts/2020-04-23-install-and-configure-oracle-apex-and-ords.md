---
layout: post
title: "Install and configure Oracle APEX and ORDS"
date: 2020-04-23 00:01
comments: true
author: Manoj Singh
published: true
authorIsRacker: true
authorAvatar: 'https://media-exp1.licdn.com/dms/image/C5103AQE6tfHUm-whiw/profile-displayphoto-shrink_200_200/0?e=1593043200&v=beta&t=OPNBn8Pl4CYK6aqbqvXaTWs7n5TXPAglIB__-P4CuFk'
bio: "I have over ten years of  IT experience in Apps DBA, Core DBA, Cloud DBA,
Database Architect, and middleware as a IT Consultant. I'm also experienced in
cloud architecture analysis, migration planning, and migration execution. My
proven effectiveness in building good client interaction and partnering with
senior business leaders serve me well, as do my excellent facilitation skills
in conducting walkthroughs, brainstorming sessions, and core team meetings. I'm
an OCI-certified cloud DBA with expertise in Oracle Database 9i, 10g, 11g,12c
and Oracle E-Business Suite 11i ,R12&R12.2. I also have extensive experience in
release and change management, project management, and IT infrastructure."
categories:
    - Oracle
    - database
metaTitle: "Install and configure Oracle APEX and ORDS"
metaDescription: "This post describes Oracle&reg; Application Express (APEX) and Oracle REST Data
Services (ORDS), including the steps to install APEX and configure ORDS."
ogTitle: "Install and configure Oracle APEX and ORDS"
ogDescription: "This post describes Oracle&reg; Application Express (APEX) and Oracle REST Data
Services (ORDS), including the steps to install APEX and configure ORDS."
---

This post describes Oracle&reg; Application Express (APEX) and Oracle REST Data
Services (ORDS), including the steps to install APEX and install and configure
ORDS. Typically, database administrators (DBAs) carry out both of these tasks.

<!-- more -->

### APEX

Oracle developed APEX as a low-cost, web-based software development environment
platform that runs on an Oracle database. You can deploy APEX anywhere, which
enables developers to build secure and scalable enterprise apps with various
features.

### ORDS

ORDS, a Java-based application, enables developers with SQL and database skills
to develop REST APIs for Oracle Database. You can deploy ORDS on web and
application servers, including WebLogic&reg;, Tomcat&reg;, and Glassfish&reg;,
as shown in the following image:

![]({% asset_path 2020-04-23-install-and-configure-oracle-apex-and-ords/Picture1.png %})

*Image source*: [https://www.oracle.com/technetwork/developer-tools/apex/application-express/apex-arch-1876607.png](https://www.oracle.com/technetwork/developer-tools/apex/application-express/apex-arch-1876607.png)

### Install and configure

You can install and configure APEX and ORDS by using the following methods:

- Install APEX and ORDS and configure ORDS.
- Install APEX and configure a web listener: embedded PL/SQL gateway.
- Install APEX and configure the legacy web listener: Oracle HTTP Server.

For this post, I chose the first option, which Oracle recommends:  Install APEX
and ORDS and configure ORDS.

####  Install APEX

**Note:** You must install APEX on the database server node.

Install the Apex executable and create the tablespace and schema by using the
following steps:

1. Download and unzip the APEX software to **/u01/app/oradi/Apex**.

        $unzip apex_19.2_en.zip
        SQL> create tablespace apex_data datafile '+DMLCKI_DATA1/dmlcki/datafile/apex_data01.dbf' size 4000M; Tablespace created.
        $pwd /u01/app/oradi/Apex
        sqlplus "/as sysdba"
        SQL> @apexins.sql apex_data apex_data TEMP /i/
        apex_data - Tablespace to hold Apex Schema and its files
        TEMP - Temporary Tablespace
        /i/ - It is image directory

2· Change the administrator password.

        SQL> @apxchpwd.sql

3· Create the APEX\_LISTENER and APEX\_REST\_PUBLIC\_USER.

        SQL> @apex_rest_config.sql

#### Install and configure ORDS

Use the following steps to install and configure ORDS:

1. Download the latest release of ORDS to **/u01/app/oradi/ORDS**.

2. Unzip the downloaded file into the directory of your choice.

3. Copy the images directory, **/u01/app/oradi/Apex/apex/images**, from the
   APEX software zip file to the location where you plan to install ORDS.

        [oradi@diatmlckidb01 apex]$ cp -rp images /u01/app/oradi/ORDS/
        [oradi@diatmlckidb01 apex]$ pwd
        /u01/app/oradi/Apex/apex
        [oradi@diatmlckidb01 apex]$ cd /u01/app/oradi/ORDS/
        [oradi@diatmlckidb01 ORDS]$ ls -lrt
        drwxr-xr-x 32 oradi oinstall  40960 Nov 6 14:21 images
        -rw-r--r-- 1 oradi oinstall 63211594 Nov 27 20:14 ords-19.2.0.199.1647.zip

4. Oracle recommends that you use the latest version of Java is for ORDS.
   Download JDK version 8 from the patch file, **p30437878_180231_LINUX.zip**,
   and unzip the file.

5. Take a backup of the existing **jdk** folder and copy **jdk1.8.0_231** to
   **ORACLE_HOME/**.

        [oradi@diatmlckidb01 clone]$ cd /u01/app/oradi/DMLCKI/db/tech_st/11.2.0/
        [oradi@diatmlckidb01 11.2.0]$ mv jdk jdk_old
        [oradi@diatmlckidb01 11.2.0]$ cd
        [oradi@diatmlckidb01 ~]$ cd clone/
        [oradi@diatmlckidb01 clone]$ cp -rp jdk1.8.0_231 $ORACLE_HOME/
        [oradi@diatmlckidb01 clone]$ cd $ORACLE_HOME/
        [oradi@diatmlckidb01 11.2.0]$ mv jdk1.8.0_231 jdk
        [oradi@diatmlckidb01 11.2.0]$ java -version
        java version "1.8.0_231"
        Java(TM) SE Runtime Environment (build 1.8.0_231-b33)
        Java HotSpot(TM) Server VM (build 25.231-b33, mixed mode)

6. Execute the following command to complete the setup and configuration:

        [oradi@diatmlckidb01 ORDS]$ java -Dorg.eclipse.jetty.server.Request.maxFormContentSize=3000000 -jar ords.war
        This Oracle REST Data Services instance has not yet been configured.
        Please complete the following prompts
        Enter the location to store configuration data: /u01/app/oradi/ORDS/params
        Enter the name of the database server [localhost]:diatmlckidb01.
        Enter the database listen port [1521]:1522
        Enter 1 to specify the database service name, or 2 to specify the database SID [1]:
        Enter the database service name:DMLCKI
        Enter the database password for ORDS_PUBLIC_USER:
        Confirm password:
        Requires to login with administrator privileges to verify Oracle REST Data Services schema.
        Enter the administrator username:sys
        Enter the database password for SYS AS SYSDBA:
        Confirm password:
        Retrieving information.
        Enter the default tablespace for ORDS_PUBLIC_USER [SYSAUX]:
        Enter **1** if you want to use PL/SQL Gateway or **2** to skip this step.
        If you are using Oracle Application Express or migrating from mod_plsql then you must enter **1**:
        Enter the database password for APEX_PUBLIC_USER:
        Confirm password:
        Enter **1** to specify passwords for Application Express RESTful Services database users (APEX_LISTENER, APEX_REST_PUBLIC_USER) or **2** to skip this step:
        Enter the database password for APEX_LISTENER:
        Confirm password:
        Enter the database password for APEX_REST_PUBLIC_USER:
        Confirm password:
        Nov 28, 2019 6:38:12 AM
        Installing Oracle REST Data Services version 19.2.0.r1991647
        ... Log file written to /home/oradi/ords_install_core_2019-11-28_063812_00625.log
        ... Verified database prerequisites
        ... Created Oracle REST Data Services proxy user
        ... Created Oracle REST Data Services schema
        ... Granted privileges to Oracle REST Data Services
        ... Created Oracle REST Data Services database objects
        ... Log file written to /home/oradi/ords_install_datamodel_2019-11-28_063822_00076.log
        ... Log file written to /home/oradi/ords_install_apex_2019-11-28_063823_00607.log
        Complete installation for Oracle REST Data Services version 19.2.0.r1991647. Elapsed time: 00:00:12.537.

You should be able to access the URL for APEX, **http://localhost:8080/apex/apex_admin**,
from your web browser.


### Conclusion

APEX, the Oracle tool for database and web application development, replaced the
legacy Oracle forms applications. Oracle APEX is a better choice because it
quickly builds applications at a low cost and enables DBAs to address the
requirements of your customers.

ORDS gives you direct access to your database access through a HTTP or HTTPS
request, so you can easily modify your data for an existing application. Software
developers just call a web service to interact with the database.

Use the Feedback tab to make any comments or ask questions. You can also
[chat now](https://www.rackspace.com/#chat) to start the conversation.

<a class="cta red" id="cta" href="https://www.rackspace.com/dba-services">Learn more about Databases.</a>

