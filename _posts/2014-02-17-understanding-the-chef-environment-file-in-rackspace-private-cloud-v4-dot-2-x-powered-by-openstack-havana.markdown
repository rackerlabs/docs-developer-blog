---
layout: post
title: Understanding the Chef Environment File in Rackspace Private Cloud v4.2.x powered by OpenStack Havana
date: '2014-02-17 09:43'
comments: true
author: James Thorne
published: true
categories:
  - OpenStack
  - Private Cloud
  - Chef
  - DevOps
---

In a [previous post](http://developer.rackspace.com/blog/understanding-the-chef-environment-file-in-rackspace-private-cloud.html)
I went through two typical Chef Environment files specific to Rackspace Private
Cloud v4.1.x powered by OpenStack Grizzly with nova-network and Quantum Networking.
However, with Rackspace Private Cloud v4.2.x powered by OpenStack Havana some
things have changed, in particular Quantum has been renamed to Neutron.

In the following post, I am going to break down each part of the Chef
Environment file, including the Highly Available pieces, specific to Rackspace
Private Cloud 4.2.x powered by OpenStack Havana.

<!-- more -->

Typical Chef Environments
-------------------------

Below are two typical Chef Environment files to install Rackspace Private
Cloud v4.2.x, one without Highly Available services and one with Highly
Available services.

In this scenario, each of the following Chef Environment files represent an
OpenStack environment where the controller and compute nodes each use three
network interfaces (eth0, eth1, and eth2).

__eth0__ on each node will be connected to a managed network switch as an
__access__ port on a unique VLAN with network subnet __192.168.236.0/24__; the
OpenStack APIs and services will listen on this network interface.

__eth1__ on each node will be connected to a managed network switch as an
__access__ port on a unique VLAN with network subnet __192.168.240.0/24__;
OpenStack instances will communicate on this network interface through
GRE tunnels.

__eth2__ on each node will also be connected to a managed network switch but as
a __trunk__ port containing all of the VLANs you want available in the
OpenStack environment; Neutron Provider Networks will be created from these
VLANs and will communicate over this network interface.

#### Rackspace Private Cloud v4.2.x Chef Environment File Without Highly Available Services

    {
        "name": "rpc-havana",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {
            "nova": {
                "network": {
                    "provider": "neutron"
                }
            },
            "neutron": {
                "ovs": {
                    "provider_networks": [
                        {
                            "label": "ph-eth2",
                            "bridge": "br-eth2"
                        }
                    ],
                    "network_type": "gre",
                    "network": "neutron"
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
                "neutron": "192.168.240.0/24"
            }
        }
    }

#### Rackspace Private Cloud v4.2.x Chef Environment File With Highly Available Services

    {
        "name": "rpc-havana",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {
            "nova": {
                "network": {
                    "provider": "neutron"
                }
            },
            "neutron": {
                "ovs": {
                    "provider_networks": [
                        {
                            "label": "ph-eth2",
                            "bridge": "br-eth2"
                        }
                    ],
                    "network_type": "gre",
                    "network": "neutron"
                }
            },
            "mysql": {
                "allow_remote_root": true,
                "root_network_acl": "%"
            },
            "vips": {
                "rabbitmq-queue": "192.168.236.50",
                "ceilometer-api": "192.168.236.51",
                "ceilometer-central-agent": "192.168.236.51",
                "cinder-api": "192.168.236.51",
                "glance-api": "192.168.236.51",
                "glance-registry": "192.168.236.51",
                "heat-api": "192.168.236.51",
                "heat-api-cfn": "192.168.236.51",
                "heat-api-cloudwatch": "192.168.236.51",
                "horizon-dash": "192.168.236.51",
                "horizon-dash_ssl": "192.168.236.51",
                "keystone-admin-api": "192.168.236.51",
                "keystone-internal-api": "192.168.236.51",
                "keystone-service-api": "192.168.236.51",
                "nova-api": "192.168.236.51",
                "nova-api-metadata": "192.168.236.51",
                "nova-ec2-public": "192.168.236.51",
                "nova-novnc-proxy": "192.168.236.51",
                "nova-xvpvnc-proxy": "192.168.236.51",
                "swift-proxy": "192.168.236.51",
                "neutron-api": "192.168.236.51",
                "mysql-db": "192.168.236.52",
                "config": {
                    "192.168.236.50": {
                        "vrid": 1,
                        "network": "public"
                    },
                    "192.168.236.51": {
                        "vrid": 2,
                        "network": "public"
                    },
                    "192.168.236.52": {
                        "vrid": 3,
                        "network": "public"
                    }
                }
            },
            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24",
                "neutron": "192.168.240.0/24"
            }
        }
    }

The default JSON Block
----------------------

    {
        "name": "rpc-havana",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {}
    }

Above is what you would see if you created a new Chef Environment file with
the following command:

    knife environment create rpc-havana -d "Rackspace Private Cloud"

There isn't much going on here.

When using Rackspace Private Cloud, the  __override_attributes__ JSON
block is the main part to configure in the Chef Environment file. Inside
this JSON block is where you will override the default attributes already
set in the Chef Cookbooks to match your environment.

So, let's break down the various JSON blocks within the
__override_attributes__ JSON block that apply to this scenario.

The nova JSON Block
-------------------

    "nova": {
        "network": {
            "provider": "neutron"
        }
    },

Above is the __nova__ JSON block.

The __nova__ JSON block has one attribute: __network__.

Inside the __network__ JSON block is one attribute: __provider__.

The __provider__ attribute specifies what OpenStack Networking model to
use. The two possible values are __nova-network__ and __neutron__, but in
this scenario __neutron__ will be used. When using Neutron Networking,
there are additional configuration steps required after running
__chef-client__ on each node. Some of these configuration steps are
mentioned in the following section.

The neutron JSON Block
----------------------

    "neutron": {
        "ovs": {
            "provider_networks": [
                {
                    "label": "ph-eth2",
                    "bridge": "br-eth2"
                }
            ],
            "network_type": "gre",
            "network": "neutron"
        }
    },

Above is the __neutron__ JSON block.

The __neutron__ JSON block has one attribute: __ovs__.

Inside of the __ovs__ JSON block are three attributes:
__provider_networks__, __network_type__, and __network__.

The __provider_networks__ attribute is an array and contains two
attributes: __label__ and __bridge__. The __label__ attribute contains a
value that specifies the name of a label which points to the Open vSwitch
Bridge created in the subsequent attribute, __bridge__.

The __bridge__ attribute contains a value that specifies the name of the Open
vSwitch Bridge interface that the `ovs-vsctl add-br` command will create when
the __chef-client__ command is run on each node. These attributes are found
in the __/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini__ file on
the controller and compute nodes. As mentioned above, __eth2__ is the network
interface that is connected to a managed network switch as a trunk port
containing all of the VLANs you want available in the OpenStack environment.
__eth2__ is connected to the __br-eth2__ Open vSwitch Bridge by running
`ovs-vsctl add-port br-eth2 eth2` on each node after __chef-client__ is run.
At this point, the `neutron net-create` command can be used to create Neutron
Provider Networks for each VLAN in the trunk. OpenStack instances can then be
attached to these Neutron Provider Networks.

The __network_type__ attribute sets the default type of Neutron Tenant Network
created when it is not specified in the `neutron net-create` command. The
different types of Neutron Tenant Networks you can create are __gre__ and __vlan__. Both GRE and VLAN based Neutron Tenant Networks can be created and used at the same time, but if you set __network_type__ to __vlan__, __gre__ Neutron Tenant Networks cannot be created. This attribute is found in the __/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini__ file on the controller and compute nodes.

By default, if GRE tunnels are used for Neutron traffic, each node's GRE
tunnel will communicate on whatever network is assigned to the __nova__
__osops_network__ attribute. In this scenario, the __nova__ __osops_network__
attribute is tied to eth0 on each node. However, the Neutron traffic should be
kept separate from the traffic on eth0 and eth1 will be used. So, the
__network__ attribute has been added to the __neutron__ JSON block to point
to the __neutron__ __osops_network__ attribute which will configure the GRE
tunnels to communicate on network __192.168.240.0/24__ on eth1 on each node.

The mysql JSON Block
--------------------

    "mysql": {
        "allow_remote_root": true,
        "root_network_acl": "%"
    },

Above is the __mysql__ JSON block.

The __mysql__ JSON block has two attributes: __allow_remote_root__ and
__root_network_acl__.

The __allow_remote_root__ attribute with a value of __true__ allows remote
root connections to the MySQL service.

The __root_network_acl__ attribute defines the network where the MySQL root
user can login from. With this attribute set to value __%__, which is a wild
card in MySQL, the MySQL root user can log into the mysql service from any host.

The vips JSON Block
-------------------

    "vips": {
        "rabbitmq-queue": "192.168.236.50",
        "ceilometer-api": "192.168.236.51",
        "ceilometer-central-agent": "192.168.236.51",
        "cinder-api": "192.168.236.51",
        "glance-api": "192.168.236.51",
        "glance-registry": "192.168.236.51",
        "heat-api": "192.168.236.51",
        "heat-api-cfn": "192.168.236.51",
        "heat-api-cloudwatch": "192.168.236.51",
        "horizon-dash": "192.168.236.51",
        "horizon-dash_ssl": "192.168.236.51",
        "keystone-admin-api": "192.168.236.51",
        "keystone-internal-api": "192.168.236.51",
        "keystone-service-api": "192.168.236.51",
        "nova-api": "192.168.236.51",
        "nova-api-metadata": "192.168.236.51",
        "nova-ec2-public": "192.168.236.51",
        "nova-novnc-proxy": "192.168.236.51",
        "nova-xvpvnc-proxy": "192.168.236.51",
        "swift-proxy": "192.168.236.51",
        "neutron-api": "192.168.236.51",
        "mysql-db": "192.168.236.52",
        "config": {
            "192.168.236.50": {
                "vrid": 1,
                "network": "public"
            },
            "192.168.236.51": {
                "vrid": 2,
                "network": "public"
            },
            "192.168.236.52": {
                "vrid": 3,
                "network": "public"
            }
        }
    },

Above is the __vips__ JSON block.

Inside the __vips__ JSON block are 22 attributes.

21 of the attributes contain the VIP, virtual IP address, for that particular
service. The 22nd attribute, __config__, contains all of the VIPs to be used,
what virtual router ID is tied to that VIP, and what __osops_network__ is
tied to that VIP, __public__ in this case.

By default Rackspace Private Cloud uses three VIPs: one for rabbitmq, a second
for mysql, and a third for the OpenStack services that need to be load balanced.
The OpenStack services that need to be load balanced can use the same VIP because
each service is listening on its own port. This three VIP setup allows mysql and
rabbitmq to run on their own servers while the OpenStack services need to all run 
on the same server.

The osops_networks JSON Block
-----------------------------

            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24",
                "neutron": "192.168.240.0/24"
            }
        }
    }

Above is the __osops_networks__ JSON block.

The __osops_networks__ JSON block has four attributes: __nova__, __public__,
__management__, and __neutron__. __nova__, __public__, and __management__ are
the three default attributes but, in this scenario, the __neutron__ attribute
 has been added. Additional attributes can also be added, such as __cinder__,
 for additional configuration.

The three default attributes, __nova__, __public__, and __management__, map
to specific OpenStack services and each attribute's value is expecting a
network subnet, not a specific IP address. When __chef-client__ is run on each
node, the Chef Cookbooks will search for a network interface assigned an IP
address within the specified network subnet. That IP address is then used as
the listening IP address for each OpenStack service mapped to that specific
attribute.

The __neutron__ attribute is not tied to any OpenStack services, and has been
added only so the GRE tunnels communicate on the __192.168.240.0/24__ network
and not the __192.168.236.0/24__ network which is assigned to the __nova__
attribute.

Below is a rough list of what services map to the default __nova__,
__public__, and __management__ attributes:

__rsyslog__ and __ntpd__ do not map to any attribute. __rsyslog__ binds 
to __0.0.0.0__ and __ntpd__ binds to all interfaces.

#### nova

The following services were found by running the following command on the Chef
Server (the command assumes the Chef Cookbooks are in root's home directory):

    fgrep -r '["network"] = "nova"' /root/chef-cookbooks

* keystone-admin-api
* nova-xvpvnc-proxy
* nova-novnc-proxy
* nova-novnc-server

#### public

The following services were found by running the following command on the Chef
Server (the command assumes the Chef Cookbooks are in root's home directory):

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
* neutron-api

#### management

The following services were found by running the following command on the Chef
Server (the command assumes the Chef Cookbooks are in root's home directory):

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

I have gone through two Chef Environment files that can be used to install
Rackspace Private Cloud v4.2.x powered by OpenStack Havana without Highly
Available services and with Highly Available services.

If you want to dive deeper, there are many other override attributes that can
be set in the Chef Environment file. You can see all the different attributes
that can be overridden by logging into your Chef Server (I am assuming the
Rackspace Private Cloud Chef Cookbooks are downloaded there), changing into
the __chef-cookbooks__ directory, changing into the particular Chef Cookbook
directory you want to change the default attributes of, changing into the
__attributes__ directory, and finally opening the __default.rb__ file.

For comments, feel free to get in touch with me [@jameswthorne](https://twitter.com/jameswthorne).
