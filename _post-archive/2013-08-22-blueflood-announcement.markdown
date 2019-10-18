---
layout: post
title: 'Blueflood: A new Open Source Tool for Time Series Data at Scale'
date: 2013-08-22T08:00:00.000Z
comments: true
author: James Burkhart
published: true
categories:
  - Cloud Monitoring
---
Time series data can yield some of the most interesting and relevant information for developers, operators and businesses. But ever larger datasets coming from multiple sources are making it difficult for people to pull real, actionable intelligence from these time series streams.

We've been working on a tool called <b>Blueflood</b> that makes managing massive-scale time series metrics much easier and are pleased to be open sourcing it for comment, collaboration and improvement. Please check out <https://blueflood.io> for documention, <https://github.com/rackerlabs/blueflood> for the source code and on Freenode IRC #blueflood for discussion.<!-- more -->

### Background

The [Cloud Monitoring](https://www.rackspace.com/cloud/monitoring/) product team at Rackspace takes metrics very seriously. We're currently processing thousands of monitoring datapoints per second and hundreds of millions of values each day. Storing all of this timeseries data in an accessible way is a pretty steep engineering challenge. Existing solutions like RRDTool or Graphite were not designed with massive scale or multitenancy in mind, so we built our own time series data backend in Java on top of Cassandra.

The first incarnation of Cloud Monitoring was only capable of performing alarming and notifications based on real-time changes in the stream of monitoring data. Persisting that data in order to support users querying for historical data was a natural progression. However, storing hundreds of millions of raw data points per day and keeping them for any significant time simply wasn't going to scale. We needed something to perform downsampling of that data to keep it at lower resolutions. Today, users of Cloud Monitoring can visualize historical data for any of their checks right in our control panel.

We ended up choosing Cassandra as the database backend as it is a natural fit for this problem. The access pattern is far more write-heavy than read-heavy. It supports custom TTLs for each write, enabling us to do things like support longer data retentions for specific customers. The fact that our team has a great deal of operational experience with Cassandra certainly influenced the decision, as did the first contributor to Blueflood development being an active Cassandra committer.

### What Blueflood Does
  * Ingests raw metric data points in the form of numeric, string, or boolean values via Scribe or HTTP interfaces.
  * Downsamples raw numeric data into 5, 20, 60, 240, and 1440 minute aggregations that provide: min, max, average, variance and count of raw data points represented.
  * Supports massive scale and multi-datacenter deployments, with a great degree of flexibility with regard to cluster configuration.
  * Supports high availability configurations. Blueflood can be set up with a high degree of redundancy and fault tolerance.

### Dependencies & Configuration:
 * [Cassandra](https://cassandra.apache.org/) -- Blueflood uses Cassandra as the data store.
 * [Zookeeper](https://zookeeper.apache.org/) -- Responsibilities for calculating rollups are handled through sharding managed through Zookeeper.

 Individual nodes can be responsible for one or more roles.
  * Ingestion: Node will be be responsible for consuming data via an HTTP interface.
  * Rollup: Node will perform downsampling calculations and summarize raw data, persisting lower resolution aggregates.
  * Query: Node will handle incoming HTTP-based queries, returning raw or aggregate data for a given time window.
   The amount of resources allocated to the tasks associated with each role can also be tuned, giving users full control of optimizing Blueflood for their own unique cluster configuration and usage patterns.

### Our Cluster:

We built Blueflood to run at massive scale, and hundreds of millions of data points per day is nowhere close to max capacity. We use a 36 node multi-datacenter cluster to run Blueflood in production. Of those, 4 nodes perform ingestion and querying, while the remaining 32 perform rollup calculations and querying. Internally, we use a Thrift-based interface for querying and ingestion that contains a lot of code specific to our internal systems. We wrote reference HTTP-based ingestion and query layers for the opensource release. The ingestion nodes are colocated with the Scribe feeds they read off of, and the rollup nodes are colocated with Cassandra.

{% img center 2013-08-22-blueflood-announcement/rollups_per_minute.png %}

### The Future:
We've got plenty of ideas for how to improve Blueflood, and there's a long road ahead of us. Some of the things we're planning to implement:

* Pre-aggregated rollups. This would enable users to send us data points that have already been rolled up by metric aggregators, such as [StatsD](https://github.com/etsy/statsd/).
* Better query support. Currently any render-time aggregation functions must be applied on the front-end. We'd like to eventually achieve feature-parity with Graphite in terms of data transformations supported.
* Metrics discovery. We'd like to get integration with [Elasticsearch](https://www.elasticsearch.org/), allowing users to perform queries. This will, at a minimum, allow glob-notation when querying for metric data.

### Contributing:
We're opensourcing Blueflood to build a community to support its development. We welcome pull requests. If you've got any questions or want to contribute, you can find us on IRC in the #blueflood channel on Freenode.
