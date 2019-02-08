---
layout: post
title: Beginning to understand Neutron provider and tenant networks in OpenStack
date: '2014-02-03 09:23'
comments: true
author: James Thorne
published: true
categories:
  - OpenStack
  - Neutron
---

OpenStack is composed of many different projects. The core projects
provide compute, storage, and network resources. The Neutron project
provides network resources to the OpenStack environment and can be
difficult to get started with. To help get the gears turning, I will
be discussing some of the functionality Neutron Networking is capable of.

<!-- more -->

I would wager that most of us are familiar with virtualized networking through
experience running VMware vSphere. Each node in the VMware vSphere Cluster
will have physical NICs connected to physical switch ports on a managed switch.
Those physical switch ports on the managed switch are configured as a trunk
containing all of the particular VLANs you need accessible from your VMware
vSphere Cluster. Within the VMware vSphere Client, virtual networks are
created mapping to the different VLANs in the trunk. As VMware virtual
machines are provisioned, one or more of those virtual networks can be
attached to the virtual machine. The virtual network interfaces within the
virtual machines can then be assigned IP addresses associated with the subnet
on that particular VLAN and the virtual machines can begin communicating.

OpenStack Neutron Networking has the same capabilities. The controller and
compute nodes will have physical NICs connected to physical switch ports on a
managed switch. Those physical switch ports on the managed switch are
configured as a trunk containing all of the particular VLANs you need
accessible from your OpenStack environment. Then from the command line on
one of the OpenStack nodes, Neutron Provider Networks (Neutron Provider
Networks always map to a physical network with a gateway that exists on
a router or firewall) are created mapping to the different VLANs in the trunk.
As OpenStack instances are provisioned, one or more of those Neutron Provider
Networks can be attached to the instance. The virtual network interfaces within
the instances will then be assigned IP addresses associated with the subnet on
that particular VLAN and the instances can begin communicating.

Both of these scenarios are very similar to each other, so what else does
Neutron Networking bring to the table? Neutron Tenant Networks.

First, what is a Tenant (also known as a Project)? OpenStack has been designed
to be a multi-tenant environment. User X and User Y can co-exist within the
same OpenStack environment and share compute, storage, and network resources
or they can have dedicated compute, storage, and network resources within the
same OpenStack environment.

User X can create Neutron Tenant Networks that are completely isolated from
any Neutron Tenant Networks created by User Y, even if User X and Y are sharing
resources. User X and Y can do this without help from a Systems Administrator
(assuming they have the proper permissions). This functionality is possible
through the use of Network Namespaces, a feature implemented in the Linux
kernel. You can think of Network Namespaces as a chroot jail for the
networking stack.

When User X and User Y create Neutron Tenant Networks, a Network Namespace is
created for each. When User X and Y create OpenStack instances and attach
those instances to their respective Neutron Tenant Network, only those instances
within the same Network Namespace can communicate with each other, even if the
instances are spread across OpenStack compute nodes. This is very similar to
having two physical Layer 2 networks that have no way of communicating with
each other until a router is put between them. And this is exactly how
different Neutron Tenant Networks can communicate with each other, by
putting a Neutron Router between them.

With a Neutron Router between the two Neutron Tenant Networks, the instances
in each Neutron Tenant Network can now communicate with each other.

Now, what if those instances need to route out to the internet? One of the
Neutron Provider Networks you created above, or possibly a different one,
could be attached to the Neutron Router and act as the Neutron Router's
default gateway out to the internet. The Neutron Tenant Networks could then
be attached to the Neutron Router and those Neutron Tenant Networks could
then route out to the internet.

There is a lot more to Neutron Networking, and this has simply been a
high-level overview to get you thinking.

If you would like to dive deeper and see how to configure various aspects of
Neutron Networking, I encourage you to read the following posts by fellow
Racker James Denton:

[Neutron Networking: The Building Blocks of an OpenStack Cloud](http://developer.rackspace.com/blog/neutron-networking-the-building-blocks-of-an-openstack-cloud.html)

[Neutron Networking: Simple Flat Network](http://developer.rackspace.com/blog/neutron-networking-simple-flat-network.html)

[Neutron Networking: VLAN Provider Networks](http://developer.rackspace.com/blog/neutron-networking-vlan-provider-networks.html)

[Neutron Networking: Neutron Routers and the L3 Agent](http://developer.rackspace.com/blog/neutron-networking-l3-agent.html)

For questions and/or comments, feel free to get in touch with me [@jameswthorne](http://twitter.com/jameswthorne).

