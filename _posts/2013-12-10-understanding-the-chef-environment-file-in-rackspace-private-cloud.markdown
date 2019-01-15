---
layout: post
title: Understanding the Chef Environment File in Rackspace Private Cloud
date: '2013-12-10 11:01'
comments: true
author: James Thorne
published: true
categories:
  - chef
  - devops
  - private cloud
  - OpenStack
---

Rackspace Private Cloud uses Chef to deploy an OpenStack environment. Chef
provides the ability to quickly configure and deploy an OpenStack environment
on one to many nodes. An integral part of deployment is the Chef Environment
file. This file can be difficult to understand as a newcomer to Chef.

In the following post, I am going to break down each part of two typical Chef
Environment files specific to Rackspace Private Cloud v4.1.x powered by
OpenStack Grizzly.

_A new post covering the Chef Environment file for Rackspace Private Cloud v4.2.x, including the highly available bits, can be found [here](http://developer.rackspace.com/blog/understanding-the-chef-environment-file-in-rackspace-private-cloud-v4-dot-2-x-powered-by-openstack-havana.html)._

<!-- more -->

Typical Chef Environments
-------------------------

Below are two typical Chef Environment files to install Rackspace Private
Cloud v4.1.x, one with nova-network and one with Quantum Networking.

The Chef Environment file will differ slightly depending on which OpenStack
Networking model you chose.

In this scenario, each of the following Chef Environment files represent an OpenStack environment where the controller and compute nodes each use three network interfaces (eth0, eth1, and eth2).

__eth0__ on each node will be connected to a managed network switch as an __access__ port on a unique VLAN with network subnet __192.168.236.0/24__; the OpenStack APIs and services will listen on this network interface.

__eth1__ on each node will be connected to a managed network switch as an __access__ port. If you are using __nova-network__ the network interface will be active but left un-configured because Chef will configure it. If you are using __Quantum Networking__ the network interface will be on a unique VLAN with network subnet __192.168.240.0/24__; OpenStack instances will communicate on this network interface through GRE tunnels.

__eth2__ on each node will also be connected to a managed network switch but as a __trunk__ port containing all of the VLANs you want available in the OpenStack environment; Depending on which OpenStack Networking model you use, nova-networks or Quantum Provider Networks will be created from these VLANs and will communicate over this network interface.

#### Rackspace Private Cloud v4.1.x using nova-network Chef Environment File:

    {
        "name": "rpc-grizzly",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {
            "nova": {
                "network": {
                    "provider": "nova",
                    "public_interface": "br-eth1"
                },
                "networks": {
                    "public": {
                        "label": "public",
                        "bridge_dev": "eth1",
                        "bridge": "br-eth1",
                        "ipv4_cidr": "192.168.100.0/24",
                        "dns1": "8.8.4.4",
                        "dns2": "8.8.8.8"
                    }
                }
            },
            "mysql": {
                "allow_remote_root": true,
                "root_network_acl": "%"
            },
            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24"
            }
        }
    }

#### Rackspace Private Cloud v4.1.x using Quantum Networking Chef Environment File:

    {
        "name": "rpc-grizzly",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
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
                            "label": "ph-eth2",
                            "bridge": "br-eth2"
                        }
                    ],
                    "network_type": "gre",
                    "network": "quantum"
                }
            },
            "mysql": {
                "allow_remote_root": true,
                "root_network_acl": "%"
            },
            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24",
                "quantum": "192.168.240.0/24"
            }
        }
    }

The default JSON Block
----------------------

    {
        "name": "rpc-grizzly",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {}
    }

Above is what you would see if you created a new Chef Environment file with the following command:

    knife environment create rpc-grizzly -d "Rackspace Private Cloud"

There isn't much going on here.

When using Rackspace Private Cloud, the  __override_attributes__ JSON block is the main part to configure in the Chef Environment file. Inside this JSON block is where you will override the default attributes already set in the Chef Cookbooks to match your environment.

So, let's break down the various JSON blocks within the __override_attributes__ JSON block that apply to this scenario.

The nova JSON Block
-------------------

Below are two different __nova__ JSON blocks, one for __nova-network__ and one for
__Quantum Networking__. One or the other will be used depending on which
OpenStack Networking model you want to use.

#### Using nova-network

    "nova": {
        "network": {
            "provider": "nova",
            "public_interface": "br-eth1"
        },
        "networks": {
            "public": {
                "label": "public",
                "bridge_dev": "eth1",
                "bridge": "br-eth1",
                "ipv4_cidr": "192.168.100.0/24",
                "dns1": "8.8.4.4",
                "dns2": "8.8.8.8"
            }
        }
    },

Above is the __nova__ JSON block if you are using __nova-network__.

In our scenario, there are two JSON blocks within the nova JSON block:
__network__ and __networks__.

Inside the network JSON block are two attributes: __provider__ and
__public_interface__.

The __provider__ attribute specifies what OpenStack Networking model to use.
In this case __nova-network__ will be used instead of __Quantum Networking__.

The __public_interface__ attribute specifies what network interface on the
compute nodes nova-network floating IP addresses will be assigned to. This
parameter can be found in the __/etc/nova/nova.conf__ file on the controller
and compute nodes.

Inside the __networks__ JSON block is another JSON block called __public__.
The __networks__ JSON block will accept two JSON blocks: a JSON block labeled
__public__, as shown above, and an optional JSON block labeled __private__.
The __public__ and __private__ JSON blocks are labeled this way because the
__public__ JSON block is meant to setup a nova-network that allows outbound
network access from the OpenStack instances and the __private__ JSON block is meant to
setup a nova-network that only allows instance-to-instance communication.
__public__ and __private__ are just labels, you could setup a private
network in the __public__ JSON block or a public network in the __private__
JSON block. However, adhering to the intended convention will make everything
easier to understand. A more appropriate name for the __public__ attribute would
be __fixed__ because an OpenStack instance will always be assigned, or __"fixed"__, an
IP address from the nova-network you specified. In addition, the __public__ attribute is
commonly confused with the __public__ attribute in the __osops_networks__ JSON block,
which you will read about later, and has no relation to it.

When the chef-client command is run on the compute node, it will use the
attributes in the __public__ JSON block, and the __private__ JSON block if
you set it up, to create a nova-network using the `nova-manage network create`
command. A Linux bridge interface named __br-eth1__ will be created and the physical
network interface, __eth1__, will be attached to it. In addition, a dnsmasq
process will be spawned serving IP addresses in the __192.168.100.0/24__
subnet from __192.168.168.100.2 - 192.168.100.254__; __192.168.100.1__ is
skipped because this is usually the gateway IP address for the network
terminated on a router or firewall elsewhere in the network. OpenStack instances will have
their virtual network interfaces attached to the __br-eth1__ bridge interface
so they can communicate on the __192.168.100.0/24__ network.

#### Using Quantum Networking

    "nova": {
        "network": {
            "provider": "quantum"
        }
    },

Above is the __nova__ JSON block if you are using __Quantum Networking__.

The __nova__ JSON block has one attribute: __network__.

Inside the __network__ JSON block is one attribute: __provider__.

The __provider__ attribute specifies what OpenStack Networking model to
use. The two possible values are __nova-network__ and __quantum__, but
in this scenario __quantum__ will be used. When using Quantum Networking,
there are additional configuration steps required after running
__chef-client__ on each node. Some of these configuration steps are
mentioned in the following section.

The quantum JSON Block
----------------------

    "quantum": {
        "ovs": {
            "provider_networks": [
                {
                    "label": "ph-eth2",
                    "bridge": "br-eth2"
                }
            ],
            "network_type": "gre",
            "network": "quantum"
        }
    },

Above is the __quantum__ JSON block. This would only be in the Chef Environment
file if you are using Quantum Networking.

The __quantum__ JSON block has one attribute: __ovs__.

Inside of the __ovs__ JSON block are three attributes: __provider_networks__, __network_type__, and __network__.

The __provider_networks__ attribute is an array and contains two attributes: __label__ and __bridge__. The __label__ attribute contains a value that specifies the name of a label which points to the Open vSwitch Bridge created in the subsequent attribute, __bridge__.

The __bridge__ attribute contains a value that specifies the name of the Open vSwitch Bridge interface that the `ovs-vsctl add-br` command will create when the __chef-client__ command is run on each node. These attributes are found in the __/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini__ file on the controller and compute nodes. As mentioned above, __eth2__ is the network interface that is connected to a managed network switch as a trunk port containing all of the VLANs you want available in the OpenStack environment. __eth2__ is connected to the __br-eth2__ Open vSwitch Bridge by running `ovs-vsctl add-port br-eth2 eth2` on each node after __chef-client__ is run. At this point, the `quantum net-create` command can be used to create Quantum Provider Networks for each VLAN in the trunk. OpenStack instances can then be attached to these Quantum Provider Networks.

The __network_type__ attribute sets the default type of Quantum Tenant Network created when it is not specified in the `quantum net-create` command. The different types of Quantum Tenant Networks you can create are __gre__ and __vlan__. Both GRE and VLAN based Quantum Tenant Networks can be created and used at the same time, but if you set __network_type__ to __vlan__, __gre__ Quantum Tenant Networks cannot be created. This attribute is found in the __/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini__ file on the controller and compute nodes.

By default, if GRE tunnels are used for Quantum traffic, each node's GRE tunnel will communicate on whatever network is assigned to the __nova__ __osops_network__ attribute. In this scenario, the __nova__ __osops_network__ attribute is tied to eth0 on each node. However, the Quantum traffic should be kept separate from the traffic on eth0 and eth1 will be used. So, the __network__ attribute has been added to the __quantum__ JSON block to point to the __quantum__ __osops_network__ attribute which will configure the GRE tunnels to communicate on network __192.168.240.0/24__ on eth1 on each node.

The mysql JSON Block
--------------------

    "mysql": {
        "allow_remote_root": true,
        "root_network_acl": "%"
    },

Above is the __mysql__ JSON block.

The __mysql__ JSON block has two attributes: __allow_remote_root__ and __root_network_acl__.

The __allow_remote_root__ attribute with a value of __true__ allows remote root connections to the MySQL service.

The __root_network_acl__ attribute defines the network where the MySQL root user can login from. With this attribute set to value __%__, which is a wild card in MySQL, the MySQL root user can log into the mysql service from any host.

The osops_networks JSON Block
-----------------------------

Below are two different __osops__networks__ JSON blocks, one for __nova-network__ and one for
__Quantum Networking__. One or the other will be used depending on which
OpenStack Networking model you want to use.

The nova-network __osops_network__ JSON block does not have the __quantum__ attribute because it does not need it.

#### Using nova-network

            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24"
            }
        }
    }

#### Using Quantum Networking

            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24",
                "quantum": "192.168.240.0/24"
            }
        }
    }

The __osops_networks__ JSON block has three default attributes: __nova__, __public__, and __management__.

If you are using Quantum Networking, the __quantum__ attribute has been added. Additional attributes can also be added, such as __cinder__, for additional configuration.

The three default attributes, __nova__, __public__, and __management__, map to specific OpenStack services and each attribute's value is expecting a network subnet, not a specific IP address. When __chef-client__ is run on each node, the Chef Cookbooks will search for a network interface assigned an IP address within the specified network subnet. That IP address is then used as the listening IP address for each OpenStack service mapped to that specific attribute.

The __quantum__ attribute is not tied to any OpenStack services, and has been added only so the GRE tunnels communicate on the __192.168.240.0/24__ network and not the __192.168.236.0/24__ network which is assigned to the __nova__ attribute.

Below is a rough list of what services map to the default __nova__, __public__, and __management__ attributes:

__rsyslog__ and __ntpd__ do not map to any attribute. __rsyslog__ binds
to __0.0.0.0__ and __ntpd__ binds to all interfaces.

#### nova

The following services were found by running the following command on the Chef Server (the command assumes the Chef Cookbooks are in root's home directory):

    fgrep -r '["network"] = "nova"' /root/chef-cookbooks

* keystone-admin-api
* nova-xvpvnc-proxy
* nova-novnc-proxy
* nova-novnc-server

#### public

The following services were found by running the following command on the Chef Server (the command assumes the Chef Cookbooks are in root's home directory):

    fgrep -r '["network"] = "public"' /root/chef-cookbooks

* ceilometer-api
* cinder-api
* glance-api
* glance-registry
* heat-cloudwatch_api
* heat-cfn_api
* heat-base_api
* horizon-dash
* horizon-dash_ssl
* keystone-service-api
* nova-api
* nova-ec2-admin
* nova-ec2-public
* nova-volume
* quantum-api

#### management

The following services were found by running the following command on the Chef Server (the command assumes the Chef Cookbooks are in root's home directory):

    fgrep -r '["network"] = "management"' /root/chef-cookbooks

* ceilometer-internal-api
* ceilometer-admin-api
* ceilometer-central
* cinder-internal-api
* cinder-admin-api
* cinder-volume
* collectd
* glance-admin-api
* glance-internal-api
* statsd
* graphite-api
* carbon-line-receiver
* carbon-pickle-receiver
* carbon-cache-query
* heat-cfn_internal_api
* heat-base_internal_api
* heat-base_admin_api
* keystone-internal-api
* memcached-cache
* mysql
* rabbitmq-server
* nova-internal-api
* nova-admin-api

Diving Deeper
-------------

I have gone through two typical Chef Environment files that can be used to
install Rackspace Private Cloud v4.1.x powered by OpenStack Grizzly with
nova-network and with Quantum Networking.

If you want to dive deeper, there are many other override attributes that can
be set in the Chef Environment file. You can see all the different attributes
that can be overridden by logging into your Chef Server (I am assuming the
Rackspace Private Cloud Chef Cookbooks are downloaded there), changing into
the __chef-cookbooks__ directory, changing into the particular Chef Cookbook
directory you want to change the default attributes of, changing into the
__attributes__ directory, and finally opening the __default.rb__ file.

For comments, feel free to get in touch with me [@jameswthorne](https://twitter.com/jameswthorne).