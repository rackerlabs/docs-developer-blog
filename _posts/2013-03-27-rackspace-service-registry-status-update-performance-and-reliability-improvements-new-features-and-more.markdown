---
layout: post
title: 'Rackspace Service registry status update: Performance and reliability improvements, new features, and more'
date: '2013-03-27 08:00'
comments: true
author: Tomaz Muraus
categories:
  - General
---
Back in November we announced the [Rackspace Service registry preview](http://www.rackspace.com/blog/keep-track-of-your-services-and-applications-with-the-new-rackspace-service-registry/).
Since then we have been busy listening to user feedback, using that data along
with other metrics and inputs to improve our service in different ways.

This blog post provides a high level overview of some of those changes and
improvements. It describes some of the new features we have added and things
we have changed, improved and removed to make the whole API faster, better,
more reliable and user-friendly.

<!-- more -->

### Performance and reliability improvements

We spent a lot of time making the whole service faster and more reliable. This
includes improvements ranging from data model adjustments, adding new services
and in some cases, algorithmic changes to the code.

Besides spending a lot of time on the code changes we also spent a lot of time
tweaking and upgrading our infrastructure. One of the bigger upgrades we have
performed recently has been an upgrade from Cassandra 1.1 to Cassandra 1.2.

When we initially started working on Rackspace Service registry, Cassandra 1.2
hasn’t been stable yet and that is why we started with 1.1. We have primarily
upgraded to 1.2 so we can, among other things, take an advantage of an
optimized and more efficient [tombstone removal](http://www.datastax.com/dev/blog/tombstone-removal-improvement-in-1-2)
and a great new feature called [virtual nodes](http://www.datastax.com/dev/blog/virtual-nodes-in-cassandra-1-2).

{% img center 2013-03-27-rackspace-service-registry-status-update/vnodes.png %}
<p style="text-align: center">Virtual nodes among other things make operations
such as bootstrap faster and allow users to more easily run Cassandra on
heterogeneous hardware. Picture taken from http://www.datastax.com.</p>

Prior to making the Cassandra 1.2 upgrade, we needed to make [some changes](https://github.com/racker/node-cassandra-client/pull/64)
to the [open source Node.js Cassandra client](https://github.com/racker/node-cassandra-client)
we are one of the main contributors to.
The client now works with Cassandra 1.2 using a default Thrift transport in CQL
2.0 compatibility mode. We currently have other priorities and no short-term
plans for switching to [CQL 3.0](http://www.datastax.com/dev/blog/whats-new-in-cql-3-0)
or the [new binary protocol](http://www.datastax.com/dev/blog/binary-protocol).
This functionality is not available in the client yet. If you need this
functionality yourself and you are willing to contribute it please free to do
so. The Node.js Cassandra client is an open-source Apache 2.0 licensed project
and contributions of any kind (code, documentation, tests) are are appreciated
and more than welcome.

Another Apache Cassandra 1.2 feature we have recently started experimenting
with is [PBS consistency predictions](http://www.bailis.org/blog/using-pbs-in-cassandra-1.2.0/).

In a nutshell, PBS helps you to measure and figure out how eventual and how
consistent is the eventual consistency. You can then use those measurements and
predictions to determine the optimal consistency value which should be used for
different Cassandra reads and writes. If you want to know more about PBS we
encourage you to check [this page](http://pbs.cs.berkeley.edu/).

We have only just begun, so we don’t have a lot of data and insights yet.
When we do, we will make sure to share observations from our single-region
Cassandra cluster running on Rackspace Cloud Servers with you in another
blog post.

### Configuration namespaces

The [configuration storage](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/overview.html#what-is-rackspace-service-registry-configuration-storage)
feature allows users to store arbitrary key/value pairs in our system and get
notified when a value is updated or removed. This allows you to build more
robust and responsive services which react to configuration changes faster.

This feature worked well enough for simple cases, but if you wanted to organize
values in some special way or there were complex relationships between
different configuration values you needed to implement a lot of client side
logic and filtering to make it work.

To support those more advanced use cases, we decided to add a feature called
"Configuration namespaces". Configuration namespaces allows you to organize
different (related) configuration values together in a hierarchical manner.
They also make retrieving a subset of configuration values easier and more
efficient.

{% img center 2013-03-27-rackspace-service-registry-status-update/configuration_namespaces_tree_visualization.png %}
<p style="text-align: center">Configuration namespaces visualized using a tree</p>

In the example above we have a configuration value *listen_ip* and
*listen_port* under a namespace */production/cassandra/*. Namespace on the
first level represents an environment (*production*) and namespace on the
second level represents a service (*cassandra*).

Using this naming scheme allows us to very easily and efficiently retrieve
all the configuration values under namespace */production/* and
*/production/cassandra/*.

When you refer to a configuration value which has a namespace you need to
refer to it using a fully qualified path. In this example this is
*/production/cassandra/listen_ip* and */production/cassandra/listen_port*.

This feature is fully backward compatible which means you don’t need to make
any changes to your existing code and it will continue functioning normally.

If you are currently using some convention to encode hierarchy / namespaces
in the configuration key we encourage you can take an advantage of the new
first-class namespaces feature which, among other things, makes organizing
and retrieving a subset of configuration values easier and more efficient.

### Folding sessions into services: a simplification

When we first released service into preview in November, it included a concept
called a session. The whole idea behind the session concept was to allow users
to organize multiple related services under a single session and only heartbeat
a single session instead of multiple services.

A good example of this is a Java process which has two threads performing
different work. With the first version of the API you could create a single
session with two services (one for each thread) and then heartbeat this
session.

At the beginning, this sounded like a good and powerful feature. In practice
it turns out that services and sessions generally mapped out 1-to-1. Having
them logically separated made the public API more complex and both harder
to use and consume.

It made good sense to optimize the API for the common case where a session
is comprised of a single service. This required merging certain concepts
(primarily the heartbeat_timeout and last_seen attribute) from sessions
into services. The result is that instead of heartbeating a Session, you now
heartbeat a Service directly. This significantly reduces the amount a code
a user is required to write to register a services in the registry.

Best way to illustrate this change and its ramifications is to look at some
code.

Before:

<script src="https://gist.github.com/Kami/5209441.js"></script>

After:

<script src="https://gist.github.com/Kami/5209442.js"></script>

In both examples we register one service. As you can see, in the second example
where session and service model has been merged, we can get rid of 1 level of
nesting and couple of lines of code. In almost all cases less lines of code is
better because among other things it means code is easier to read and maintain.

We know that backward incompatible changes are usually very painful for the
user so we do our best to avoid them. This time though we believe that this
change was more than justified, because in the end it brings more value to the
user and makes the API more user-friendly.
On a related note, service is currently still in preview phase. One of the
goals of this phase is to collect as much feedback from the preview users as
possible and then use that data to improve the service before committing to a
stable API in the Early Access / General Availability phase.

This change being backward incompatible means you also need to update your
existing code if you want it to work with those new changes. We have already
updated all of our official client libraries so if you use one of those make
sure to upgrade to the latest version (0.2.x for Node.js and Python client
libraries and 2.0.x for Java client library).

For more information, please see the [release notes page](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/release-notes.html#release-notes-v20-march-2013).

### External bindings and API integration

We’ve been evaluating other APIs, projects and services with the goal of
integrating them with Rackspace Service Registry. We will highlight the first
of these integrations in an upcoming blog post. In the meantime you can have
a look at our [repository](https://github.com/racker/java-service-registry-client/tree/master/service-registry-curator)
which contains a couple of [examples](https://github.com/racker/java-service-registry-client/tree/master/service-registry-examples/src/main/java/com/rackspacecloud/client/service_registry/examples).

### Client library and command line client improvements

Our Node.js, Python and Java client libraries have received a lot of
improvements. A few of them are listed below.

#### Events feed poller in the node.js client library

Node.js client library now exposes a higher level interface for working with
the events feed called [EventsFeedPoller](https://github.com/racker/node-service-registry-client/blob/master/lib/events_feed_poller.js).
In the background this class implements the [EventEmitter](http://nodejs.org/api/events.html#events_events)
interface and takes care of periodically polling the events feed and emitting
an event when a new item has been detected in the event feed.

If you are not familiar with the EventEmitter concept in Node.js you can read
more about it [here](http://www.mshiltonj.com/blog/2011/10/04/nodejs-eventemitter-example-with-custom-events/).

Here is a short example which demonstrates its usage:

<script src="https://gist.github.com/Kami/5230779.js"></script>

In this example we listen for all of the available events and simply print
the event payload to the standard output.

#### Improvements in the Java client

The Java client received a lot of improvements and new features ranging from
the [EventsClient](https://github.com/racker/java-service-registry-client/blob/master/service-registry-client/src/main/java/com/rackspacecloud/client/service_registry/clients/EventsClient.java)
for working with the Service registry events feed to better notification of
HeartBeater state changes using [standard Java events](https://github.com/racker/java-service-registry-client/blob/master/service-registry-client/src/main/java/com/rackspacecloud/client/service_registry/HeartBeater.java#L106).

#### Command line client now supports storing credentials in the .raxrc configuration file

The [Command Line Client](https://github.com/racker/python-service-registry-cli)
now supports storing service credentials in the **~/.raxrc** file. This means you
don’t need to pass `--username` and `--api-key` argument to every command anymore.
You simply [store this information in the ~/.raxrc file](https://github.com/racker/python-service-registry-cli#settings-credentials).

In fact, the Cloud Monitoring command line tool uses the same configuration
file format.  This means you can use a single configuration file if you already
use Cloud Monitoring and want to use the same credentials with Rackspace
Service registry.

### Conclusion

During the past couple months we have listened to our customers. We have used
their feedback and other metrics to improve our service in many different ways.
One of the changes was backward incompatible, but overall we believe it’s a
step in the right direction because it reflects a common use case better and
makes the whole API easier to use.

In future blog posts we will go more in depth and show how we are developing
bindings so that you can use the Rackspace Service registry with APIs you may
already be familiar with.

Note: Service registry is currently in closed preview available free of charge.
If you don’t have access yet you can request it by filling out
[this survey](https://surveys.rackspace.com/Survey.aspx?s=f3d6e51580ab4510a564487fafdafdfd).

_This is a guest post from Tomaz Muraus. Tomaz is a Racker and a project
lead for the [Rackspace Service registry](http://www.rackspace.com/blog/keep-track-of-your-services-and-applications-with-the-new-rackspace-service-registry/) product. He is also a project chair
of [Apache Libcloud](http://libcloud.apache.org/), an open-source project
which deals with cloud interoperability. Before working on Service Registry
he worked on the [Cloud Monitoring](http://www.rackspace.com/cloud/monitoring/)
product and before joining Rackspace, he worked at
[Cloudkick](https://www.cloudkick.com/) helping customers manage and monitor
their infrastructure. In his free time, he loves writing code, contributing
to open-source projects, advocating for software freedom, going to the gym
and cycling. Be sure to check out his GitHub [page](https://github.com/Kami)._
