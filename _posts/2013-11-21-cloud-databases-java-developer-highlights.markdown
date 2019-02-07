---
layout: post
title: 'Cloud Databases: Java developer highlights'
date: '2013-11-21 14:10'
comments: true
author: Zack Shoylev
published: true
categories:
  - java
  - jclouds
---

Imagine a MySQL database you need not install, configure, optimize, or update.
One that you can instantiate on demand or scrap when you don't need it any
more. Sounds great - in a nutshell, that is what you get with Cloud Databases.
While you can access Cloud Databases using a bunch of different languages,
here I will do it by using Java with [jclouds](http://jclouds.apache.org/start/what-is-jclouds/).

<!-- more -->

Start by including Cloud Databases in your existing (or make a new) Java
project. If you are using Maven, you can do so by adding the following dependency:

    <dependency>
        <groupId>org.apache.jclouds.labs</groupId>
        <artifactId>rackspace-clouddatabases-us</artifactId>
        <version>1.6.2-incubating</version>
    </dependency>

Because the Rackspace Cloud Databases API is based on
[OpenStack Trove](https://wiki.openstack.org/wiki/Trove), jclouds uses the
TroveApi to talk to it:

    TroveApi troveApi = ContextBuilder.newBuilder("rackspace-clouddatabases-us")
       .credentials(username, apiKey)
       .buildApi(TroveApi.class);

With the help of the TroveApi, users can access the following:

1. Instance
1. Database
1. User
1. Flavor

For example:

    instanceApi = troveApi.getInstanceApiForZone("DFW");
    databaseApi = troveApi.getDatabaseApiForInstanceInZone("some-instance-id", "DFW");
    userApi = troveApi.getUserApiForInstanceInZone("some-instance-id", "DFW");
    flavorApi = troveApi.getFlavorApiForZone("DFW");

Here DFW specifies the Dallas–Fort Worth zone (or location). The id specifies
the database instance you want to modify. Database instances are virtual
machines that can run databases.

In case you have no database instances running, let's create one. Start by
selecting a flavor:

    int flavorId = flavorApi.list().first().get().getId();

We just picked the first flavor on the list. Flavors are hardware
specifications. Picking the first one would usually (but not necessarily)
give us a somewhat small machine, maybe 1GB RAM or so. It should be
sufficient for now.

To finish creating the instance, provide the flavor id, the volume size
(in GB), and the name:

    instance = instanceApi.create(flavorId, 100, "my-db-instance");

And now to quickly add a database and a user:

    databaseApi.create("my-own-cdb");
    userApi.create("zack", "hard-to-guess-password", "my-own-cdb");

And there you have it! Easy, right? To make it even easier, check out the
more detailed jclouds code [examples](https://github.com/jclouds/jclouds-examples/tree/master/rackspace).

Let's finish by pointing out there are multiple ways you can setup your
application infrastructure with Cloud Databases:

1. Internal: A common use case is to have an application running on a
Rackspace Cloud Server that talks to the database instance. While clustering
is not supported at this time, Rackspace provides flavors that perform quite
well, even with a good amount of load.

2. External: If you have to talk to the database from outside the Rackspace
internal network, you will have to setup a Cloud Load Balancer.
