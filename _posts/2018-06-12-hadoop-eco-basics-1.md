---
layout: post
title: "Hadoop ecosystem basics: Part 1"
date: 2018-06-12 00:00
comments: true
author: Pavan Paramathmuni
published: true
authorIsRacker: true
categories:
    - General
---

SUMMARY HERE

<!-- more -->

### Introduction

Developed back in 2005, Hadoop is an open source framework developed using Java based programming language to support and process humongous data in a distributed computing environment. Doug Cutting and Mike Cafarella are the developers of the Hadoop.

Built on a commodity hardware, Hadoop works on the basic assumption that hardware failures are common. These failures are taken care by Hadoop Framework. Introduction:

In this blo post, we'll discuss big data, its characteristics, different sources of big data, and some key components of the Hadoop Framework.

In this two-part blog series, we'll cover the basics of the Hadoop ecosystem.

Let us start with big data and its importance in Hadoop Framework. Ethics, privacy, security measures are very important and need to be taken care while dealing with the challenges of Big data.

### Big data: When the data itself becomes part of the problem

Data is crucial for all organizations. It has to be stored for future use. We can refer the term _big data_ as the data, which is beyond the storage capacity and the processing power of an organization. What are the sources of this huge data?

There are different sources of data, such as social networks, closed caption television (CCTV) cameras, sensors, online shopping portals, hospitality data, global positioning systems (GPS), the automobile industry, and other sources that generate a huge amount of data.

Big data can be characterized as:

* The Volume of the data

* Velocity of the data

* The variety of data being processed

Volume of data is increasing rapidly in GB, TB, PB and so on, and requires a huge amount of disk space to store it.

Velocity of data is stored in data centers to cater to the organizational needs. In order to get data to the local workstation high-speed data processors are needed.

We can also broadly classify data into the following types: structured, unstructured , and semi-structured.

Big data = (Volume + Velocity + Variety) of data

![Alt text]({% asset_path 2018-06-12-hadoop-eco-basics-1/picture1.png %})

Source: http://whatis.techtarget.com/definition/3Vs

What is the Hadoop ecosystem? This term refers to the various components of the Apache&reg; Hadoop Software library. It is a set of tools and accessories designed to address the unique requirements involved in processing big data.

In other words, a a Hadoop Ecosystem is comprised of a set of different
modules that interact with each other.

### Components of the Hadoop framework

The Hadoop framework has the following core components.

#### Distributed storage

##### Hadoop Distributed File System

In Hadoop, distributed storage is referred to as the Hadoop Distributed File System (HDFS). It is a distributed file system for redundant storage. HDFS has the following characteristics:

* Designed to store data on the commodity hardware reliably.

* Built to expect hardware failures.

* Intended for large files and batch inserts. (Write once, read many times.)

![Alt text]({% asset_path 2018-06-12-hadoop-eco-basics-1/picture2.png %})

Source: http://www.tdprojecthope.com

##### HBase

HBase is a distributed, column-oriented NoSQL database. HBase uses HDFS for its underlying storage, and supports both batch-style computations using MapReduce and point queries (random reads).

It also has the following characteristics:

* Storage of large data volumes (up to billions of rows) atop clusters of commodity hardware.

* Bulk storage of logs, documents, real-time activity feeds, and raw imported data.

* Consistent performance of reads and writes to data used by Hadoop applications.

* Allows the data store to be aggregated or processed using MapReduce functionality.

* Data platform for analytics and machine learning.

##### HCatalog

HCatalog is a table and storage management layer for Hadoop that enables
Hadoop applications (such as Pig, MapReduce, and Hive) to read and write data in a tabular form as opposed to the files.

* Centralized location of storage for data used by Hadoop applications.

* Reusable data store for sequenced and iterated Hadoop processes.

* Storage of data in a relational abstraction.

* Metadata management.

Once data is stored, we want it to check it and create insights from the data.

#### Distributed processing

##### MapReduce

MapReduce is a distributed data processing model and execution environment that runs on large clusters of commodity machines. It uses the MapReduce algorithm to breaks down all the operations into Map or Reduce functions.

* Aggregation (counting, sorting, and filtering) on large and disparate data sets.

* Scalable parallelism of Map or Reduce tasks.

* Distributed task execution.

##### YARN

Yet Another Resource Negotiator (YARN) is the cluster and resource management layer for the Apache Hadoop ecosystem. It is one of the main features in the second generation of the Hadoop framework.

* YARN "schedules" applications in order to prioritize tasks and maintains big data analytics systems.

* As one part of a greater architecture, YARN aggregates and sorts data to conduct specific queries for data retrieval.

* It helps to allocate resources to particular applications and manages other kinds of resource monitoring tasks.

#### MACHINE LEARNING

##### Mahout

Apache Mahout is an open source project that's primarily used for creating scalable machine learning algorithms. Mahout is a data mining framework that typically runs with the Hadoop infrastructure in the background to manage huge volumes of data.

* Mahout offers developers a ready-to-use framework for performing data mining tasks on larger volumes of data.

* Written on top of Hadoop, Mahout's algorithms make it work well in the distributed environment.

* Mahout enables applications to analyze large data sets effectively and in quick time.

* Comes with the distributed fitness function capabilities for evolutionary programming. Includes matrix and vector libraries.

#### WORKFLOW MONITORING & SCHEDULING

##### Oozie

Oozie is a workflow scheduler system for managing Apache Hadoop jobs. Oozie runs the workflows for the dependent jobs. It enables users to create directed acyclic graphs (DAGs) of workflows that run both in parallel and sequentially in Hadoop.

Oozie also has the following characteristics:

* High flexibility. You can easily start, stop, suspend and rerun jobs.

* It makes it very easy to rerun failed workflows.

* Oozie is scalable and can manage timely execution of thousands of workflows (each consisting of dozens of jobs) in a Hadoop cluster.

#### SCRIPTING

##### Pig

We can use Apache Pig for scripting in Hadoop. Scripting is a SQL-based language and an execution environment for creating complex MapReduce transformations. First written in the Pig Latin language Pig is translated into an executable Map Reduce jobs. Pig also allows the user to create extended functions (UDFs) using Java.

Pig also offers the following things:

* Scripting environment to execute ETL tasks/procedures on raw data in HDFS.

* SQL based language for creating and running complex Map Reduce functions.

* Data processing, stitching, schematizing on large and desperate data sets.

* It’s a high-level data flow language.

* It abstracts you from the specific details and allows you to focus on data processing.

### Conclusion

Hadoop and the MapReduce framework already have a substantial base in the bioinformatics community, especially in the field of next-generation sequencing analysis. Hadoop provides the robust, fault-tolerant Hadoop Distributed File System (HDFS). HBase adds a distributed, fault-tolerant scalable database, built on top of the HDFS file system, with random real-time read/write access to data. Mahout is an Apache project for building scalable machine learning libraries, with most algorithms built on top of Hadoop. Pig is designed for batch processing of the data.

In Part 2, we'll cover more components of the Hadoop ecosystem.

Have a question? Post it in a comment below!
