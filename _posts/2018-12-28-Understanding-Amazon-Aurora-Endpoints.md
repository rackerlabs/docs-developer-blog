---
layout: post
title: "Understanding Amazon Aurora Endpoints"
date: 2018-12-28 00:00
comments: true
author: Ash Hornbeck
published: true
authorIsRacker: true
authorAvatar: https://www.gravatar.com/avatar/f96915d3f29e5623f9a9ff8c7cb3148f
bio: "Ash Hornbeck is a Sr. Product Architect on the Rackspace Managed Public Clouds Product Architecture Team."
categories:
    - AWS
    - Database
metaTitle: "Understanding Amazon Aurora Endpoints"
metaDescription: "A look at the various Aurora Endpoint types and when to use them."
ogTitle: "Understanding Amazon Aurora Endpoints"
ogDescription: "A look at the various Aurora Endpoint types and when to use them."
---
If you've ever used Aurora Read Replicas, you may have noticed that there are several different endpoints available.  The _Cluster Endpoint_, the _Reader Endpoint_, and _Instance Endpoints_... with all of these options, how do you know which one to use and when?  As with any non-trivial system, the answer is... it depends.  In this blogpost, we'll look at the different endpoints, use-cases for them, and the trade-offs that come with those design decisions.

<!-- more -->

First, let's touch on the different endpoints available with Amazon Aurora.

* **Cluster Endpoint** – The _Cluster Endpoint_ connect your application to the current primary DB instance for that DB cluster.  Your application can both read and write to this instance.

* **Reader Endpoint** – The _Reader Endpoint_ load-balances connections across the pool of available Read Replicas. Offload read queries here, reducing load on your primary DB instance.

* **Instance Endpoints** – An _Instance Endpoint_ connects to a specific instance in the cluster.  Clients can have fine-grained control over query allocation, rather than having Amazon Aurora handle connection distribution.

I know what you're thinking... I'll just connect to the _Cluster Endpoint_ for writes, the _Reader Endpoint_ for all reads, and why would I ever connect to a specific instance – that bypasses the built-in fault tolerance and is asking for trouble, right?  As eluded to earlier, your application and its interaction with Aurora create a complex (or at least a non-trivial) system.  With complex systems, one-size fits all is not a rule to rely on... unless you enjoy calls in the middle of the night.

Let's go through some scenarios and look at when and where to use the various endpoints.

## Immediate Consistency

Some applications expect the data to be immediately consistent.  When these applications write data, they immediately read the data in strict compliance with any of the many design patterns that say, "rely on the model, not your local data".  Amazon Aurora is ACID-compliant; a read from the _Cluster Endpoint_ immediately after a successful write commit will retrieve the expected data (assuming another transaction did not modify the data before the subsequent read).

Where the trouble happens is when writes are sent to the _Cluster Endpoint_ and reads are made to the _Reader Endpoint_.  This is due to the latency between writing data and when it becomes visible to the readers.  While the replication latency is under 100 milliseconds, it isn't instantaneous, leading to a race condition.  If you have a scenario where you need to immediately read data after writing, use the _Cluster Endpoint_ for both reads and writes.  It should be noted, if additional performance is required, you must increase the size of your primary instance.

However, if eventual consistency is acceptable and your application supports it, using the _Reader Endpoint_ is a great way to reduce the load on your primary instance.

## Offloading Reads

If immediate reads after writes are not ok, what's the point of having a separate a _Reader Endpoint_?  There are many use-cases where slightly inconsistent data is not an issue.  For  example: daily reporting.  When running batch jobs to generate reports from yesterday's data, a 100-millisecond replication lag is inconsequential.  It's easy to imagine other scenarios, such as product descriptions on an ecommerce site... you are more likely to have stale data in the user's browser than be impacted by the replication lag.

Generally, read-heavy workloads that do not rely on immediate consistency should consider using the _Reader Endpoint_.

## Non-uniform Workloads

There are situations where it makes sense to use _Instance Endpoints_.  Let's say you have an application that has a number of stateless microservices behind an Elastic Load Balancer.  In this situation, it is reasonable to assume that queries will be evenly distributed across the clients, and therefore, across the Read Replicas – when using the _Reader Endpoint_.

But what about the situation where the workload of each client is not uniformly distributed?  If a reporting service is added to the mix, one Read Replica will have a disproportionally high load as compared to the others.  If the before-mentioned microservices also use this Read Replica, there is a high probability of poor query performance when querying the instance used by the reporting service.  One approach to avoid this is to manage the distribution of connections on the client side, rather than letting Amazon Aurora do this for you.  Luckily, this is easily done by using _Instance Endpoints_ instead of the _Reader Endpoint_.  With the MariaDB Connector/J for Aurora for MySQL or Fast Failover with Amazon Aurora PostgreSQL, the driver can be made aware of the individual instances you want to use as Read Replicas, allowing the driver to directly manage how queries are distributed to individual instances.

## Manage DNS Caching

In addition to understanding the nature of your workloads, it is important to understand how connections are allocated to provide Aurora's High Availability and the _Reader Endpoint_ load balancing.

Management of automatic _Cluster Endpoint_ failover and _Reader Endpoint_ load balancing are handled through DNS (Amazon Route 53), not at the IP, TCP, or database client protocol layers. Handling distribution of connections through DNS means your that application must make a DNS query for each new connection request.  Applications that use DNS caching should adjust the cache timeout to match the DNS record TTL for Amazon Aurora.  Caching DNS responses longer than the Aurora DNS record TTL will result in a couple of error conditions.  If there is a High-Availability (HA) failover event, that is, a Read Replica is promoted to Primary, a cached DNS response will mean your application will attempt to reconnect to the old, failed instance.  In the case of the _Reader Endpoint_, caching the DNS response results in multiple connections going to a specific Read Replica instead of being distributed across the available Read Replicas.

## Wrapping Up

As we can see, there is no one-size-fits-all solution when it comes to a non-trivial production workload.  If your application needs immediate consistency, then make sure both reads and writes are sent to the _Cluster Endpoint_.  When read queries can handle a little replication lag, offload read queries to the _Reader Endpoint_.  If you can use Read Replicas but your queries are not uniformly distributed across all clients, then use the _Instance Endpoints_ and manage the distribution of connections on the client side.  Just don't forget, if your application uses DNS caching with cache timeouts longer than the DNS record TTL, endpoints will appear to not behave as expected during _Cluster Endpoint_ HA failovers or when using the _Reader Endpoint_.

Understanding the nature of your application, how the Aurora Endpoints behave, and correctly applying that knowledge will lead to a more robust application environment, which is very important to you and your customers.  No one wants an outage call in the middle of the night.
