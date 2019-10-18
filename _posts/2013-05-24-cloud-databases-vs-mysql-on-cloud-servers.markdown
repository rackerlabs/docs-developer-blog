---
layout: post
title: Cloud Databases vs. MySQL on Cloud Servers
date: '2013-05-24 12:00'
comments: true
author: Edward Adame
published: true
categories:
  - Cloud Servers
---
If you need to run MySQL on the Rackspace Cloud, you have two fundamental choices: run MySQL on a Cloud Server, or run MySQL as a Cloud Database instance. This naturally raises a few questions: What are the features and benefits of each? Which performs better? Which will be more cost effective? As with every application, the answer is ”it depends;” however, the information below should help you make the right choice based on your needs.<!-- more -->

Let’s begin with performance. The graph below compares the various Cloud Database instance sizes, from 512 MB to 16 GB. Results shown are the average of five test iterations:

{% img center 2013-05-24-cloud-servers-vs-cloud-databases/cloudsrv.jpg "MySQL Performance - Cloud Servers" %}

*Performance was measured using sysbench, table size 2 million rows, run from a 4 GB Cloud Server client with 200Mbps of network throughput.*

Now let’s compare the performance of Cloud Databases with Cloud Servers, again with the same testing criteria in place:

{% img center 2013-05-24-cloud-servers-vs-cloud-databases/compare.jpg "MySQL Performance - Cloud Servers vs. Cloud Databases" %}

The results indicate that Cloud Databases generally perform better than their Cloud Server counterparts, especially when under load. When we factor price into the equation, the right choice becomes a bit more dependent on application load and requirements. The cost of a Cloud Database varies depending on how much storage you need; if I assume 10 GB of storage for the sake of discussion, the number of transactions you get per dollar works out as follows:

{% img center 2013-05-24-cloud-servers-vs-cloud-databases/value.jpg "Transactions per Dollar - Cloud Servers vs. Cloud Databases" %}

The harder the server works, the greater the performance margin is for Cloud Databases. As this margin increases, it exceeds the price difference between Cloud Databases and Cloud Servers, making Cloud Databases a better value.

So, which should *you* choose?

For lighter workloads and smaller database sizes, my suggestion would be to choose your platform based upon features instead of performance. With Cloud Databases, you don’t have to configure or patch the server. You have the convenience of a control panel interface, and three copies of the database are maintained automatically. This does not, however, protect you from accidentally dropping a table, so you should also perform a scheduled dump to disk from a Cloud Server client as illustrated here: <https://www.rackspace.com/knowledge_center/article/exporting-data>

Cloud Databases also do not allow you to modify the MySQL configuration files or configure master /slave replication, so if you need to run backups on a replicated slave, you must choose a Cloud Server. For heavier workloads and where these limitations are not a factor, Cloud Databases would likely be a better choice.

_Editor's Note: There is some confusion around the "three copies" statement in this post. Cloud Databases uses volumes to store data. Volumes are automatically provisioned on shared Internet Small Computer System Interface (iSCSI) storage area networks (SAN) that provide for increased performance, scalability, availability and manageability. Applications with high I/O demands are performance optimized and data is protected through both local and network RAID-10. Additionally, network RAID provides synchronous replication of volumes with automatic failover and load balancing across available storage clusters. --Hart_
