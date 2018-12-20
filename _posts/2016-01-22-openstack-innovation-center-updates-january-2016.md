---
layout: post
title: "OpenStack Innovation Center (OSIC) Updates - January 2016"
date: 2016-01-22 12:00
comments: true
author: Walter Bentley
published: true
categories:
  - Private Cloud
  - OpenStack
  - Architecture
---

Since the initial launch of the OpenStack Innovation Center back in July of 2015, much work has been done.  Wanted to take a moment to share the current status and some details about its next phases.  If you are unfamiliar with OSIC, let me start off with some very quick background information.

<!-- more -->

The OpenStack Innovation Center, abbreviated to ‘OSIC’, is a joint partnership between Rackspace and Intel implemented to further accelerate the development of enterprise capabilities into upstream OpenStack code.  It is intended to bring together Rackspace and Intel engineers in order to:

>***“advance the scalability, manageability and reliability of OpenStack by adding new features, functionality and eliminating bugs through upstream code contributions”***

as mentioned in the [Rackspace press release](https://blog.rackspace.com/newsarticles/rackspace-collaborates-with-intel-to-accelerate-openstack-enterprise-feature-development-and-adoption/).

It is also intended to offer an OpenStack cloud (at an enterprise scale) to the greater OpenStack community in order to develop/test new OpenStack functionality.  The OSIC hub can be found within Rackspace’s corporate headquarters in San Antonio, TX nicknamed “Castle”. Personally, I thought the OSIC launch was a very exciting one.  This was mainly because it was aimed at solving some of OpenStack’s greatest challenges thus far, which are enterprise focused features and the basic idea that OpenStack was not enterprise ready.  Those two 1,000 node OpenStack clusters sort of dispel that second wrong idea in so many ways.  OpenStack runs in my blood, and I am very proud to be part of the community.

OK, enough of my banter - let's get down to business with some updates!

**Innovation Center**

Yes, you can actually see, touch, and sit in it now.  The Innovation Center, located at Rackspace’s Castle, launched on September 10th of 2015.  Imagine reserving a whole wing of what used to be a old shopping mall just to seat a bunch of OpenStack developers, engineers, support, and architecture staff.  This location allows Rackspace and Intel engineers to collaborate on all things OpenStack.  We openly invite any and all who are interested to come on down to see it with their own eyes.

**Developer Training/Joint OpenStack Engineering**

As of October 2015, Intel has placed ~12 developers into the Innovation Center to take part in the detailed training program created in order to on-board OpenStack focused developers.  From that point forward, roughly 10-15 additional developers will be brought in to work in the Innovation Center on a monthly basis.  The details around the OSIC engineering road map can be found in the following slide from the Tokyo OpenStack Summit:

![OSIC Roadmap](http://www.hitchnyc.com/content/images/2016/01/osic-roadmap-n.png)

**Developer Cloud**

Come on...you know you only read this far to get the scope in this section.  Being honest, you're thinking the the Developer Cloud is pretty darned cool, and I can not blame you.  Just saying “two 1000-node OpenStack clusters” out loud sounds impressive.  As an architect, my first thought was “show me the details!”.  Well, you will be the first to get a look at the details that make up the first of the 1000-node cluster that is hosted at the Rackspace Dallas Fort Worth datacenter.  Could not think of a better combination of being funded by Intel and supported by Rackspace.

Keep in mind the following details encompass only the first 1000-node cluster that is ready for use and hosted at Rackspace.  Unfortunately, I was not able to get any exciting details on the second cluster located at Intel in Oakland, California yet.  Keep posted for more updates to come at a later date.

***OSIC Cluster @ Rackspace***

* Made up of ~1012 bare metal servers that are broken up in particular ways to serve the various requests that come in from the OpenStack community.
* Over 60% of the cluster is running RPC-O (Rackspace Private Cloud - OpenStack)
* The remainder of the cluster is configured for bare metal server environments as requested by the community.
* Each cabinet has two top-of-rack Cisco Nexus 3172-PQ network switches.
* Each cabinet also has one top-of-rack network switch for out-of-band management.

The hardware is broken out into two cloud regions and the details follow:

--------
****Cloud Region 1****

Nodes running RPC-O version 11.0:

* 17 Server cabinets
* 1x Deployment node
* 3x Controller nodes
* 7x Logging nodes
* 132x Compute nodes with spindle drives
* 44x Compute nodes with Intel SSD S3500
* 66x Compute nodes with Intel SSD S3700
* 44x Cinder nodes
* 4x Swift Proxy nodes
* 40x Swift Object Storage nodes

Bare metal nodes:

* 10x Compute nodes with spindle drives

Unused nodes:

* 12x Compute nodes with spindle drives
* 4x Controller nodes
* 5x Network nodes
* 1x Util node
* 1x Jump node

--------
****Cloud Region 2****

Nodes running RPC-O version 11.0:

* 29 Server cabinets
* 1x Deployment node
* 3x Controller nodes
* 7x Logging nodes
* 154x Compute nodes with spindle drives
* 44x Compute nodes with Intel SSD S3500
* 66x Compute nodes with Intel SSD S3700
* 44x Cinder nodes
* 4x Swift Proxy nodes
* 40x Swift Object Storage nodes

Bare metal nodes:

* 242x Compute nodes with spindle drives

Unused nodes:

* 22x Compute nodes with spindle drives
* 4x Controller nodes
* 5x Network nodes
* 1x Util node
* 1x Jump node

--------
**Who’s using the Developer Cloud?**

Currently the Intel Bare Metal CI Team and Mirantis are the only OSIC customers using the cluster as of today.  Both of those teams use the bare metal server option as mentioned above.  The next consumers slated to come on board is the OpenStack Infrastructure team.  We're also moving the OSIC sign-up form from this [link](http://go.rackspace.com/developercloud) to http://www.osic.org, which will sit on the Developer cloud.

We close out this update with two pretty pictures.  I'm rather confident that you wish that this was a screenshot of Horizon from your home labs, just like I do.  We can all dream right?  Please stay tuned for more updates to come and keep Stacking!

{<2>}![Rackspace OSIC Cloud Region 1](http://www.hitchnyc.com/content/images/2016/01/osic-cloud1-n.png)
{<3>}![Rackspace OSIC Cloud Region 2](http://www.hitchnyc.com/content/images/2016/01/osic-cloud2-n.png)

Check out the last 8 minutes of the recorded OSIC session from the Tokyo OpenStack summit back in October 2015 to see the video of the OSIC launch at Castle: [https://www.openstack.org/summit/tokyo-2015/videos/presentation/intel-cloud-for-all-openstack-innovation-center](https://www.openstack.org/summit/tokyo-2015/videos/presentation/intel-cloud-for-all-openstack-innovation-center).
