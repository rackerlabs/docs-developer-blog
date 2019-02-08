---
layout: post
title: 'Neutron networking: Neutron routers and the L3 agent'
date: '2014-01-07 15:20'
comments: true
author: James Denton
published: true
categories:
  - OpenStack
  - Neutron
  - Cloud Networks
---

In this multi-part blog series I intend to dive into the various components of the OpenStack Neutron project and provide working examples of networking configurations for clouds built with [Rackspace Private Cloud](http://www.rackspace.com/cloud/private/) powered by [OpenStack](http://www.openstack.org) on Ubuntu 12.04 LTS.

In the previous installment, [Neutron Networking: VLAN Provider Networks](http://developer.rackspace.com/blog/neutron-networking-vlan-provider-networks.html), I provided guidance on configuring networks in Neutron using VLAN tagging. In this fourth installment, I'll describe how to combine flat or VLAN provider networks with GRE-based tenant networks using the L3 agent and Neutron routers.<!-- more -->

### Getting started and prerequisites

Beginning with v4.2, Rackspace Private Cloud is powered by OpenStack Havana. This walkthrough assumes a working installation of at least v4.2.1. In prior releases the L3 agent was not supported, however, many of the concepts covered in this post can be altered to fit a Grizzly-based install using Rackspace Private Cloud or vanilla OpenStack.

In the last two installments I covered the concept of provider networks, or networks that are tied to the physical infrastructure. I highly recommend giving them a read if you haven't already done so, as this walkthough depends on a working provider network configuration.

[Neutron Networking: Simple Flat Network](http://developer.rackspace.com/blog/neutron-networking-simple-flat-network.html)

[Neutron Networking: VLAN Provider Networks](http://developer.rackspace.com/blog/neutron-networking-vlan-provider-networks.html)

### Neutron L3 agent: What is it and how does it work?

Neutron has an API extension to allow administrators and tenants to create "routers" that connect to L2 networks. Known as the "neutron-l3-agent", it uses the Linux IP stack and iptables to perform L3 forwarding and NAT. In order to support multiple routers with potentially overlapping IP addresses, neutron-l3-agent defaults to using Linux [network namespaces](http://www.opencloudblog.com/?p=42) to provide isolated forwarding contexts. Like the DHCP namespaces that exist for every network defined in Neutron, each router will have its own namespace with a name based on its UUID.

### Network design: Implementing Neutron routers

While deploying instances using provider networks is suitable in many cases, there is a limit to the scalability of such environments. Multiple flat networks require corresponding bridge interfaces, and using VLANs may require manual switch and gateway configuration. All routing is handled by an upstream routing device such as a router or firewall, and said device may also be responsible for NAT as well. Any benefits are quickly outweighed by manual control and configuration processes.

Using the neutron-l3-agent allows admins and tenants to create routers that handle routing between directly-connected LAN interfaces (usually tenant networks, GRE or VLAN) and a single WAN interface (usually a FLAT or VLAN provider network). While it is possible to leverage a single bridge for this purpose (as is often the documented solution), the ability to use already-existing provider networks is my preferred solution.

### Neutron L3 agent: Floating IPs

One of the limitations of strictly using provider networks to provide connectivity to instances is that a method to provide public connectivity directly to instances must be handled by a device outside of Neutron's control. In the previous walkthoughs, the Cisco ASA in the environment handled both 1:1 static NAT and a many-to-one PAT for outbound connectivity.

In nova-networking, the concept of a "floating ip" is best understood as a 1:1 NAT translation that could be modified on-the-fly and "float" between instances. The IP address used as the floating IP was an address in the same L2 domain as the bridge of the hypervisors (or something routed to the hypervisor.) Assuming multi_host was true, an iptables SNAT/DNAT rule was created on the hypervisor hosting the instance. If the user wanted to reassociate the floating IP with another instance, the rule was removed and reapplied on the appropriate hypervisor using the same floating IP and the newly-associated instance address. Instance IPs never changed - only NAT rules.

Neutron's implementation of floating IPs differs greatly from nova-networks, but retains many of the same concepts and functionality. Neutron routers are created that serve as the gateway for instances and are scheduled to a node running neutron-l3-agent. Rather than manipulating iptables on the hypervisors themselves, iptables in the router namespace is modified to perform the appropriate NAT translations. The floating IPs themselves are procured from the provider network that is providing the router with its public connectivity. This means floating IPs are limited to the same L3 network as the router's WAN IP address.

A logical representation of this concept can be seen below:

{% img center 2014-01-07-neutron-networking-l3-agent/l3_agent_1.1.png %}

While logically it appears that floating IPs are associated directly with instances, in reality a floating IP is associated with a Neutron port. Other port associations include:

- security groups
- fixed ips
- mac addresses

A port is associated with the instance indicated by the "device_id" field of the "port-show" command:

```
[root@controller01 ~]# neutron port-show 3d9a794e-62ae-4be5-b553-b0ffc3569dd2
+-----------------------+------------------------------------------------------------------------+
| Field                 | Value                                                                  |
+-----------------------+------------------------------------------------------------------------+
| admin_state_up        | True                                                                   |
| allowed_address_pairs |                                                                        |
| binding:capabilities  | {"port_filter": true}                                                  |
| binding:host_id       | compute01.grizzly.openstacksupport.com                                 |
| binding:vif_type      | ovs                                                                    |
| device_id             | 20316c55-4b2a-43a2-aa23-a83fe9972af1                                   |
| device_owner          | compute:nova                                                           |
| extra_dhcp_opts       |                                                                        |
| fixed_ips             | {"subnet_id": "06f2839f-xxx-0884bba52327", "ip_address": "10.241.0.3"} |
| id                    | 3d9a794e-62ae-4be5-b553-b0ffc3569dd2                                   |
| mac_address           | fa:16:3e:67:8d:1e                                                      |
| name                  |                                                                        |
| network_id            | d063d15a-1eb7-4e6c-990a-efdc1515a3fb                                   |
| security_groups       | 3d6d37d8-ea92-4cce-a149-c1c45a227acf                                   |
| status                | ACTIVE                                                                 |
| tenant_id             | 75a79e144bcd45f6b66b2deb884a73a9                                       |
+-----------------------+------------------------------------------------------------------------+
```

### Networking: Layout

For this installment, a Cisco ASA 5510 will once again serve as the lead gateway device. In fact, I’ll be building upon the configuration already in place from the flat and/or VLAN networking demonstration in the previous installments:

- [Simple Flat Network](http://developer.rackspace.com/blog/neutron-networking-simple-flat-network.html)
- [VLAN Provider Networks](http://developer.rackspace.com/blog/neutron-networking-vlan-provider-networks.html)

10.240.0.0/24 will continue to serve as the management network for hosts. A single VLAN network will be created to demonstrate the ability to use either a flat or VLAN network.

- VLAN 10 - MGMT - 10.240.0.0/24
- VLAN 20 – GATEWAY_NET – 192.168.100.0/22

A single interface on the servers will be used for both management and provider network connectivity. Neutron works with Open vSwitch to build peer-to-peer tunnels between hosts that serve to carry encapsulated *tenant* network traffic.

{% img center 2014-01-07-neutron-networking-l3-agent/l3_agent_1.2.png %}


### Networking: L3 agent configuration

Before you can utilize the L3 agent, there are a couple of configuration options that must be added or edited. These include specifying the external bridge and external network in l3_agent.ini. There are some caveats to the L3 agent you should be aware of:

- When "external_network_bridge" is specified, Neutron places the external interface of the router directly into the specified bridge. When the gateway network is set for the router, Neutron assigns an IP from the subnet to the router's WAN interface. However, provider attributes such as "vlan", "segmentation_id", and "provider_network" are ignored. External traffic is untagged and not handled by OVS flows.

- When "external_network_bridge" is unset (ie. ""), Neutron places the external interface of the router into the OVS bridge specified by the "provider_network" provider attribute in the Neutron network. Traffic is processed by Open vSwitch flow rules. In this configuration it is possible to utilize flat and VLAN provider networks.

- When "gateway_external_network_id" is specifed, the L3 agent utilizes that network as the gateway network for routers. Otherwise, the L3 agent expects a single provider network to have been set with "external=true" and will fail to start if more than one is found.

- By default, there is a single 'neutron-l3-agent' process running on the controller/network node. Only one external providernetwork is allowed per agent. However, it is possible to build several Neutron routers using the same external provider network as the gateway network and different tenant networks. Overlapping tenant networks are allowed, but not behind the same router.


#### Changes to environment

Changes to a standard Rackspace Private Cloud deployment are handled by Chef. Using the 'knife' utility, add the following override attribute to the environment file:

'neutron : ovs : external_bridge'

```
"neutron": {
  "ovs": {
    ...
    "external_bridge": ""
```

Run chef-client on the controller/network node to update the configuration. Chef will update /etc/neutron/l3_agent.ini with the following entry:


```
[DEFAULT]
external_network_bridge =
```

Setting the bridge to null results in the router gateway interface being placed in the OVS bridge specified in the provider network.

### Networking: Building a router in Neutron

With the L3 agent properly configured, it's now time to build a router in Neutron. The configuration will mirror that of the diagram below, and assume a tagged VLAN provider network of 192.168.100.0/22 exists:

```
neutron net-create --provider:physical_network=ph-eth0 --provider:network_type=vlan --provider:segmentation_id=1998 --shared --router:external=true GATEWAY_NET

neutron subnet-create GATEWAY_NET 192.168.100.0/22 --name GATEWAY_SUBNET --gateway=192.168.100.1 --allocation-pool start=192.168.101.1,end=192.168.103.254
```

A router can be created with the 'router-create' command:

```
root@controller01:~# neutron router-create NEUTRON-ROUTER

Created a new router:
+-----------------------+--------------------------------------+
| Field                 | Value                                |
+-----------------------+--------------------------------------+
| admin_state_up        | True                                 |
| external_gateway_info |                                      |
| id                    | ba605e63-3c54-402b-9bd7-3eba85d00080 |
| name                  | NEUTRON-ROUTER                       |
| status                | ACTIVE                               |
| tenant_id             | 75a79e144bcd45f6b66b2deb884a73a9     |
+-----------------------+--------------------------------------+
```

With the router created, it’s time to set the external gateway.

Syntax: ```neutron router-gateway-set <router-id> <external-network-id>```

```
root@controller01:~# neutron router-gateway-set NEUTRON-ROUTER GATEWAY_NET
Set gateway for router NEUTRON-ROUTER
```

With the gateway set, it should be possible to ping *at least* the network gateway from the router namespace, and possibly an Internet address if upstream routing and NAT is properly configured:

```
[root@controller01 ~]# ip netns
qrouter-ba605e63-3c54-402b-9bd7-3eba85d00080
qdhcp-9ce7f51f-dac6-453f-80ce-3391769d9990

[root@controller01 ~]# ip netns exec qrouter-ba605e63-3c54-402b-9bd7-3eba85d00080 ip a
136: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
137: qg-8860da83-31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether fa:16:3e:57:0b:47 brd ff:ff:ff:ff:ff:ff
    inet 192.168.101.2/22 brd 192.168.103.255 scope global qg-8860da83-31
    inet6 fe80::f816:3eff:fe57:b47/64 scope link
       valid_lft forever preferred_lft forever

[root@controller01 ~]# ip netns exec qrouter-ba605e63-3c54-402b-9bd7-3eba85d00080 ping 192.168.100.1
PING 192.168.100.1 (192.168.100.1) 56(84) bytes of data.
64 bytes from 192.168.100.1: icmp_seq=1 ttl=255 time=2.22 ms
64 bytes from 192.168.100.1: icmp_seq=2 ttl=255 time=0.485 ms

[root@controller01 ~]# ip netns exec qrouter-ba605e63-3c54-402b-9bd7-3eba85d00080 ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=47 time=13.3 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=47 time=12.6 ms
```

Upstream NAT for the router IP is important, since all traffic from an instance without a floating IP will be SNAT'd by the Neutron router. A dynamic NAT has been configured on the Cisco ASA in this example.

### Networking: Attaching tenant networks

Now that connectivity has been established for the router it's time to attach tenant networks to complete our network. Without a Neutron router, traffic within a GRE-based tenant network is limited to itself. A Neutron router will allow directly-connected tenant networks to communicate amongst each other and external networks (including the Internet), as well as provide the ability to connect to instances directly from an outside network using floating IPs.

Below are two tenant networks I've created. Note that it is no longer necessary to implement the default route workaround as documented in prior releases and walkthroughs, as the Neutron router will serve as the gateway and provide connectivty to the metadata service.

```
[root@controller01 ~]# neutron net-create --provider:network_type=gre --provider:segmentation_id=10 --shared APPS_NET

Created a new network:
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | d063d15a-1eb7-4e6c-990a-efdc1515a3fb |
| name                      | APPS_NET                             |
| provider:network_type     | gre                                  |
| provider:physical_network |                                      |
| provider:segmentation_id  | 10                                   |
| shared                    | True                                 |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | 75a79e144bcd45f6b66b2deb884a73a9     |
+---------------------------+--------------------------------------+

[root@controller01 ~]# neutron net-create --provider:network_type=gre --provider:segmentation_id=20 --shared DMZ_NET

Created a new network:
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | c0a1958a-fbf9-4388-83d9-342ef73b6aee |
| name                      | DMZ_NET                              |
| provider:network_type     | gre                                  |
| provider:physical_network |                                      |
| provider:segmentation_id  | 20                                   |
| shared                    | True                                 |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | 75a79e144bcd45f6b66b2deb884a73a9     |
+---------------------------+--------------------------------------+

[root@controller01 ~]# neutron subnet-create APPS_NET 10.241.0.0/22 --name APPS_SUBNET --dns-nameservers list=true 8.8.8.8 4.2.2.2

Created a new subnet:
+------------------+------------------------------------------------+
| Field            | Value                                          |
+------------------+------------------------------------------------+
| allocation_pools | {"start": "10.241.0.2", "end": "10.241.3.254"} |
| cidr             | 10.241.0.0/22                                  |
| dns_nameservers  | 4.2.2.2                                        |
|                  | 8.8.8.8                                        |
| enable_dhcp      | True                                           |
| gateway_ip       | 10.241.0.1                                     |
| host_routes      |                                                |
| id               | 06f2839f-f494-447f-9cba-0884bba52327           |
| ip_version       | 4                                              |
| name             | APPS_SUBNET                                    |
| network_id       | d063d15a-1eb7-4e6c-990a-efdc1515a3fb           |
| tenant_id        | 75a79e144bcd45f6b66b2deb884a73a9               |
+------------------+------------------------------------------------+

[root@controller01 ~]# neutron subnet-create DMZ_NET 10.242.0.0/22 --name DMZ_SUBNET --dns-nameservers list=true 8.8.8.8 4.2.2.2
Created a new subnet:
+------------------+------------------------------------------------+
| Field            | Value                                          |
+------------------+------------------------------------------------+
| allocation_pools | {"start": "10.242.0.2", "end": "10.242.3.254"} |
| cidr             | 10.242.0.0/22                                  |
| dns_nameservers  | 4.2.2.2                                        |
|                  | 8.8.8.8                                        |
| enable_dhcp      | True                                           |
| gateway_ip       | 10.242.0.1                                     |
| host_routes      |                                                |
| id               | 8e992658-f467-4571-aa8e-698aa2d9fda5           |
| ip_version       | 4                                              |
| name             | DMZ_SUBNET                                     |
| network_id       | c0a1958a-fbf9-4388-83d9-342ef73b6aee           |
| tenant_id        | 75a79e144bcd45f6b66b2deb884a73a9               |
+------------------+------------------------------------------------+
```

Attaching the networks to the router can be accomplished with the 'router-interface-add' command:

Syntax: ```neutron router-interface-add <router-id> <interface>```

Where ```router-id``` is the ID or name of the router, and ```interface``` is the ID or name of the subnet.


```
[root@controller01 ~]# neutron router-interface-add NEUTRON-ROUTER APPS_SUBNET
Added interface 00bb311f-08db-46fa-96e7-1280c027033e to router NEUTRON-ROUTER.
[root@controller01 ~]# neutron router-interface-add NEUTRON-ROUTER DMZ_SUBNET
Added interface 8ab84178-b66c-4d7b-9a0a-4e739236eabd to router NEUTRON-ROUTER.
```

A quick look at the router namespace shows two new interfaces configured:

```
[root@controller01 ~]# ip netns exec qrouter-ba605e63-3c54-402b-9bd7-3eba85d00080 ip a
136: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
137: qg-8860da83-31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether fa:16:3e:57:0b:47 brd ff:ff:ff:ff:ff:ff
    inet 192.168.101.2/22 brd 192.168.103.255 scope global qg-8860da83-31
    inet6 fe80::f816:3eff:fe57:b47/64 scope link
       valid_lft forever preferred_lft forever
145: qr-00bb311f-08: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether fa:16:3e:de:46:c3 brd ff:ff:ff:ff:ff:ff
    inet 10.241.0.1/22 brd 10.241.3.255 scope global qr-00bb311f-08
    inet6 fe80::f816:3eff:fede:46c3/64 scope link
       valid_lft forever preferred_lft forever
147: qr-8ab84178-b6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether fa:16:3e:05:23:98 brd ff:ff:ff:ff:ff:ff
    inet 10.242.0.1/22 brd 10.242.3.255 scope global qr-8ab84178-b6
    inet6 fe80::f816:3eff:fe05:2398/64 scope link
       valid_lft forever preferred_lft forever
```

A look into OVS shows that all three router interfaces are in the integration bridge and adhere to OVS flow rules:

```
[root@controller01 ~]# ovs-vsctl show
5ec91d45-1520-416c-b668-2cc1e6dd1faa
...
    Bridge br-int
    	...
        Port "tap8860da83-31"
            tag: 9
            Interface "tap8860da83-31
        Port "tap00bb311f-08"
            tag: 10
            Interface "tap00bb311f-08"
        Port "tap8ab84178-b6"
            tag: 11
            Interface "tap8ab84178-b6"
...

[root@controller01 ~]# ovs-ofctl dump-flows br-int
NXST_FLOW reply (xid=0x4):
...
 cookie=0x0, duration=7605.772s, table=0, n_packets=8, n_bytes=740, idle_age=6880, priority=3,in_port=30,dl_vlan=1998 actions=mod_vlan_vid:9,NORMAL
...
```

### Testing: Instance creation and communication tests

To test connectivty I will spin up two instances - one per network.

```
[root@controller01 ~]# nova boot --flavor=myFlavor.5 --key_name=controller-id_rsa --image=31939ad3-86bc-4c51-8740-d307e63edf2d --nic net-id=d063d15a-1eb7-4e6c-990a-efdc1515a3fb APPS_INSTANCE
[root@controller01 ~]# nova show APPS_INSTANCE
+--------------------------------------+--------------------------------------------------+
| Property                             | Value                                            |
+--------------------------------------+--------------------------------------------------+
| status                               | ACTIVE                                           |
| updated                              | 2013-12-18T17:24:23Z                             |
| OS-EXT-STS:task_state                | None                                             |
| OS-EXT-SRV-ATTR:host                 | compute01.grizzly.openstacksupport.com           |
| key_name                             | controller-id_rsa                                |
| image                                | Ubuntu_Precise                                   |
| hostId                               | 6041cc5a34abc3e998ff86c5458b5ae09d0a7a1706cda4b6a|
| OS-EXT-STS:vm_state                  | active                                           |
| OS-EXT-SRV-ATTR:instance_name        | instance-0000003f                                |
| OS-SRV-USG:launched_at               | 2013-12-18T17:24:23.000000                       |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute01.grizzly.openstacksupport.com           |
| flavor                               | myFlavor.5 (63805c42-e928-4228-a3f4-616e0a44b134)|
| id                                   | 20316c55-4b2a-43a2-aa23-a83fe9972af1             |
| security_groups                      | [{u'name': u'default'}]                          |
| OS-SRV-USG:terminated_at             | None                                             |
| user_id                              | d44ac34a6c514fe9af169bcb099d473e                 |
| name                                 | APPS_INSTANCE                                    |
| created                              | 2013-12-18T17:24:13Z                             |
| tenant_id                            | 75a79e144bcd45f6b66b2deb884a73a9                 |
| APPS_NET network                     | 10.241.0.3                                       |
| OS-DCF:diskConfig                    | MANUAL                                           |
| metadata                             | {}                                               |
| os-extended-volumes:volumes_attached | []                                               |
| accessIPv4                           |                                                  |
| accessIPv6                           |                                                  |
| progress                             | 0                                                |
| OS-EXT-STS:power_state               | 1                                                |
| OS-EXT-AZ:availability_zone          | nova                                             |
| config_drive                         |                                                  |
+--------------------------------------+--------------------------------------------------+

[root@controller01 ~]# nova boot --flavor=myFlavor.5 --key_name=controller-id_rsa --image=31939ad3-86bc-4c51-8740-d307e63edf2d --nic net-id=c0a1958a-fbf9-4388-83d9-342ef73b6aee DMZ_INSTANCE
[root@controller01 ~]# nova show DMZ_INSTANCE
+--------------------------------------+--------------------------------------------------+
| Property                             | Value                                            |
+--------------------------------------+--------------------------------------------------+
| status                               | BUILD                                            |
| updated                              | 2013-12-18T17:25:12Z                             |
| OS-EXT-STS:task_state                | spawning                                         |
| OS-EXT-SRV-ATTR:host                 | compute01.grizzly.openstacksupport.com           |
| key_name                             | controller-id_rsa                                |
| image                                | Ubuntu_Precise (31939ad3-86bc-4c51-8740-d307e63ed|
| hostId                               | 6041cc5a34abc3e998ff86c5458b5ae09d0a7a1706cda4b6a|
| OS-EXT-STS:vm_state                  | building                                         |
| OS-EXT-SRV-ATTR:instance_name        | instance-00000041                                |
| OS-SRV-USG:launched_at               | None                                             |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute01.grizzly.openstacksupport.com           |
| flavor                               | myFlavor.5 (63805c42-e928-4228-a3f4-616e0a44b134)|
| id                                   | e54118be-6a1d-4e0f-8b6d-01bf9f19880d             |
| security_groups                      | [{u'name': u'default'}]                          |
| OS-SRV-USG:terminated_at             | None                                             |
| user_id                              | d44ac34a6c514fe9af169bcb099d473e                 |
| name                                 | DMZ_INSTANCE                                     |
| created                              | 2013-12-18T17:25:11Z                             |
| tenant_id                            | 75a79e144bcd45f6b66b2deb884a73a9                 |
| OS-DCF:diskConfig                    | MANUAL                                           |
| metadata                             | {}                                               |
| os-extended-volumes:volumes_attached | []                                               |
| accessIPv4                           |                                                  |
| accessIPv6                           |                                                  |
| DMZ_NET network                      | 10.242.0.3                                       |
| progress                             | 0                                                |
| OS-EXT-STS:power_state               | 0                                                |
| OS-EXT-AZ:availability_zone          | nova                                             |
| config_drive                         |                                                  |
+--------------------------------------+--------------------------------------------------+
```

Because these instances are behind a Neutron router and are without floating IPs,
there is no direct connectivity to them outside of the corresponding router or
DHCP namespace or a multi-homed instance. You can confirm successful DHCP and
metadata communication via the console-log, however:

```

[root@controller01 ~]# nova console-log APPS_INSTANCE
...
cloud-init start-local running: Wed, 18 Dec 2013 17:24:34 +0000. up 2.32 seconds
no instance data found in start-local
ci-info: lo    : 1 127.0.0.1       255.0.0.0       .
ci-info: eth0  : 1 10.241.0.3      255.255.252.0   fa:16:3e:67:8d:1e
ci-info: route-0: 0.0.0.0         10.241.0.1      0.0.0.0         eth0   UG
ci-info: route-1: 10.241.0.0      0.0.0.0         255.255.252.0   eth0   U
cloud-init start running: Wed, 18 Dec 2013 17:24:36 +0000. up 5.22 seconds
...
Generating public/private rsa
```
