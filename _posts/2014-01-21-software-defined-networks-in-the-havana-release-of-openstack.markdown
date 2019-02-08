---
layout: post
title: Software-defined networks in the Havana release of OpenStack
date: '2014-01-21 11:00'
comments: true
author: Phil Hopkins
published: true
categories:
  - OpenStack
  - Neutron
---


 Software Defined Networks (SDN) are a key technology in enabling users of
 cloud environments to build a wide variety of virtual environments. The
 OpenStack network project, Neutron, has been growing at a rapid pace to the
 point that the OpenStack user can build virtual machines (VM) into various
 flexible network implementations. This can present a challenge to OpenStack
 administrators who may not have a clear understanding of the technologies
 that OpenStack uses to create these virtual networks. This is the first in a
 series of articles that looks closely how OpenStack Neutron implements
 these virtual networks. Through the course of these articles, we will look in
 detail at how virtual networks are created in Neutron, how data in different
 networks in kept separate, and security features built into the security
 group functionality.

 <!-- more -->

Let us start by considering two simple networks created by two different
OpenStack tenants. The first network as seen in the illustration below is a
simple network with a VM connected to a DHCP server. The server gets its IP
from the DHCP server and we can contact the VM from within the network:


{% img center 2014-01-21-software-defined-networks-in-the-havana-release-of-openstack/tenant2.png 433 218 %}

A second network exists for another tenant consisting of 2 VMs, a DHCP
server, a router/gateway to the external world and public (floating) IP
assigned to one of the VMs. This network is shown below:

{% img center 2014-01-21-software-defined-networks-in-the-havana-release-of-openstack/tenant1.png 431 130 %}

These virtual networks are created on physical hardware that has no
resemblance to the virtual networks. For this discussion a very simple
OpenStack environment has been created consisting of one controller node,
one network node and one compute node as shown below:

{% img center 2014-01-21-software-defined-networks-in-the-havana-release-of-openstack/openstacknetwork2tent.png 662 456 %}

Creation of the networks for the each of tenants named test and test1,
occur within the compute and network nodes. More specifically this series
of articles will examine how the Open vSwitch (OVS) processes on each node
enable the creation of separate networks and isolate them. Additionally use
of iptables rules on the compute node are used to apply security group rules
on each network, enabling traffic filtering into and out of each VM.

Continuing, this series looks at how several Linux technologies are used
to the filter traffic in and out of the VMs.  We look at how a path
from the VM to the OVS process is created so that iptables can be used to
filter this traffic and specifically why the path changed from the Folsom
release using Nova security group rules to the current technique. Then the
iptables rules that are created to do this filtering will be examined to see
how they perform this function.

Subsequent articles review the OVS process in detail to see how the
traffic enters the OVS process and exactly how the packets are manipulated
to keep each network separate. This example uses GRE tunnels to separate
the network traffic going between the network and compute nodes, however
alternate technologies such as VLANS or VXLANs could be used. Once the
concepts of traffic separation using GRE tunnels is understood the reader
should easily be able to make the transition to either or these alternate
techniques.

The traffic then moves to the network node, where we look at the use of
OVS to direct each network's traffic to the proper DHCP server or gateway.
We will see how network namespaces are used to isolate each endpoint as well
as use of Linux routing and NAT rules inside of a namespace to allocate an
external public IP to one of the VMs so that it can be reached from the
internet. Namespaces have been added to the Linux kernel in the last few
years and add a very powerful tool that OpenStack is able to leverage. Each
network namespace created has its own separate, isolated network stack which
facilitates creating networks for different tenants that are able to use the
same IP addresses. Without namespaces the OpenStack administrator would have
to allocate distinct separate IP address ranges for each tenants networks as
was the case is early implementations of OpenStack.

This series will help OpenStack users and administrators in understanding
how the various pieces fit together to make Neutron work. From there the
administrator will have the basic tools to solve the network problems that
arise from time to time.
