---
comments: true
date: 2012-09-26T08:00:43.000Z
layout: post
title: 'OpenStack Folsom: Looking at the numbers'
author: Hart Hoover
categories:
  - OpenStack
---

[Bitergia](https://bitergia.com) has an excellent [post](https://bitergia.wordpress.com/2012/09/22/preview-of-the-analysis-of-the-upcoming-openstack-release/) on statistics for Folsom, the upcoming release for OpenStack.

<!-- more -->

The OpenStack [Summit](https://www.openstack.org/summit/san-diego-2012/) is only a few weeks away, and development has been accelerating toward release. Here is a comparison of a graph for Folsom from Bitergia to an Essex graph from [ReadWriteWeb](https://www.readwriteweb.com/cloud/2012/04/who-wrote-openstack-essex-a-de.php):

{% img center 2012-09-26-openstack-folsom-looking-at-the-numbers/essex.png %}
{% img center 2012-09-26-openstack-folsom-looking-at-the-numbers/stat1.png %}

While Rackspace still leads in committing code to OpenStack, Red Hat is surging as it looks to [productize](https://www.redhat.com/about/news/archive/2012/9/the-process-to-make-openstack-a-product) the OpenStack project. HP and Piston Cloud have standardized on earlier versions of OpenStack for their cloud offerings.


### Most Exciting New Features in Folsom


Two of the most noteworthy new features in the Folsom release are [Quantum](https://wiki.openstack.org/Quantum) and [Cinder](https://wiki.openstack.org/Cinder). Quantum is now a core project and provides "networking as a service" between interfaces for other OpenStack services. Quantum lets you use a set of different backends called "plugins" that work with a growing variety of networking technologies depending on your stack:



	
  * [Big Switch Networks](https://www.bigswitch.com) Plugin

	
  * [Cisco UCS/Nexus](https://wiki.openstack.org/cisco-quantum) Plugin

	
  * [Floodlight OpenFlow Controller](https://floodlight.openflowhub.org/quantum-and-openstack/) Plugin

	
  * [Linux Bridge](https://wiki.openstack.org/Quantum-Linux-Bridge-Plugin) Plugin

	
  * [MidoNet](https://github.com/midokura/midonet-openstack) Plugin

	
  * [NEC OpenFlow](https://github.com/nec-openstack/quantum-openflow-plugin) Plugin

	
  * [Nicira Network Virtualization Platform (NVP)](https://www.nicira.com) Plugin

	
  * [Open vSwitch](https://www.openvswitch.org) Plugin

	
  * [Ryu OpenFlow Controller](https://www.osrg.net/ryu/using_with_openstack.html) Plugin


Rackspace is partnering with Nicira (now VMware) on our upcoming Cloud Networks product based on Quantum. Cinder provides block storage capabilities, abstracting code that was previously part of Nova (nova-volume). Another major update in Folsom is the return of Hyper-V as a supported hypervisor in OpenStack Nova.


### Coming up: The OpenStack Summit


It's an exciting time to [be a part](https://wiki.openstack.org/HowToContribute) of the OpenStack community! Wayne and I will be posting from the Summit in a few weeks and you can expect complete coverage here and on the [Rackspace Blog](https://www.rackspace.com/blog/). <del>You can find a preliminary schedule for sessions posted on [Google Docs](https://docs.google.com/spreadsheet/ccc?key=0AmUn0hzC1InKdEtNWVpRckt4R0Z0Q0Z3SUc1cUtDQXc#gid=0).</del> UPDATE: The schedule for the OpenStack Summit is live [here](https://openstacksummitfall2012.sched.org/).
