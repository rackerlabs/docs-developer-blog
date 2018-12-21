---
layout: post
title: "Understanding Amazon Aurora HA Strategies"
date: 2018-12-26 00:00
comments: true
author: Ash Hornbeck
published: true
authorIsRacker: true
authorAvatar: https://www.gravatar.com/avatar/f96915d3f29e5623f9a9ff8c7cb3148f
bio: "Ash Hornbeck is a Sr. Product Architect on the Rackspace Managed Public Clouds Product Architecture Team."
categories:
    - AWS
    - Database
metaTitle: "Understanding Amazon Aurora HA Strategies"
metaDescription: "A look at several High Availability strategies available in Amazon Aurora."
ogTitle: "Understanding Amazon Aurora HA Strategies"
ogDescription: "A look at several High Availability strategies available in Amazon Aurora."
---
If you are reading this, you have probably heard of Amazon Aurora.  As you know, Amazon Aurora is a PaaS service provided by AWS as part of the RDS suite of services.  It provides a fully managed relational database management system (RDBMS) that comes in two flavors, MySQL and Postgres, while maintaining wire compatibility with both. But, how does this impact your high availability strategies and options? 

<!-- more -->

You may be wondering how Amazon Aurora is different than MySQL or PostgreSQL on Amazon RDS.  These are fully managed RDBMS services also, correct?  Yes, but they are essentially the standard open-source implementations running on a fleet of EC2 instances and managed by AWS.  The key difference with Aurora is that AWS separated the storage engine from the database engine.  AWS applied the Separation of Concerns Principle to open-source databases.

## Separation of Concerns

Normally, a RDBMS has to run on generally available hardware.  This means that the implementation must work within the limitations imposed by the OS and hardware to accomplish all of the features we have come to expect from a modern database, such as: DML and DDL processing, ACID compliant transactions, replication, high-availability (HA), and fault tolerance.  If, however, the implementation was not required to run on generally available hardware but only in an environment specifically designed for a database, the various responsibilities could be separated into layers, allowing the database engine and storage engine to be focused and specialized.  As a result, high-availability and performance can be significantly increased – up to 5x more performance than stand MySQL and up to 3x more than standard PostgreSQL.

Ok, it's faster, but how does a specialized database and storage engine help us with HA?  There are several ways this helps us achieve HA. Before we get into that though, let's have a quick look at how the Aurora storage engine works to help us understand how HA is derived from this separation.

When data is written to the Aurora storage engine, the engine takes care of ensuring the data is written consistently, correctly, and durably.  Data is written in two locations in each of three availability zones, for a total of six different places.  The storage engine handles the complexities of making sure all of that happens correctly.  While maybe a bit of an oversimplification, essentially the database engine can now “fire-and-forget”, no longer needing to worry about if the data was written, transaction logs, the possibility of needing to recover, etc. 

Removing the storage concern from the database engine, a number of HA strategies become available.

## Read Replicas

While the concept of Read Replicas long predates Aurora, the implementation in open-source solutions involves log shipping or query replays.  With Aurora, Read Replicas have read-only access to the exact same storage as the master.  This means very little replication latency from the time data is written to the time it becomes visible to the Read Replica (replication lag would be a misnomer in this scenario).  When multiple Read Replicas are needed, all Read Replicas see the same data, removing overhead and complexity put on the master, found in standard MySQL and PostgreSQL implementations.  These features come together to allow a Read Replica to immediately take over if the master fails.  In addition, AWS handles replacing the failed instance, to meet provisioned capacity, with a new instance and updates DNS to point to the new master.

This is a great solution for applications that have a high read-to-write ratio.  However, keep in mind that your primary instance must be large enough to handle the entire write load.  Also, for write HA, you want to provision at least one Read Replica that is the same size as your master.  Then, set this Read Replica as the priority instance to be promoted to the primary instance.  In the case of failure, you will maintain high availability for both read and write capacity.

## Autoscaling

Autoscaling is the ability to horizontally scale out (add instances) or scale in (remove instances) from your set of available servers.  You may have heard of Autoscaling for EC2 instances, but did you know you can have elasticity in your Aurora Read Replicas also?  Typically, you will configure a minimum number of Read Replicas to handle your base load and have autoscaling policies to add or remove instance as demand changes.  The ability to leverage elasticity is another derivative of the fact that the storage engine is separate from the database engine.

An example scenario where this would be useful is a B2B ecommerce site.  It will experience heavy traffic during weekday business hours but very little overnight and on weekends.  Images and content descriptions have a high read-to-write ratio and benefit from both Read Replicas and Autoscaling.  Autoscaling your Read Replicas allows you to meet demand during peak hours while minimizing cost during off hours.

## Cross-Region Replication

If you need to bring availability to the next level, replicate it to another region.  By having the database engine replicate the data to another region, it can be read locally or used in case of failure of the primary region.  The instance in the secondary region is treated as a Read Replica (this is not multi-master), but it can also have its own Read Replicas or become the master if the primary region fails.
 
There are many reasons why cross-region replication would be needed.  Sometimes the data is just too important to be stored in a single geographic region.  This may be due to business continuity, regulatory, or financial reasons.  Another reason is reduced latency between users and the database backend.  Using ecommerce as an example once again, changes to images and descriptions can be applied to the master in a single region but be distributed globally to be read locally. 


## External Replication

What about situations where you need the data outside of the Aurora cluster?  There are situations where corporate policies or regulatory environment demand it, or you have a need to process the data or run reports outside of Aurora.  All of these cases can be handled by using External Replication.

It is easy to have Aurora replicate the data to an Amazon EC2 MySQL instance, an Amazon EC2 instance running MySQL, or even a MySQL instance running in your corporate data center. Using this one-way replication, your data is always in sync with your Aurora cluster and available for use outside of Aurora.

## Serverless

Last, but certainly not least, is serverless.  Maybe one of the most significant developments for availability and scalability is the addition of serverless to the equation.  Obviously serverless does not mean there are no servers.  It means that you do not have to worry about the provisioning, configuration, scaling, or maintenance of any servers. 

To configure Aurora Serverless, you specify the capacity available to your application and AWS handles the details of making sure that capacity is available on demand, when your clients need it.  For serverless, an additional layer, a proxy layer, has been added to the two existing layers, the database engine and storage engine.

AWS maintains a fleet of proxy servers that listen for incoming requests.  In addition, a warm pool of DB capacity is waiting to serve the request.  When your first query comes in, the proxy fleet receives it, requests an instance from the warm pool, and forwards the request to that instance, after it's allocated for your use.  Even better, the number of instances allocated for your use is elastic and scales in and out based on demand and the limits you specify in the Aurora Serverless configuration.  As with earlier strategies, the ability to dynamically allocate a database engine to you is made possible by the separation of database and storage.  Based on your configuration, the database instance stays assigned to you and available for immediate use.  After the timeout period expires, the instance is returned to the warm pool.  You are only charged for resources you are using.  When an instance is allocated for your use, you are charged for it plus any consumed storage.  When not allocated, you are only charged for the storage consumed.

For workloads that are spikey, such as development and test environments, or new applications that simply do not have enough history to predict usage patterns, serverless is the way to go.  You no longer pay for resource you are not using, do not have to worry about making sure the development team turned the lights out before leaving for the weekend, and you won't be woken up in the middle of the night to adjust capacity because your users' time zone coincides with your sleep zone.

## Wrapping Up

Amazon Aurora is built with availability, durability, and scalability in mind.  If used like standard open-source implementations, you have a solid, reliable, and performant database.  With a little deeper look at Aurora's capabilities and the patterns to leverage them, you can implement a solution to meet your needs, from local read offloading to a globally distributed availability.
