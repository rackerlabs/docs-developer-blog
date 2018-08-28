---
layout: post
title: "Oracle Data Integrator 11g performance bottlenecks"
date: 2018-08-16 00:00
comments: true
author: Sivaram Kolla
published: true
authorIsRacker: true
categories:
    - General
---

Originally published by TriCore: April 4, 2017

This blog post aims to help Oracle&reg; Data Integrator (ODI) designers,
administrators, and system teams address performance bottlenecks
in ODI execution plans. Following the steps outlined here will result in a
speedier experience for your end users.  

<!-- more -->

### Introduction

Performance bottlenecks in ODI execution plans occur for eight primary
reasons. The following list is ordered by the priority in which they
should be addressed:

1. Network latency
2. Temporary memory allocation
3. Application memory allocation
4. Sequential vs. parallel processing of fact groups
5. Source database connection type
6. Optimal usage of indexes
7. Reduce data movement
8. Execution location of transformations

### Network latency

The Batch Update/Array Fetch configuration is a compromise between network and
agent overhead. With a highly available network, you can keep low values (such
as those below 30). With a poor network, you can use larger values (100 and
higher).

The following parameters help tune this data flow:

1. *Array Fetch* in the source data server definition
2. *Batch Update* in the target data server definition

### Temporary memory allocation

Temporary spaces are used during aggregation of data, during lookup queries,
or during sessions that are running in parallel.  

For optimal performance, the temporary space should equal the table space.  

### Application memory allocation

Application memory allocation refers to Oracle WebLogic memory. If the agent
needs to have data flowing through it, it should not be installed on a machine
that doesn't have spare resources. In ODI 11g, you can adjust the
`ODI_INIT_HEAP` and `ODI_MAX_HEAP` parameters in the `odiparams` configuration
file to define the agent's Java&reg; virtual machine (JVM) initial and maximum
heap size.  

![The `ODI_INIT_HEAP` and `ODI_MAX_HEAP` parameters highlighted in the
odiparams configuration file]({% asset_path 2018-08-16-odi-bottlenecks/picture1.png %})

**Default values**:

The configuration file has the following default values:

- ODI_INIT_HEAP: 32 MB
- ODI_MAX_HEAP: 256 MB
- Max No of Connections: 10

**Recommended values**:

The following values are recommended for the best possible performance:

- ODI_INIT_HEAP: 512 MB
- ODI_MAX_HEAP: 4096 MB
- Max no of connections: 20

The `ODI_MAX_HEAP` value can be increased to approximately half the size of
the RAM available on the server on which the ODI Agent is running.

### Sequential vs. parallel processing of fact groups

When you're running a load plan with the serial steps for fact groups,
individual task run times are less. However, the total time for load plan
completion is higher. If you execute your load plan with out-of-the-box (OOTB)
parallel steps for fact groups instead, the total time is less, but individual
task run times are higher. If you want to increase the number of concurrent
connections to user schema, consider that the total load time is less with
parallel steps.

### Source database connection type

ODI has two options for connecting to the source database for source-dependent
extract (SDE) loads: Java Database Connectivity (JDBC) connections and DB
Links. DB Links provide better performance optimization, according to a study
of SDE load execution times for these two options.  

### Optimal usage of indexes

Optimizing source indexes might help enhance load performance. Use the
following steps to optimize source indexes:

1. Analyze the Explain Plan for SDE queries.
2. Check if indexes are used on sources tables.
3. Look for the optimization scope (for example, creation and modification of
   indexes).

### Reduce data movement  

If you're aggregating a large amount of source data to generate a small data
flow to a remote target, then you should consider locating the staging area on
the source side.

![An architectural model of the source, staging area, and
target]({% asset_path 2018-08-16-odi-bottlenecks/picture2.png %})

### Execution location of transformations  

When you're filtering source data, execute the filters on the source servers
to reduce the data flow from the source to the staging area.

When you're joining source tables, complete the following steps:

1. If the expected source set resulting from the join is smaller than the sum
   of the two sources, perform the join on the source.

2. If the expected source set after the join is larger than the sum of the two
   sources, perform the join on the staging area. One example of this result
   would be when there is a cross-join.  

### Other performance tuning tips

Be aware while you're setting up the physical architecture. If the staging and
target areas are on the same server, then ensure that you select the correct
data schema and work schema for the tasks.

Enable archival logging on the system and regularly purge logs and archive
logs. Taking these steps will help clean up the metadata tables that use the
most storage, thereby increasing the start time and execution time of
scenarios.

### Conclusion

We hope that you find these techniques helpful for eliminating ODI performance
bottlenecks. We'd love to hear your own ideas and suggestions. You can share
them with the Rackspace developer community by posting a comment below.  

### References

The following documents were used as references for this blog post:

- [Oracle Data Integrator Performance
  Guide](http://www.oracle.com/us/products/middleware/data-integration/odi-performance-guide-wp-2147067.pdf)

- [Performance Tuning Oracle Data Integrator
  (ODI)](http://www.kpipartners.com/blog/bid/149359/Performance-Tuning-Oracle-Data-Integrator-ODI)
