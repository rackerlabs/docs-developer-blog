---
layout: post
title: Benchmarking hosted MongoDB services
date: '2013-02-27 09:00'
comments: true
author: Paul Querna
published: true
categories:
  - General
---

When we started investigating the hosted MongoDB space, we quickly found that
most of the companies involved were just hosting MongoDB on top of AWS instances.
We were intrigued by the different approach taken by ObjectRocket.  Instead of
using AWS primitives, they built their service on their own hardware in
neighboring data centers, and utilized AWS DirectConnect to provide low latency
connectivity.

In order to validate that ObjectRocket’s architectural choices made a difference,
Rackspace conducted tests comparing ObjectRocket with two providers that offer
MongoDB on generic cloud environments. We chose to compare ObjectRocket’s
performance to the hosted providers on AWS. Further, we chose a $150 price point
per month for comparison’s sake. SoftLayer’s offering was not included in the
comparison because their least expensive MongoDB option costs around $650.

<!-- more -->

As with any benchmark, sticks can be thrown, but we believe this represents a
good baseline of the performance differences between the vendors.

### Set up

Below are the setups used for each provider:

* [ObjectRocket](http://www.objectrocket.com/): $149/month, Standard, 5gb, in the us-east zone.
* Hosted AWS Provider #1: $149/month, "Replica Set: Small", 5gb, in AWS us-east-1
* Hosted AWS Provider #2: $160/month, AWS Dedicated "Mini", 1.7gb RAM, 20gb Storage, in AWS us-east-1.

For the benchmark, we leveraged the [YCSB tool](https://github.com/brianfrankcooper/YCSB/),
which is open sourced by Yahoo Research. In order to use the latest MongoDB Java
SDK, we did make [small modifications to YCSB itself](https://github.com/brianfrankcooper/YCSB/pull/112).
While YCSB has received criticism when it's used to benchmark different backends,
we were only using the MongoDB backend so we were less concerned about this
criticism.

We built a dataset of 2.5 million records, with a 1-kilobyte average size. This
represents a good user-database type application, and puts us at a 2.5-gigabyte
total size, which fits well with the $150 price point.

To test performance we selected two workloads:

* “Session Store" 50% reads, 50% updates.
* "Heavy Reads" 100% reads.

YCSB works by putting a target throughput on the service, and then observing
actual performance of operations per second and latency. All workloads used 150
threads in YCSB, and 500,000 operations. We ran YCSB from an m3.xl EC2 instance
in the AWS us-east-1 region.

### Session Store Workload

This workload exercises the ability for a data store to handle high in-place
updates of data. MongoDB has well known limitations in this space, because of
its [locking design](http://docs.mongodb.org/manual/faq/concurrency/) that
causes contention and performance degradation at high loads.

{% img center 2013-02-27-benchmarking-hosted-mongodb-services/session-store-throughput.png "Session Store, Throughput (Higher is better)" %}

ObjectRocket’s system met the desired throughput to over 3,000 ops/s, and showed
no signs of breaking down while the AWS hosted providers began to degrade at
either 1,000 ops/s or 1,500 ops/s.

Because this is a 50% write workload, the MongoDB Lock contention became a
problem on all of the platforms.

{% img center 2013-02-27-benchmarking-hosted-mongodb-services/session-read-latency.png "Session Store, Read Latency (lower is better)" %}

To get a full picture of the latency differences, we created a zoomed-in graph
of the preceding graph.

{% img center 2013-02-27-benchmarking-hosted-mongodb-services/session-read-latency-zoomed.png "Session Store, Read Latency (lower is better)" %}

ObjectRocket produced a consistent latency of 2ms regardless of target throughput.
Hosted AWS Provider #1 sustained consistency around 20ms. Hosted AWS Provider
#2 quickly spiked to 200ms of latency under load.

{% img center 2013-02-27-benchmarking-hosted-mongodb-services/session-update-latency.png "Session Store, Update Latency (lower is better)" %}

ObjectRocket repeated its 2ms latency for all update operations, with both
AWS-hosted offerings growing to nearly 300ms.

### Heavy Reads Workload

Heavy reads workloads, such as web applications like CMS's which commonly have
many viewers and few updaters, are MongoDB's bread and butter. MongoDB generally
provides super low latency access to your data and little CPU overhead.

{% img center 2013-02-27-benchmarking-hosted-mongodb-services/heavy-reads-throughput.png "Heavy Reads, Throughput (higher is better)" %}

ObjectRocket met all target throughputs up to 10,500 ops/s and showed little
signs of degradation. Hosted AWS Provider #1 trailed off before 3,000 ops/s and
Hosted AWS Provider #2 never got past 1,200 ops/s.

{% img center 2013-02-27-benchmarking-hosted-mongodb-services/heavy-reads-latency.png "Heavy Reads, Latency (lower is better)" %}

ObjectRocket delivered consistent 2ms results until above 6,500 ops/s, past which
we saw latencies increase up to 20ms. Hosted AWS Provider #1 kept up sub-10ms
performances until load grew beyond 1,500 ops/s, but then performance degraded.
We observed high variability in Hosted AWS Provider #2’s performance, and under
peak load it delivered read results around 430ms.

### Conclusion

Don't just take our word for it, ObjectRocket is currently
[offering 30 day free trials](http://objectrocket.com/pricing) so you can test
out your own application and workloads.

P.S.: Rackspace is always hiring outstanding developers. For more information
on software developer jobs at Rackspace, visit our
[careers page](http://jobs.rackspace.com/go/software-developer-jobs/247407/)

### Disclaimer

*This Comparative Service Portfolio outlines general information
regarding our services and services of our competitor. The information
contained in this document is obtained from public sources and is as
accurate as possible, but may not be 100% comprehensive. The
information was last updated on February 27, 2013. ALL STATEMENTS AND
INFORMATION ARE PROVIDED "AS IS", FOR INFORMATIONAL PURPOSES ONLY, AND
ARE PRESENTED WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. OUR
PRODUCT/SERVICES OFFERINGS ARE SUBJECT TO CHANGE WITHOUT NOTICE.*
