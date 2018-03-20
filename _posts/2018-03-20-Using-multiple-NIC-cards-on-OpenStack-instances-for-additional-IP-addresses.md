---
layout: post
title: "Using multiple NIC cards on OpenStack instances for additional IP addresses"
date: 2018-03-20 00:00
comments: false
author: Phil Hopkins
published: true
authorIsRacker: true
categories:
    - Openstack
---

In my [previous series of articles](https://blog.rackspace.com/a-users-look-at-openstack-networking-part-5)
on OpenStack networking, I mentioned that there are ways of doing things in the
virtual world that can’t be done in the physical world. Because of that, we
shouldn’t let the physical server limitations control our thinking in the
virtual world -- but often we do.

<!-- more -->

### Introduction

When a physical server needs multiple public Internet Protocol (IP) addresses,
we add these IPs onto one network interface controller (NIC) card because a
limited number of NIC card slots are available in a chassis. These limitations
do not exist in the virtual world, where you can add a virtual NIC card for each
additional IP needed. The limitation for virtual servers isn’t physical slots --
instead, it’s the number of available PCI bus addresses. This limitation occurs
when a web server supports multiple domains, some of which have separate public
IPs.

Each public IP is a floating IP address on the public cloud network. This
floating IP must be mapped to an IP on the server so that traffic to the
floating IP is directed to the server. The difference in the cloud is that
the new IP can reside on a new NIC card as opposed to being added to an existing
NIC card.

### Routing problem

But this presents a newfound problem. Running separate NIC cards on the same
subnet has been not recommended in the past, principally due to a lack of
understanding of policy-based routing that was built into the kernel network
stack over the last few years. Many people don’t know that by using policy-based
routing, it is quite simple to configure multiple NIC cards on the same subnet.

The problem occurs in the following scenario:

- A packet comes in on one interface (for example, interface A)
- The outgoing response packet gets routed out by another interface, which is
connected to the same subnet (for example, interface B).
- The first routing table entry for the subnet is not for the interface on which
the packet first arrived (in this case, interface A).

As a result, the outgoing reply packet has an Ethernet-frame MAC address of the
interface from which the packet exits (interface B), which causes a problem.
The issue is that OpenStack port security causes this outgoing packet to be
dropped as it comes out of the instance. OpenStack does not have a port using an
IP/MAC address combination, and OpenStack does not allow a port to change either
its MAC address or its IP address.

### Solution: Policy-based routing

Policy-based routing provides additional options to decide how a packet may be
routed. Decisions can be based on a number of parameters. The typical router
makes routing decisions based on the IP destination address. In some cases, you
may need to route packets to interfaces based on different criteria, depending
not only on the destination addresses but also on other packet fields such as
source address, IP protocol, transport protocol ports, or even packet payload.
The kernel’s implementation of this type of routing is called *Policy Routing*.

In this application, we want to route packets based on the packet `source address`
to ensure that the packets go out of the interface (or NIC card) that uses the
packet’s `from` IP address. If we don't do this, the system uses the interface
with the first entry in the routing main table. This first entry may or may not
be the interface on which the packet came in, which could cause the IP/MAC
address relationship to be incorrect.

By default, Linux uses a minimum of three separate routing tables, named main,
default, and local (main id=254, default id=253, and local id=255). For packets
going to external addresses, the kernel looks in the main routing table (id=254)
and finds the first routing match to the desired subnet, and it uses only that
first entry. As a result, all packets from the NIC card use that same routing
entry from the main table (id=254). Since the Ethernet frame information is
added by the *outgoing* interface, the MAC address of the packet is from the
outgoing interface (rather than the incoming interface) and communication fails.
This can be fixed only by using policy-based routing. To do this, we need to
create separate tables for each NIC card on the subnet. These tables include a
route and a rule for each IP or NIC card, which cause packets to be routed out
of the correct interface.

### Policy-based routing example

Let’s consider how to configure a system to use policy-based routing by doing
the following tasks:

- Create routing tables populated with routes and rules for each NIC card.
- Add a route in the main table for each NIC card.

In this case, let's setup each interface to use static addresses rather than
OpenStack’s DHCP-based addressing system.

For recent Debian-based systems, the directory `/etc/network/interfaces.d` has
a file for each interface, so we just need to set the static IP and to add
four lines to the interface configuration file for policy-based routing. After
setting the static IP and network information in the file, add the following
details. Don't forget to change the sections between angle brackets( `<` and
`>` ) to contain the appropriate information for the interface:

    post-up ip route add <subnet CIDR> dev <interface name> src <assigned IP address> table <table name or number>
    post-up ip route add default via <subnet gateway> dev <interface name> table <table name or number>
    post-up ip rule add from <assigned IP address> table <table name or number>
    post-up ip route add <subnet CIDR> dev <interface name> src <assigned IP address>

Let’s illustrate with the following example. A new interface is to be set up on
the `10.20.0.0/24` network using this information:

    device name - ens4
    device IP - 10.20.0.4
    subnet CIDR - 10.20.0.0/24
    subnet gateway - 10.20.0.1
    file name: /etc/network/interface.d/ens4.cfg

After we fill in the information, `/etc/network/interface.d/ens4.cfg` contains:

    auto ens4
    iface ens4 inet static
    address 10.20.0.4
    network 10.20.0.0
    netmask 255.255.255.0
    broadcast 10.20.0.255
    post-up ip route add 10.20.0.0/24 dev ens4 src 10.20.0.4 table 4
    post-up ip route add default via 10.20.0.1 dev ens4 table 4
    post-up ip rule add from 10.20.0.4 table 4
    post-up ip route add 10.20.0.0/24 dev ens4 src 10.20.0.4

### Naming or numbering routing tables

Routing tables can be identified by either a number or a name. Here we used
numbers, but to name them, use a unique table name followed by a unique number
in the `/etc/iproute2/rt_tables` file. To avoid editing the file, use numbers
for each table reference. It might be helpful to use the subnet part of the IP
address of the NIC card as the table number or for NIC cards. If you have
interfaces on different subnets, then add part of the base address to the table
number to ensure that the table number is unique. The Linux kernel can handle up
to 2**31 (2147483648) tables.

### Conclusion

As you can see, it is quite easy to configure policy-based routing for these
types of applications. Using separate NIC cards for each additional IP is a
virtual-world alternative to assigning multiple IPs to a single NIC card.

Rackspace is the world’s leading OpenStack service provider. To learn more about
OpenStack, attend a public training session or schedule a private training class
with our experts. For a complete schedule of class offerings, please visit the
Rackspace Training page.
