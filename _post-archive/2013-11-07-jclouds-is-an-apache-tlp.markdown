---
layout: post
title: jclouds is an Apache Top Level Project
date: '2013-11-07 11:35'
comments: true
author: Everett Toews
published: true
categories:
  - jclouds
  - java
  - sdk
  - developers
---
{% img right 2013-11-07-jclouds-is-an-apache-tlp/jclouds.jpg 200 %}

The lower case j's have been dotted and the t's have been crossed. jclouds is an Apache Software Foundation (ASF) Top Level Project (TLP)! With the closing of [this issue](https://issues.apache.org/jira/browse/INFRA-6912) and the resolution being set to "Fixed", it's officially and infrastructurally done. We've even dropped the "incubator" prefix/suffix from our DNS entries and various source code artifacts. You can now find us at our permanent home [jclouds.apache.org](http://jclouds.apache.org/). Huzzah!

<!-- more -->

It's been a relatively short ride through the ASF incubation process, just over 6 months. Adrian Cole founded jclouds over 4 years ago and had already built a thriving community before proposing the move to an open source foundation. That community, on the strength of its diversity, had already met many of the requirements to become a TLP. We had some excellent mentors but it was David Nalley that really helped guide our fledging project through the incubation process.

On the technical side, it was mainly a matter of moving all of the jclouds source code into the ASF canonical repos, updating many a license header, and getting some releases as an incubating project under our belt. The work was completed by many in the community but we leaned heavily on our trifecta of Andrews for the releases. To that end, Andrew Bayer will represent jclouds as our vice president in the ASF. I'm proud to be one of the project management committee (PMC) members and a committer.

## The Mission

It's a good time to review the jclouds mission statement.

> Apache jclouds® is an open source library that helps you get started in the cloud and utilizes your Java or Clojure development skills. The jclouds API gives you the freedom to use portable abstractions or cloud-specific features.

Adrian set out to create an open source project and succeeded admirably in that. Getting started in the cloud can be a tough nut to crack but jclouds allows you get going with a minimum of fuss. Of course jclouds is written in Java but it also has a Clojure API and works well with most any JVM based language like Scala or Groovy.

jclouds truly does give you freedom in the cloud. But being a multi-cloud toolkit is not easy. It means we need to abstract out the features common to many clouds into classes that can be used as an API that is portable across those clouds. These portable abstractions allow you to readily write code that can interact with diverse clouds. This is a key feature of jclouds and is a crucial aspect for certain use cases.

jclouds also recognizes that not everyone will need such portable abstractions. Many use cases require coding to cloud-specific features. jclouds does not prevent you from doing so and, in fact, makes it easy.

## OpenStack

Speaking of cloud-specific features, another open source project that is near and dear to my heart is [OpenStack](http://www.openstack.org/) (my first open source love). You can use jclouds to work with many of its key features. This allows you to move your code between any OpenStack provider.

We take an OpenStack first approach in our development when it comes to supporting a new feature in jclouds. When an OpenStack provider releases a new feature for general availability, it's the OpenStack API that we code to. For example, when Rackspace released Cloud Databases, we coded to OpenStack Trove (the code name for OpenStack Databases) first and Cloud Databases second.

Right now jclouds supports the following OpenStack APIs:

*   Nova (Compute)
*   Swift (Object Storage)
*   Keystone (Identity)
*   Cinder (Block Storage)
*   Trove (Databases)

In the near future we'll also support:

*   Marconi (Queues) - This is what I'm currently working on. The code is baking [here](https://github.com/jclouds/jclouds-labs-openstack/tree/master/openstack-marconi).
*   Neutron (Networking) - Kris Sterkx and Nick Livens from Alcatel-Lucent. The code is baking [here](https://github.com/jclouds/jclouds-labs-openstack/tree/master/openstack-neutron).

After that we'll support:

*   Heat (Orchestration)
*   Glance (Images)

To get started with jclouds and OpenStack see the [Quick Start guide](http://jclouds.apache.org/guides/openstack/).

## Conclusion

If you don't have an OpenStack cloud handy, I invite you to kick the tires on jclouds by using the [Rackspace Developer Trial](https://developer.rackspace.com/devtrial/). Use the [jclouds Getting Started Guide](http://jclouds.apache.org/guides/rackspace/) to get up and running quickly. Let us know what you think! You can reach out to me, Everett Toews, on Twitter [@everett_toews](https://twitter.com/everett_toews), [email the developer support team](mailto:sdk-support@rackspace.com), ping [@Rackspace](https://twitter.com/Rackspace) on Twitter, or even reach out to [help@rackspace.com](mailto:help@rackspace.com).

A heartfelt thanks to all of those involved in getting jclouds to where it is today. Our new home in Apache secures the future of jclouds in perpetuity. The increased visibility in the ASF has already had a positive impact on community contribution and engagement from cloud providers. There is no doubt in my mind this is a sign of things to come. It's a new beginning for jclouds and I for one am excited to be a part of it.
