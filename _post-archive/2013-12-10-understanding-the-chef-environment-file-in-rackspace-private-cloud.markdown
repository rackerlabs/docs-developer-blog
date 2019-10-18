---
layout: post
title: Understanding the Chef environment file in Rackspace Private Cloud
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

_A new post covering the Chef Environment file for Rackspace Private Cloud v4.2.x,
 including the highly available bits, can be found
 [here](https://developer.rackspace.com/blog/understanding-the-chef-environment-file-in-rackspace-private-cloud-v4-dot-2-x-powered-by-openstack-havana.html)._

<!-- more -->

### Typical Chef environments

Below are two typical Chef Environment files to install Rackspace Private
Cloud v4.1.x, one with nova-network and one with Quantum Networking.

The Chef Environment file differs slightly depending on which OpenStack
Networking model you chose.

In this scenario, each of the following Chef Environment files represent an
OpenStack environment where the controller and compute nodes each use three
network interfaces (eth0, eth1, and eth2).

**eth0** on each node is connected to a managed network switch as an *access*
port on a unique VLAN with network subnet **192.168.236.0/24**. The OpenStack APIs
and services listens on this network interface.

**eth1** on each node is connected to a managed network switch as an *access*
port. If you are using *nova-network*, the network interface is active but left
un-configured because Chef will configure it. If you are using *Quantum Networking*,
the network interface are on a unique VLAN with network subnet **192.168.240.0/24**.
OpenStack instances communicate on this network interface through GRE tunnels.

**eth2** on each node is also connected to a managed network switch but as a
*trunk* port containing all of the VLANs you want available in the OpenStack
environment. Depending on which OpenStack Networking model you use, nova-networks
or Quantum Provider Networks are created from these VLANs and communicate over
this network interface.

#### Rackspace Private Cloud v4.1.x using nova-network Chef environment file:

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

#### Rackspace Private Cloud v4.1.x using Quantum Networking Chef environment file:

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

#### The default JSON block

    {
        "name": "rpc-grizzly",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {}
    }

You would see the preceding block if you created a new Chef environment file
with the following command:

    knife environment create rpc-grizzly -d "Rackspace Private Cloud"

There isn't much going on here.

When using Rackspace Private Cloud, the `override_attributes` JSON block is the
main part to configure in the Chef Environment file. Inside this JSON block, you
override the default attributes already set in the Chef Cookbooks to match your
environment.

So, let's break down the various JSON blocks within the override_attributes
JSON block that apply to this scenario.

#### The nova JSON Block


Below are two different nova JSON blocks, one for nova-network and one for
Quantum Networking. One or the other will be used depending on which
OpenStack Networking model you want to use.

##### Using nova-network

The following example shows the nova JSON block, if you are using nova-network.

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

In our scenario, the nova JSON block has two JSON blocks: `network` and `networks`.

The network JSON block has two attributes: `provider` and `public_interface`.

The `provider` attribute specifies what OpenStack Networking model to use.
In this case, we use nova-network instead of Quantum Networking.

The `public_interface` attribute specifies the network interface on the
compute nodes that nova-network floating IP addresses are assigned to. This
parameter can be found in the **/etc/nova/nova.conf** file on the controller
and compute nodes.

Inside the `networks` JSON block is another JSON block called `public`.
The `networks` JSON block will accept two JSON blocks: a JSON block labeled
`public`, as shown above, and an optional JSON block labeled `private`.
The `public` and `private` JSON blocks are labeled this way because the
`public` JSON block is meant to setup a nova-network that allows outbound
network access from the OpenStack instances and the `private` JSON block is meant to
setup a nova-network that only allows instance-to-instance communication.
`public` and `private` are just labels, you could setup a private
network in the `public` JSON block or a public network in the `private`
JSON block. However, adhering to the intended convention will make everything
easier to understand. A more appropriate name for the `public` attribute would
be `fixed` because an OpenStack instance will always be assigned, or `"fixed"`, an
IP address from the nova-network you specified. In addition, the `public` attribute is
commonly confused with the `public` attribute in the `osops_networks` JSON block,
which you will read about later, and has no relation to it.

When the chef-client command is run on the compute node, it will use the
attributes in the `public` JSON block, and the `private` JSON block if
you set it up, to create a nova-network using the `nova-manage network create`
command. A Linux bridge interface named **br-eth1** is created and the physical
network interface, `eth1`, will be attached to it. In addition, a dnsmasq
process will be spawned serving IP addresses in the **192.168.100.0/24**
subnet from **192.168.168.100.2 - 192.168.100.254**; **192.168.100.1** is
skipped because this is usually the gateway IP address for the network
terminated on a router or firewall elsewhere in the network. OpenStack instances will have
their virtual network interfaces attached to the br-eth1 bridge interface
so they can communicate on the **192.168.100.0/24** network.

##### Using Quantum Networking

    "nova": {
        "network": {
            "provider": "quantum"
        }
    },

Above is the `nova` JSON block if you are using Quantum Networking.

The `nova` JSON block has one attribute: `network`.

Inside the `network` JSON block is one attribute: `provider`.

The `provider` attribute specifies what OpenStack Networking model to
use. The two possible values are `nova-network` and `quantum`, but
in this scenario `quantum` will be used. When using Quantum Networking,
there are additional configuration steps required after running
`chef-client` on each node. Some of these configuration steps are
mentioned in the following section.

##### The quantum JSON Block

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

Above is the `quantum` JSON block. This would only be in the Chef Environment
file if you are using Quantum Networking.

The `quantum` JSON block has one attribute: `ovs`.

Inside of the `ovs` JSON block are three attributes: `provider_networks`, `network_type`, and `network`.

The `provider_networks` attribute is an array and contains two attributes:
`label` and `bridge`. The `label` attribute contains a value that specifies
the name of a label which points to the Open vSwitch Bridge created in the
subsequent attribute, `bridge`.

The `bridge` attribute contains a value that specifies the name of the Open
vSwitch Bridge interface that the `ovs-vsctl add-br` command will create when
the `chef-client` command is run on each node. These attributes are found in
the **/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini** file on the
controller and compute nodes. As mentioned above, `eth2` is the network
interface that is connected to a managed network switch as a trunk port
containing all of the VLANs you want available in the OpenStack environment.
 `eth2` is connected to the `br-eth2` Open vSwitch Bridge by running
 `ovs-vsctl add-port br-eth2 eth2` on each node after `chef-client` is run.
 At this point, the `quantum net-create` command can be used to create Quantum
 Provider Networks for each VLAN in the trunk. OpenStack instances can then be
 attached to these Quantum Provider Networks.

The `network_type` attribute sets the default type of Quantum Tenant Network
created when it is not specified in the `quantum net-create` command. The different
types of Quantum Tenant Networks you can create are `gre` and `vlan`. Both
GRE and VLAN based Quantum Tenant Networks can be created and used at the same
time, but if you set `network_type` to `vlan`, `gre` Quantum Tenant Networks
cannot be created. This attribute is found in the
**/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini** file on the controller
and compute nodes.

By default, if GRE tunnels are used for Quantum traffic, each node's GRE tunnel
communicates on whatever network is assigned to the `nova` `osops_network`
attribute. In this scenario, the `nova` `osops_network` attribute is tied
to eth0 on each node. However, the Quantum traffic should be kept separate from
the traffic on eth0 and eth1 will be used. So, the `network` attribute has
been added to the `quantum` JSON block to point to the `quantum` `osops_network`
attribute which will configure the GRE tunnels to communicate on network
**192.168.240.0/24** on eth1 on each node.

##### The mysql JSON Block

    "mysql": {
        "allow_remote_root": true,
        "root_network_acl": "%"
    },

Above is the `mysql` JSON block.

The `mysql` JSON block has two attributes: `allow_remote_root` and `root_network_acl`.

The `allow_remote_root` attribute with a value of `true` allows remote root
connections to the MySQL service.

The `root_network_acl` attribute defines the network where the MySQL root user
can login from. With this attribute set to value `%`, which is a wild card in
MySQL, the MySQL root user can log into the mysql service from any host.

##### The osops_networks JSON Block

Below are two different `osops_networks` JSON blocks, one for `nova` and one for
`quantum`. One or the other is used depending on which OpenStack Networking model
you want to use.

The nova-network `osops_network` JSON block does not have the `quantum`
attribute because it does not need it.

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

The `osops_networks` JSON block has three default attributes: `nova`, `public`, and `management`.

If you are using Quantum Networking, the `quantum` attribute has been added.
Additional attributes can also be added, such as `cinder`, for additional
configuration.

The three default attributes, `nova`, `public`, and `management`, map to
specific OpenStack services and each attribute's value is expecting a network
subnet, not a specific IP address. When `chef-client` is run on each node, the
Chef Cookbooks search for a network interface assigned an IP address within the
specified network subnet. That IP address is then used as the listening IP address
for each OpenStack service mapped to that specific attribute.

The `quantum` attribute is not tied to any OpenStack services, and has been
added only so the GRE tunnels communicate on the `192.168.240.0/24` network
and not the `192.168.236.0/24` network which is assigned to the `nova`
attribute.

Below is a rough list of what services map to the default `nova`, `public`,
and `management` attributes:

`rsyslog` and `ntpd` do not map to any attribute. `rsyslog` binds
to **0.0.0.0** and `ntpd` binds to all interfaces.

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
* quantum-api

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

### Diving Deeper

I have gone through two typical Chef Environment files that can be used to
install Rackspace Private Cloud v4.1.x powered by OpenStack Grizzly with
nova-network and with Quantum Networking.

If you want to dive deeper, there are many other override attributes that can
be set in the Chef Environment file. You can see all the different attributes
that can be overridden by logging into your Chef Server (I am assuming the
Rackspace Private Cloud Chef Cookbooks are downloaded there), changing into
the `chef-cookbooks` directory, changing into the particular Chef Cookbook
directory you want to change the default attributes of, changing into the
`attributes` directory, and finally opening the `default.rb` file.

For comments, feel free to get in touch with me [@jameswthorne](https://twitter.com/jameswthorne).