---
layout: post
title: "Dynamic Data Masking in SQL Server 2016"
date: 2018-07-17 00:00
comments: true
author: Vishal Srivastava
published: true
authorIsRacker: true
categories:
    - Oracle
---

SQL Server 2016 introduced three new principal security features: Always
encrypted, dynamic data masking, and row level security.

In this blog, I'm going to introduce the dynamic data masking (DDM) feature.

<!-- more -->

### Introduction

DDM limits sensitive data exposure by masking it to non-privileged users. This
helps prevent unauthorized access to sensitive data by enabling customers
to designate how much of the sensitive data to reveal with minimum impact
on the application layer. DDM can be configured on the database to hide
sensitive data as the result sets of queries over designated
database fields, which the data in the database is not changed.

Dynamic data masking is easy to use with existing applications, because
masking rules are applied in the query results.

DDM is available in SQL Server 2016 and Azure SQL Database, and is
configured by using Transact-SQL commands. For additional information about
configuring dynamic data masking by using the Azure portal, see the
[Microsoft Azure SQL Database documentation](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-dynamic-data-masking-get-started).

### How DDM works

Dynamic data masking rules can be defined on particular columns, indicating
how the data in those columns will appear when queried. There are no
physical changes to the data in the database itself; the data remains
intact and is fully available to authorized users or applications. Database
operations remain unaffected, and masked data has the same data type as
the original data, so DDM can often be applied without making any changes
to database procedures or application code.

![Screenshot]({% asset_path 2018-07-17-dynamic-data-masking-in-sql-server-2016/ddm-overview.png %})

[*Image source*](https://www.codeproject.com/Articles/1084808/Dynamic-Data-Masking-in-SQL-Server)

To add a data mask on a certain column in the database, all you need to do is
alter that column by adding a mask and specifying the required masking type.
There are four types of masks available: **default masking**, which fully
masks the original value; **partial masking** where you specify part
of the data to expose; **random masking**, which replaces the numeric
value with a random value within a specified range, and;
**email masking**, which exposes the first character and keeps the email format.

| Function | Description | Example |
| --- | --- | --- |
| **Default** | Full masking according to the data types of the designated fields.<br/><br/>For string data types, use XXXX or fewer X's if the size of the field is less than four characters (char, nchar, varchar, nvarchar, text, ntext).<br/><br/>For numberic data types, use a zero value (bigint, bit, decimal, int, money, numeric, smallint, smallmoney, tinyint, float, real).<br/><br/>For date and time data types, use 01.01.2000 00:00:00.0000000 (date, datetime2, datetime, datetimeoffset, smalldatetime, time).<br/><br/>For binary data types, use a single byte of ASCII value 0 (binary, varbinary, image). | Column definition syntax: Phone#<br/><br/>`varchar(12) MASKED WITH (FUNCTION = 'default()') NULL`<br/><br/>Alter syntax: `ALTER COLUMN Gender ADD MASKED WITH (FUNCTION = 'default()')` |
|**Partial** | Masking method which exposes the first and last letters and adds a customer padding string in the middle.<br/><br/>prefix,[padding],suffix |
