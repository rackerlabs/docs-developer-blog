---
layout: post
title: "Sitecore Performance Boost Addon"
date: 2016-09-02 00:00
comments: false
author: Jimmy Rudley
authorIsRacker: true
published: true
categories:
  - Devops
  - database
---

Sitecore has the option of making use of TempDB in Sql Server to speed up your session state operations. What catches people off guard is the fact that tempdb is recreated at service restart of SQL Server. This becomes a problem when you have to recreate the table structure and user permissions inside tempdb.

<!-- more -->

The script that creates the table structure and stored procedures to make use of TempDB is located in the extracted Sitecore zip file path **Sitecore 8.1 rev. xxxxxx\Databases\Scripts\**  The file **Sessions db performance boost.sql** This post will not go over what this file does. However, let me point out that it creates a stored procedure in the Master db that creates the table and index structure in the TempDB, but it does not set the permissions to actually access it. We can create a script using T-SQL that will reinitialize the table and index structure and re-create the user with correct permissions. This assumes that you ran **Sessions db performance boost.sql** already.

```sh

exec [master].[dbo].[Sitecore_InitializeSessionState] --create the tables and indexes in TempDB

USE [tempdb]
IF NOT EXISTS(select name from sys.database_principals where name = 'cdsAccount') --continue if the db user account does not exist
BEGIN
CREATE USER [cdsAccount] FOR LOGIN [sql1\cdsaccount] --create the db user in tempdb
ALTER ROLE [db_datareader] ADD MEMBER [cdsAccount] -- assign the data reader role to our db user
ALTER ROLE [db_datawriter] ADD MEMBER [cdsAccount] -- assign the data writer role to our db user
END

```

The T-SQL executes the stored procedure to re-initialize the table and index structure. Then it checks to see if the database user **cdsAccount** exists. If the user does not exist, it creates the user and assigns the data reader and data writer role to the account.

We have the code, but how do we apply it when the service restarts? We can create a SQL Agent Job that we specify to run when the SQL Server Agent starts up. I have included the complete .sql script which creates the sql job for you. The readme file in the repository includes the lines you need to change for the database user that you want to create and check for.


[T-SQL Script with SQL Agent Job](https://github.com/jrudley/Sitecore-Sql-Perf-Addon)

[Sitecore documentation snippet to optimize SQL Server performance](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/xdb/session_state/walkthrough_configure_a_shared_session_state_database_using_the_sql_server_provider)



