---
layout: post
title: 'jclouds 1.7.0 released with support for OpenStack Queuing, Networks, and Rackspace Auto Scale'
date: '2014-01-08 10:00'
comments: true
author: Everett Toews
published: true
categories:
  - jclouds
  - java
  - sdk
  - developers
  - openstack
---
{% img right 2013-11-07-jclouds-is-an-apache-tlp/jclouds.jpg 200 %}

Apache jclouds version 1.7.0 has been released into the wild. This is jclouds'
first minor point version release as an Apache top level project. Community
development on the project is continuing to accelerate and there are some major
additions I'd like to highlight.

<br/>

<!-- more -->

### OpenStack

I added support for Queuing (project alias: Marconi). OpenStack Queuing is a
robust, web-scale message queuing service to support the distributed nature of
large web applications. At Rackspace, our implementation of it is known as
[Cloud Queues](http://www.rackspace.com/cloud/queues/).

Kris Sterckx from Alcatel-Lucent added support for Networking (project alias:
Neutron). [OpenStack Networking](http://www.openstack.org/software/openstack-networking/)
is a pluggable and scalable system for managing network resources, such as
networks, subnets, and virtual network interfaces.

### Rackspace

Zack Shoylev from Rackspace added support for
[Auto Scale](http://www.rackspace.com/cloud/auto-scale/). It makes the Rackspace
cloud react automatically to changes in user demand for your application. By
creating a few simple rules that you define and control, you let us know when
and how to grow (or shrink) your web or application tiers.

We also added support for the new Rackspace cloud in Hong Kong! You can use it
by setting the zone to `HKG` in jclouds.

### Get started

Rackspace uses jclouds as our Java SDK for OpenStack and the Rackspace cloud.
Go to the [Java section](http://developer.rackspace.com/#java) of the Developer
Center, where you will find links for everything you need to get started with
jclouds. Be sure to check out the [Getting Started Guide](http://jclouds.apache.org/guides/rackspace/)
and the [Examples](https://github.com/jclouds/jclouds-examples/tree/master/rackspace).

### Conclusion

Let us know what you think! Feel free to reach out to me, Everett Toews, on
Twitter [@everett_toews](https://twitter.com/everett_toews).

I'd also like to invite you to connect with the [jclouds community](http://jclouds.apache.org/community/).
From there you can join our mailing lists or drop by on IRC to say hi. If you're
looking to add new features to jclouds, you might be interested in
[How to Contribute](https://wiki.apache.org/jclouds/How%20to%20Contribute).
