---
layout: post
title: 'From the OpenStack Summit: Day 3'
date: '2013-04-18 10:52'
comments: true
author: Hart Hoover
published: true
categories:
  - OpenStack
---
Day three was great, just like day one and day two before! I'd like to continue this series of posts by highlighting two sessions from the OpenStack Summit in Portland:

##Havana Image Interchange

There was a few sessions on image management in OpenStack today, and this one in particular brought up the question that when and where should image transformation take place to ensure there is true image portability.  This spawned pretty good discussion, as some of the points that were brought up were:

1. Should Glance be a separate project?  It might be better served as a subcomponent of Nova.
2. Should Glance continue to support multiple image formats, or should there be a common format, a la, AMI like Amazon.
3. Glance's HTTP delivery of images takes a long time and adds to boot time.  What is a better alternative?

One of the largest parts of the session was on number two.  The argument was a developer that wants to build and image and bake an app that will run directly on top of it wants to do it once.  They do not, and should not, have to redo this process for every image type.  Qcow2 was the image type that was getting a lot of community traction in the room as it's vendor neutral and supports parsing.<!-- more -->  

Another point that was brought up was the face that maybe image conversion should happen on the client side, and OpenStack shouldn't have to do any of that heavy lifting.  If that's the case, there would need to be a tool that users can easier convert images.  This isn't a terrible idea, as there is already plenty of tools that provide that functionality, and the community could rally around one and make the 'default' tool for image conversion.

Overall I felt it was a production session, and it sounds like there is some synergy towards moving to a Qcow favored model over raw.  Both are easily usable today in OpenStack clouds, but for taking image compatibility the next level there is some tough decisions that are going to have to be made.

Few other topics considered was VM performance hits on different hypervisors and compressed vs uncompressed images.  For additional information on this topic here is the official link to the [etherpad](https://etherpad.openstack.org/havana-image-interchange).

##Provisioning Bare Metal with OpenStack

Another hot topic this week has been bare metal provisioning. Companies are starting to realize that it's pretty awesome to be able to orchestrate infrastructure with an API, and want to do the same thing with bare metal servers. Inside OpenStack with the Nova bare metal driver, you treat your bare metal server like a virtual machine. An image is streamed from Glance and installed on a server via PXE and IPMI calls. The `nova-compute` service lives on a separate node and manages the bare metal servers. There are still some things that need to be worked out, namely: 

1. Making the nova-compute management node highly available.
2. Including vendor-specific interfaces like DRAC and iLO
3. No migrations or snapshots are supported currently.

To implement bare metal provisioning you have to add some settings to your nova configuration:

```
[baremetal]
compute_driver=nova.virt.baremetal.driver.BareMetalDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
scheduler_host_manager=nova.scheduler.baremetal_host_manager.BaremetalHostManager
ram_allocation_ratio=1.0
reserved_host_memory_mb=0
```

The above adds a special driver for bare metal provisioning and tells the scheduler how to manage capacity when dealing with bare metal servers. More information on bare metal provisioning with OpenStack and Nova can be found [here](https://docs.openstack.org/trunk/openstack-compute/admin/content/baremetal.html) or you can [follow the etherpads](https://etherpad.openstack.org/HavanaTripleO) [from the design sessions](https://etherpad.openstack.org/HavanaBaremetalNextSteps).
