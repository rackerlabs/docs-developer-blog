---
layout: post
title: 'Neutron Networking: Simple flat network'
date: '2013-10-08 17:00'
comments: true
author: James Denton
published: true
categories:
  - OpenStack
  - Neutron
  - Cloud Networks
---

In this multi-part walkthrough series, I intend to dive into the various components of the OpenStack Neutron project, and to also provide working examples of multiple networking configurations for clouds built with Rackspace Private Cloud powered by OpenStack on Ubuntu 12.04 LTS. When possible, I’ll provide configuration file examples for those following along on an install from source.

In the previous installment, [Neutron Networking: The Building Blocks of an OpenStack Cloud](https://developer.rackspace.com/blog/neutron-networking-the-building-blocks-of-an-openstack-cloud.html), I laid the foundation of the Neutron networking model that included terminology, concepts, and a brief description of services and capabilities. In this second installment, I’ll describe how to build a simple flat network consisting of a few servers and limited networking gear. Future installments will include VLAN-based provider and tenant networks, GRE-based tenant networks, Open vSwitch troubleshooting, and more.<!-- more -->

_New to OpenStack? Rackspace offers a complete open-source package, [Rackspace Private Cloud Software](http://www.rackspace.com/cloud/private/), that you're welcome to use at no cost. Download and follow along._

### Getting started: What is a flat network?

For those coming from previous Essex- or Folsom-based Rackspace Private Cloud installations, flat networking in Neutron resembles the Flat DHCP model in Nova networking. For those new to the game, a flat network is one in which all instances reside on the same network (which may also be shared by the hosts). No vlan tagging takes place, and Neutron handles the assignment of IPs to instances using DHCP. Therefore, it’s possible to use unmanaged SOHO network switches to build a simple Neutron-based cloud, since there’s no need to configure switchports.

![](http://i.imgur.com/C7uzjps.png "Sample Flat Network")

_The diagram above represents a simple Neutron networking configuration that utilizes a flat provider network for connectivity of instances to the Internet._


### Networking: Layout

In the following diagram, a Cisco ASA 5510 is serving as the lead gateway device, with a Cisco 2960G access switch connecting the firewall and servers together via VLAN 1. 10.240.0.0/24 was chosen as the management network for hosts, but will also serve as a provider network for instances. We’ll be using a single interface on the servers for both management and provider network connectivity.

![](http://i.imgur.com/iogcVgo.png "Sample Flat Layout")

### Networking: Configuration of physical devices

The Cisco ASA was chosen for this example as it’s readily available at my location. Any router or firewall should be sufficient as long as you’re able to disable DHCP on the inside interface (you don’t want it to conflict with Neutron, after all).

Interface e0/0 should be configured with your WAN IP. Interface e0/1 must be configured with an IP address that will serve as the gateway for hosts and instances:

```
interface Ethernet0/1
  speed 100
  duplex full
  nameif mgmt
  security-level 100
  ip address 10.240.0.1 255.255.255.0
```

Depending on the model of switch, your switchports may be unmanaged or in vlan 1 by default. With the flat networking model, your gateway and hosts must simply sit in the same vlan or broadcast domain; the vlan ID itself is irrelevant.
There’s a good chance your servers have their IP configured directly on eth0. To utilize Neutron, the hosts must have a network bridge configured. This can be accomplished one of two ways:

-	Configure a bridge containing eth0
-	Configure a bridge containing another interface

The first option enables you to use a single interface on the nodes. However, there are plenty of cases where you may prefer to use other interfaces or configure multiple bridges. For this example, I’ll use a single interface and move the IP address from eth0 to the bridge.

Below is what a default eth0 configuration might look like:

```
auto eth0
 iface eth0 inet static
  address 10.240.0.10
  netmask 255.255.255.0
  gateway 10.240.0.1
  nameserver 8.8.8.8
```

In order to configure the bridge, eth0 must be modified and the bridge interface created:

```
auto eth0
iface eth0 inet manual
  up ip l s $IFACE up
  down ip l s $IFACE down

iface br-eth0 inet static
  address 10.240.0.10
  netmask 255.255.255.0
  gateway 10.240.0.1
  nameserver 8.8.8.8
```

_TIP: Do not set br-eth0 to auto. Because of the order that processes are started at boot, the interface must be brought up using rc.local. Instead, edit the /etc/rc.local file of each machine and add the following line before the 'exit' statement:_

```
ifup br-eth0
exit 0
```


### Networking: Open vSwitch configuration

Briefly mentioned in the previous installment, [Neutron Networking: The Building Blocks of an OpenStack Cloud](https://developer.rackspace.com/blog/neutron-networking-the-building-blocks-of-an-openstack-cloud.html), was Open vSwitch – the virtual switching infrastructure utilized by Neutron. Creating the bridge in Open vSwitch is a requirement for proper management of traffic.

The following will create a bridge called ‘br-eth0’ and place physical interface eth0 inside:

```
ovs-vsctl add-br br-eth0
ovs-vsctl add-port br-eth0 eth0
```

The creation and configuration of the bridge enables the instances to communicate on the network.

#### Changes to environment (RPC v4)

When using RPC v4, most configuration changes are handled via Chef. A few changes must be made to the environment file to utilize the bridge for Neutron networking.

```
knife environment edit grizzly
```

Look for the section 'quantum : ovs : provider_networks'

```
"quantum": {
  "ovs": {
    "provider_networks":
```

The bridge configuration should be modified to mirror the following example, if it doesn't already exist:

```
{
  "label": "ph-eth0",
  "bridge": "br-eth0",
  "vlans": "1:1"
}
```

Note: The vlan range above is not used in this example

The label ‘ph-eth0’ represents our provider interface, in this case the bridge ‘br-eth0’. It will be used during the creation of networks in Neutron.

The resulting file would look something like this:


```
{
  "name": "grizzly",
  "description": "",
  "cookbook_versions": {
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {
  },
  "override_attributes": {
    "nova": {
      "network": {
        "provider": "quantum"
      }
    },
    "quantum": {
      "ovs": {
	"provider_networks": [
          {
            "label": "ph-eth0",
            "bridge": "br-eth0",
            "vlans": "1:1"
          }
	],
	"network_type": "gre"
      }
    },
    "mysql": {
      "allow_remote_root": true,
      "root_network_acl": "%"
    },
    "osops_networks": {
      "nova": "10.240.0.0/24",
      "public": "10.240.0.0/24",
      "management": "10.240.0.0/24"
    }
  }
}
```

Save the changes to the file and run chef-client on all the hosts to populate the changes.

#### Changes to environment (other)

When using something other than RPC v4 (such as the OpenStack source), configuration changes must be made to the appropriate configuration files and services restarted manually.

Within /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini, update the following values:

```
[OVS]
tenant_network_type = gre
integration_bridge = br-int
enable_tunneling = True
tunnel_bridge = br-tun
tunnel_id_ranges = 1:1000
network_vlan_ranges = ph-eth0:1:1
bridge_mappings = ph-eth0:br-eth0
```

The label ‘ph-eth0’ represents our provider interface, in this case the bridge ‘br-eth0’. It will be used during the creation of networks in Neutron. It’s possible to have more than one provider bridge, especially when you have multiple switching infrastructures for various networks and services. Restart all Neutron and Open vSwitch services on all hosts for the changes to take effect.

### Networking:OVS confirmation

Remember the bridge (br-eth0) we created in OVS earlier? At a high level, it can be looked at as our bridge to the physical network infrastructure. Neutron requires an ‘Integration Bridge’ that serves as the bridge to our virtual instances. The integration bridge connects vNICs and Neutron DHCP and L3 agents with virtual networks. Overriding the default value of ‘br-int’ is not recommended, as the bridge must be named the same on each host (controller/compute).
RPC v4 creates this bridge during the chef-client run.

```
[root@controller01 ~]# ovs-vsctl show
   Bridge "br-eth0"
        Port "eth0"
            Interface "eth0"
        Port "phy-br-eth0"
            Interface "phy-br-eth0"
        Port "br-eth0"
            Interface "br-eth0"
                type: internal
    Bridge br-int
        Port br-int
            Interface br-int
                type: internal
        Port "int-br-eth0"
            Interface "int-br-eth0"
```

For those installing from source, the name of the bridge is defined in /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini:

```
[OVS]
integration_bridge = br-int
```

The bridge will need to be created manually in OVS if you are not using Chef:

```
ovs-vsctl add-br br-int
```

### Networking: Building a flat provider network in Neutron

Now that the infrastructure is in place and the bridges are configured, it’s time to build a flat provider network in Neutron. Creating a flat provider network requires only two values: the name of the network and the provider bridge label. There are additional flags that can be specified, but these aren’t required for basic connectivity.


Syntax: ```quantum net-create --provider:physical_network=<provider label> --provider:network_type=flat <network name>```

```
[root@controller01 ~]# quantum net-create --provider:physical_network=ph-eth0 --provider:network_type=flat --shared MY_FLAT_NET
Created a new network:
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | 8fc2a9c0-8bd2-4918-a9a0-2892d7680a8f |
| name                      | MY_FLAT_NET                          |
| provider:network_type     | flat                                 |
| provider:physical_network | ph-eth0                              |
| provider:segmentation_id  |                                      |
| router:external           | False                                |
| shared                    | True                                 |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | daa5a955bba743398f1a2254d9479a43     |
+---------------------------+--------------------------------------+
```

With the network created, it’s time to create the subnet. When allocating a range of addresses for the DHCP pool, be sure not to overlap with other machines on the network (including the controller/compute nodes).

Syntax:
```
quantum subnet-create <network_name> <subnet>  --name <subnet_name> --no-gateway
--host-route destination=<dest_network>,nexthop=<nexthop_ip> --allocation-pool
start=<dhcp_start_ip>,end=<dhcp_end_ip> --dns-nameservers list=true <dhcp_ip_1> <dhcp_ip_2>
```

It’s a good idea to provide values for the following options:

- ```--no-gateway```		Instructs Quantum not to provide a gateway IP.
- ```--host-route```		Provides route injection via DHCP.
- ```--allocation-pool```		Defines the DHCP IP pool boundaries
- ```--dns-nameservers```		Defines DNS servers

_When a gateway is defined, Neutron assumes all metadata routes are handled by the specified gateway and will not inject the metadata route via DHCP to instances. By specifying the ```--no_gateway``` flag and defining a default route manually, we’re able to provide instances with a default route as well as an automatic metadata route to the namespace IP._

```
[root@controller01 ~]# quantum subnet-create MY_FLAT_NET 10.240.0.0/24 --name MY_FLAT_SUBNET --no-gateway --host-route destination=0.0.0.0/0,nexthop=10.240.0.1 --allocation-pool start=10.240.0.230,end=10.240.0.234 --dns-nameservers list=true 8.8.8.7 8.8.8.8
Created a new subnet:
+------------------+-------------------------------------------------------+
| Field            | Value                                                 |
+------------------+-------------------------------------------------------+
| allocation_pools | {"start": "10.240.0.230", "end": "10.240.0.234"}      |
| cidr             | 10.240.0.0/24                                         |
| dns_nameservers  | 8.8.8.7                                               |
|                  | 8.8.8.8                                               |
| enable_dhcp      | True                                                  |
| gateway_ip       |                                                       |
| host_routes      | {"destination": "0.0.0.0/0", "nexthop": "10.240.0.1"} |
| id               | 66fd6eb5-8c20-441e-a767-2ede7ffa0855                  |
| ip_version       | 4                                                     |
| name             | MY_FLAT_SUBNET                                        |
| network_id       | 8fc2a9c0-8bd2-4918-a9a0-2892d7680a8f                  |
| tenant_id        | daa5a955bba743398f1a2254d9479a43                      |
+------------------+-------------------------------------------------------+
```

### Networking: Testing connectivity

Now that the network has been built in Neutron, it’s time to test connectivity by spinning up an instance. Like the hosts, my instance is Ubuntu 12.04 LTS.

Syntax: ```nova boot --image <image_uuid> --flavor <flavor_name> --key_name <keypair_name> --nic net-id=<network_id> <instance_name>```

```
[root@controller01 init.d]# nova boot --image a1888641-be81-46c9-b1a1-f91805bf1130 --flavor m1.small --key_name test --nic net-id=8fc2a9c0-8bd2-4918-a9a0-2892d7680a8f MY_INSTANCE_1

+-------------------------------------+--------------------------------------+
| Property                            | Value                                |
+-------------------------------------+--------------------------------------+
| status                              | BUILD                                |
| updated                             | 2013-09-16T19:39:39Z                 |
| OS-EXT-STS:task_state               | scheduling                           |
| OS-EXT-SRV-ATTR:host                | None                                 |
| key_name                            | test                                 |
| image                               | Ubuntu 12.04.1 Precise (cloudimg)    |
| hostId                              |                                      |
| OS-EXT-STS:vm_state                 | building                             |
| OS-EXT-SRV-ATTR:instance_name       | instance-0000000d                    |
| OS-EXT-SRV-ATTR:hypervisor_hostname | None                                 |
| flavor                              | m1.small                             |
| id                                  | e3956e19-3680-4889-ac3a-d2bf05afd29b |
| security_groups                     | [{u'name': u'default'}]              |
| user_id                             | 2ffc1693eca24a8982ac8fa8b4781d36     |
| name                                | MY_INSTANCE_1                        |
| adminPass                           | T9Y7aYD6ZNW9                         |
| tenant_id                           | daa5a955bba743398f1a2254d9479a43     |
| created                             | 2013-09-16T19:39:39Z                 |
| OS-DCF:diskConfig                   | MANUAL                               |
| metadata                            | {}                                   |
| accessIPv4                          |                                      |
| accessIPv6                          |                                      |
| progress                            | 0                                    |
| OS-EXT-STS:power_state              | 0                                    |
| OS-EXT-AZ:availability_zone         | nova                                 |
| config_drive                        |                                      |
+-------------------------------------+--------------------------------------+

[root@controller01 ~]# nova show e3956e19-3680-4889-ac3a-d2bf05afd29b
+-------------------------------------+---------------------------------------------------------------
| Property                            | Value                                                                    |
+-------------------------------------+---------------------------------------------------------------
| status                              | ACTIVE
| updated                             | 2013-09-16T19:39:46Z
| OS-EXT-STS:task_state               | None
| OS-EXT-SRV-ATTR:host                | compute01.grizzly.openstacksupport.com
| key_name                            | test
| image                               | Ubuntu 12.04.1 Precise (cloudimg) (a1888641-be81-46c9-b1a1-f91805bf1130) |
| hostId                              | 0f33474b1d4a3595e246d144ed8bdc946a0d18e1241a39aef3ef1c90
| OS-EXT-STS:vm_state                 | active
| OS-EXT-SRV-ATTR:instance_name       | instance-0000000d
| MY_FLAT_NET network                 | 10.240.0.230
| OS-EXT-SRV-ATTR:hypervisor_hostname | compute01.grizzly.openstacksupport.com
| flavor                              | m1.small (2)
| id                                  | e3956e19-3680-4889-ac3a-d2bf05afd29b
| security_groups                     | [{u'name': u'default'}]
| user_id                             | 2ffc1693eca24a8982ac8fa8b4781d36
| name                                | MY_INSTANCE_1
| created                             | 2013-09-16T19:39:39Z
| tenant_id                           | daa5a955bba743398f1a2254d9479a43
| OS-DCF:diskConfig                   | MANUAL
| metadata                            | {}
| accessIPv4                          |
| accessIPv6                          |
| progress                            | 0
| OS-EXT-STS:power_state              | 1
| OS-EXT-AZ:availability_zone         | nova
| config_drive                        |
+-------------------------------------+---------------------------------------------------------------
```

Check the Nova console log to verify the instance received its IP, routes and metadata:

```
[root@controller01 ~]# nova console-log MY_INSTANCE_1
...
ci-info: lo    : 1 127.0.0.1       255.0.0.0       .
ci-info: eth0  : 1 10.240.0.230    255.255.255.0   fa:16:3e:e4:d9:c6
ci-info: route-0: 0.0.0.0         10.240.0.1      0.0.0.0         eth0   UG
ci-info: route-1: 10.240.0.0      0.0.0.0         255.255.255.0   eth0   U
ci-info: route-2: 169.254.169.254 10.240.0.231    255.255.255.255 eth0   UGH
cloud-init start running: Mon, 16 Sep 2013 19:40:00 +0000. up 5.38 seconds
...
Generating public/private rsa key pair.
Your identification has been saved in /etc/ssh/ssh_host_rsa_key.
Your public key has been saved in /etc/ssh/ssh_host_rsa_key.pub.
...
```

Once the instance is available, login using the keypair specified in the boot command:

```
[root@controller01 ~]# ssh -i test.pem root@10.240.0.230
```

Confirm the necessary routes are in place:

```
root@my-instance-1:~# netstat -nr
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         10.240.0.1      0.0.0.0         UG        0 0          0 eth0
10.240.0.0      0.0.0.0         255.255.255.0   U         0 0          0 eth0
169.254.169.254 10.240.0.231    255.255.255.255 UGH       0 0          0 eth0
```

Pinging an external IP should reveal positive results as long as a static NAT or PAT exists on the external gateway device and the traffic is permitted:

```
root@my-instance-1:~# ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_req=1 ttl=46 time=14.7 ms
64 bytes from 8.8.8.8: icmp_req=2 ttl=46 time=14.5 ms
64 bytes from 8.8.8.8: icmp_req=3 ttl=46 time=14.4 ms
```

### Summary

With a limited amount of networking hardware one can create a functional private cloud based on Rackspace Private Cloud powered by OpenStack. While the flat network model provides basic connectivity, it is best used in cases where scalability is not a concern, or where switches may be unmanageable.

_Have questions or comments? Feel free to contact or follow me on Twitter [@jimmdenton](https://twitter.com/jimmdenton)_

