---
layout: post
title: "A Case for MongoDB with AEM"
date: 2015-11-09 10:00
comments: true
author: Jonathan Hurley
published: true
categories:
    - MongoDB
    - AEM
--- 

What is MongoDB?
----------------

MongoDB is, among other things, a document-oriented NoSQL database. This means that it 
deviates from the traditional, relational model to present a flexible, horizontally scaling 
model for data management and organization.

How does MongoDB work with AEM?
-------------------------------

MongoDB integrates with Adobe Experience Manager (AEM) by means of the crx3mongo runmode 
and JVM options: -Doak.mongo.uri and -Doak.mongo.db 

Why would I MongoDB?
--------------------

Primarily MongoDB provides an alternate HA configuration to the older CRX cluster 
configuration. In reality, the architecture is more similar to a shared catalog on NFS or 
to NetApp than true clustering. The authors and publishers using MongoDB are not 
necessarily aware of each other.

<!-- more -->

Let's get it out of the way - CRX clustering doesn't have a spotless track record. One of 
the inherent challenges to a local-only object catalog is that, at scale, a single catalog 
presents several benefits:

* reduced duplication of data
* concentrated scope for performance analysis and tuning
* HA availability without requiring multi-node interaction
* horizontal scaling for redundancy and performance

Even with a perfectly working CRX cluster, none of these benefits are addressed. Enter the 
so-so old days of shared data tier.

With 5.6.1 and earlier, large and growing deployments could mount their object 
repository as shared NFS, where the protocol, or NFS server, provided locking support 
for multi-write behavior with low collision. This is still a viable option, but, unless 
employing NetApp, there is often a risk of single point of failure in the controller, or 
the data tier, that holds back the n*9 architecture.

The introduction of the MongoDB microkernel into AEM 6.x provides essentially the same 
architecture with the more buzzword-heavy database that we love.
 
The primary use-case for MongoMK is with AEM author instances, where the active user limit 
(~25-30) means that horizontal scaling must first address the concurrency issue. Here, the 
shared data tier shines brightest as performance is second fiddle to scale and consistency 
while simultaneously eliminating the need for node-to-node communication.

It is certainly possible to still join publishers in similar fashion, however, the benefits 
are reduced due to the lack of a concurrency issue (i.e. just add more publishers for more 
scale) and the performance penalty of a non-local catalog.

So that's it then! Scale to infinity and beyond!

Slow down, Buzz Lightyear, there's a problem. Single-site MongoDB is expected to 
scale very effectively given its option for fast-access data and in-line networking. Here, 
the sky could be the limit. Consider, though, a multi-site deployment where MongoDB replica 
sets must communicate across disparate data centers and unknown miles of fiber. Enter the 
operations log (oplog).

The oplog is the intermediary for replicas to remain synchronized; essentially providing a 
series of delta operations to be applied in order. This is fairly similar to certain other 
database cluster configurations.

During optimized operation, the oplog is executed as close to realtime with the primary as 
possible, although MongoDB does permit drift. During multi-site operation, however, wire 
latency and operation latency can stack to introduce greater drift and present the following
challenges to this configuration:

* The oplog is functionally a stack of commands.
* Like many stacks, it is first-in - first-out.
* Stack behavior dictates that, when the next push will overwrite an un-popped record, 
  data loss will occur.

MongoDB programmers have elected to catch and address this situation by having the replica 
halt, rebuild, and sync forward from the (new) oplog after its rebuild.

On the surface, there's nothing exotic or dangerous about this operation. Consider first the 
rebuild operation, which wipes all data and thens pull a fresh copy from the known-good 
primary. Even if the export takes zero seconds to complete, the copy of the data volume 
across a latent wire will inherently introduce drift before the remote replica has even 
finished importing. Assume also that wire latency is the only challenge, so that, after 
rebuild, the oplog only contains the drift introduced by the rebuild. The original issue 
that triggered replication lag remains, so it can be expected that, over time, the newly 
built secondary will be forced to rebuild again.

In some cases, this behavior enters an unending loop of replication lag and rebuild,   
resulting in remote secondaries which are never in a functional state.

For AEM, this means that using MongoDB replicas as the primary data source for cross-site 
authoring places remote authors at significant risk.


