---
layout: post
title: 'How we run Ironic, and you can too!'
date: '2014-06-19 12:00'
comments: true
author: Jim Rollenhagen
published: true
categories:
  - openstack
---

As you may already know, Rackspace just launched [OnMetal](https://www.rackspace.com/cloud/servers/onmetal/), which is built with OpenStack [Ironic](https://github.com/openstack/ironic) and [ironic-python-agent (IPA)](https://github.com/openstack/ironic-python-agent). I want to highlight the code, what our control plane looks like, and how we operate it. My hope is that this post can help others test and deploy Ironic with IPA.

<!-- more -->

Code
====

We make a best effort to run the latest Ironic code available, with the addition of some patches that are currently in flight. We do this in a [similar fashion](https://www.youtube.com/watch?v=0D7PbIZLNSM) to Rackspace's [Nova team](https://www.slideshare.net/JesseKeating/scaling-openstack). The gist of it is:

1. fork from master
2. apply necessary patches
3. test
4. fix any bugs
5. deploy!
6. GOTO 1

We currently have some patches in flight to make Ironic's master branch work well with ironic-python-agent (and for us as operators). These patches are:

* [Adding swift temp url support](https://review.openstack.org/#/c/81391/)
* [Drivers determine acceptable power states](https://review.openstack.org/#/c/86744/)
* [Adding a reference driver for the agent](https://review.openstack.org/#/c/84795/)
* [Virt driver logging improvements](https://review.openstack.org/#/c/97047/)
* [Allow overriding the log level for ironicclient](https://review.openstack.org/#/c/97048/)

This code has been running very well for us; props to the Ironic cores for keeping the codebase stable in such a new project.

We also have [one patch in flight](https://review.openstack.org/#/c/99666/) for the agent that we use, as well as a [custom HardwareManager extension](https://github.com/rackerlabs/onmetal-ironic-hardware-manager) for secure erasing the flash cards on our I/O flavor.

Last, we run a [custom Neutron extension](https://github.com/rackerlabs/ironic-neutron-plugin) that allows us to control physical switches. Each of our bare-metal nodes has two 10G NICs that are set up trunked and bonded. We use Neutron to control the switches to restrict switch ports to certain VLANs, and thus restrict the servers to those VLANs.

Control plane
=============

Our control plane is also fairly straightforward (for some definition of straightforward). We run Ironic as its own cell; this allows us to deploy without affecting the rest of our public cloud.

The compute/Ironic side of the control plane [looks like this.](https://8c9281d7b726ce93a4bd-63b3a98a421b1a8eb26177fc7852e719.ssl.cf5.rackcdn.com/teeth-architecture.png)

Everything runs in an HA fashion. We have at least two nodes for each service, as well as load balancers in front of API servers.

What this diagram does not show is our network partitions. We have three VLANs that we use:

* PublicNet: this is attached to the public internet.
* ServiceNet: this is Rackspace's internal 10. network. This is used for support and traffic internal to a datacenter. Bonus: bandwidth over ServiceNet is free.
* "provisioning network": this is the network that Ironic agents live on for provisioning and decommissioning. This is firewalled from all other networks, with the exception of a route to the necessary bits on the control plane (ironic-conductor and swift).
* BMCs for out-of-band power control are on a separate physical network that is fully isolated.

We have two separate DHCP services. The first has a static configuration for our BMCs. The second has configurations for agents on the provisioning VLAN, runs a tftp server to serve an iPXE image, and runs an http server to serve an iPXE config and the agent image itself. Both use isc-dhcp-server for serving DHCP. We use an external DHCP service, rather than Neutron's DHCP service, because Neutron uses dnsmasq to serve DHCP, and we do not believe that dnsmasq can scale as large as we need it to.

Operations
==========

In general, we've been using the default configuration for Ironic, and find them to be sane. Here are the non-default configs that we are using in production (with the exception of configs that must be set, like rabbit settings), and why:

    [DEFAULT]
    enabled_drivers=agent_pyghmi,agent_ipmitool  # we're using the agent
    debug=true  # we believe in logging all the things
    rpc_thread_pool_size=4  # we've found this to work best with high load conductors
    rpc_conn_pool_size=20  # we've found this to work best with high load conductors

    [conductor]
    force_power_state_during_sync=false  # we don't want any surprises :)

    [glance]  # these settings are required for using swift temp URLs
    swift_temp_url_key=<lol>
    swift_scheme=https
    swift_endpoint_url=<swift-host>
    swift_path=/v1/<rackspace_tenant>
    swift_backend_container=<rackspace_container>

    [agent]
    dhcp_provider=external
    heartbeat_timeout=30  # relied on for deploys, shorter timeout means shorter deploys. We'll be fixing this in code soon.
    provisioning_network_uuid=<network_id>
    
Want to build this with us? Have more questions?
================================================

Jump in #openstack-ironic on Freenode and poke us. The OnMetal developers working upstream on Ironic are:

* russell_h
* comstud
* JayF
* jroll
* JoshNang
* morgabra
* aweeks
* ellenh


OnMetal and Ironic represent a huge shift in cloud computing, and we're super excited about it. We can't wait to see what you'll build on it!
