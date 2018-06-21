---
layout: post
title: "Deprecated and discontinued SQL Server 2016 features"
date: 2018-06-25 00:00
comments: true
author: Anil Kumar
published: true
authorIsRacker: true
categories:
    - Oracle
---

This article identifies the deprecated Oracle&trade; SQL Server Database Engine
features that are available in SQL Server 2016 and will be removed in future
releases of SQL Server.

<!-- more -->

### Introduction

You often read about new noteworthy features in SQL Server realeases. However,
you do not always find discussions about the deprecated features when planning
to upgrade databases to a newer version. Because the roll back feature is not
available during upgrades, you need to understand the deprecated features
before migrating production databases. The following sections provide details
about features that will be discontinued in SQL Server releases after SQL Server
2016.

### Backup and restore

The following list shows the status of various backup and restore operations:

- Full and Transaction Log Backups with media password are already obsolete,
  but you can restore backups with media password in SQL Server 2016. This
  feature will be removed in a future release.

- The ``restore {database | log} with [media]password`` operation continues
  to be deprecated.

- The ``backup {database | log} with password`` and
  ``backup {database | log} with [media]password`` operations are discontinued.

### Compatibility levels

You can't upgrade directly from version 110 (SQL Server 2008 and SQL Server 2008
R2). Instead, you must first upgrade the database to SQL Server 2012 and then
upgrade the database to the current version. However, database compatibility
level ``100`` is supported. Compatibility levels are only available for the last
two versions of SQL Server.

### Encryption

Encryption using ``RC4`` or ``RC4_128`` is deprecated and is scheduled to be
removed in the next version of SQL Server. Decrypting ``RC4`` and ``RC4_128``
is not deprecated. You should start using another encryption algorithm such as
``AES``.

### Remote stored procedure

Remote stored procedures start after a Transact-SQL distributed transaction is
executed by the Microsoft Distributed Transaction Coordinator (MS DTC).

Remote servers are supported in SQL Server 2016 for backward-compatibility only.
New applications should use linked servers instead.

### Table Hints

The table hint``WITH`` keyword feature is deprecated and will be removed in
future versions of SQL Server. Newly developed apps should not use the ``WITH``
keyword.

### Separating hints with spaces

The ability to separate hints with spaces (instead of commas) will be removed
in an upcoming version of SQL Server. Do not use this feature in any new
development work and modify applications that currently use this feature as soon
as possible.

### SQLMaint utility

The SQLMmaint utility executes database maintenance plans created with previous
versions of SQL Server. This feature will be made obsolete in future versions.
Replace this utility with the SQL Server maintenance plan feature.

### Features discontinued in SQL Server 2016

The following features were discontinued in SQL Server 2016:

-  SQL Server 2016 is a 64-bit application. The 32-bit installation was
   discontinued, though some elements of SQL Server 2016 still run as 32-bit
   components.

-  Compatibility level ``90`` was discontinued.

-  The ActiveX subsystem was discontinued. Use command line or PowerShell
   scripts instead.

### Conclusion

The deprecated features listed in this blog will be removed in a future release
of SQL Server, but Microsoft has not scheduled when the removals will happen.
Test old applications before migrating to a new version of SQL Server, and
deprecated features should not be used in any new development work.

If you have any questions on this topic, comment in the field below.

