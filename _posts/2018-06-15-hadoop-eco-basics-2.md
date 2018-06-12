---
layout: post
title: "Hadoop ecosystem basics: Part 2"
date: 2018-06-15 00:00
comments: true
author: Pavan Paramathmuni
published: true
authorIsRacker: true
categories:
    - Oracle
---

### Introduction

In [Part 1](2018-06-15-hadoop-eco-basics-2.md) of this two-part series on
Apache&trade; Hadoop&reg;, we introduced the Hadoop ecosystem and the Hadoop
framework. In Part 2, we cover more core components of the Hadoop framework,
including those for querying, external integration, data exchange,
coordination, and management. We also introduce a module that monitors Hadoop
clusters.

#### Querying

Part 1 of this series introduced Apache Pig&trade; as a query tool. Written in
Pig Latin, Pig is translated into executable MapReduce jobs. It offers several
advantages that you can learn more about in the previous article.

Even so, some developers still prefer SQL. If you'd rather go with what you
know, you can use SQL with Hadoop instead.

#### Hive

Apache Hive&trade; is a distributed data warehouse that manages and organizes
large amounts of data. This warehouse is built on top of the Hadoop
Distributed File System (HDFS). The Hive query language, HiveQL, is based on
SQL semantics. The runtime engine converts HiveQL to MapReduce jobs that query
the data.

Hive offers the following capabilities:

* A schematized data store for housing large amounts of raw data.

* A SQL-like environment for executing analyses and queries on raw data in the
  HDFS.

* Integration with outside relational database management system (RDBMS)
  applications.

The following image visualizes the architecture of the Hadoop ecosystem:

![Architecture of the Hadoop ecosystem]({% asset_path 2018-06-15-hadoop-eco-basics-2/picture1.png %})

Image source: [Hadoop Ecosystem: an Integrated Environment for Big Data](http://blog.agroknow.com/?p=3810)

#### External integration

Apache&reg; Flume&trade; is a distributed, reliable, and available service for efficiently collecting, aggregating, and moving large amounts of log data into HDFS. Flume transports large quantities of event data using a steaming data flow architecture that is fault tolerant and failover recovery ready.

* Transports large amount of event data (network traffic, logs, email messages).

* Streams data from multiple sources into HDFS.

* Guarantees a reliable real-time data streaming to the Hadoop applications.

#### Data exchange

##### Sqoop

Apache Sqoop&trade; is designed to efficiently transfer bulk data between Hadoop and external data stores such as relational databases and enterprise data warehouses. Sqoop works with relational databases such as Teradata, Netezza, Oracle, MySQL, Postgres etc. Sqoop is widely used in most companies that collect or analyze big data.

* Sqoop automates most of the process, depending on the database to describe the schema of the data to be imported.

* Sqoop uses Map Reduce framework to import and export the data, which provides parallel mechanism as well as the fault tolerance.

* It provides Connectors for all the major RDBMS Databases.

* It supports full/incremental load, parallel export/import of data and data compression.

* It supports Kerberos security integration.

#### Coordination

Apache Zookeeper&trade; is a coordination service for distributed applications that enables synchronization across a cluster. It is a centralized repository where distributed applications can store and retrieve data_.

* Zookeeper is an administrative Hadoop tool used to manage the jobs in a cluster.

* Zookeeper Hadoop is akin to a watch guard because it notifies any change of data in one node to the other.

#### Provisioning, managing, and monitoring Hadoop clusters

Apache Ambari is a web-based tool for provisioning, managing, and monitoring Apache Hadoop clusters. It has a very simple yet highly interactive user interface for installing tools and performing management, configuration, and monitoring tasks. Ambari provides a dashboard for viewing cluster health such as heat maps and ability to view MapReduce, Pig and Hive applications visually along with the features to diagnose their performance characteristics in a user-friendly manner.

* Master services mapping with nodes.

* We can always choose the services that we want to install.

* Stack selection made easy. We can customize our services.

* Has a simpler interface and saves lot of our efforts on installation, monitoring and managing so many components and their different installation steps along with monitoring controls at ease.

### Conclusion

Hadoop has been a very effective solution for companies dealing with extremely huge data. It is a much sought after tool in the industry for data management in the distributed systems. As it is an open source, it is easily available for the companies to leverage it for their use. These are some highlights on Apache’s Hadoop ecosystem. Documentation for these is available on Apache Software Foundation website.

Hadoop and its ecosystem is expected to continue growing and take on new roles over time.

Have you used Hadoop? Let us know what you think by posting a comment below!
