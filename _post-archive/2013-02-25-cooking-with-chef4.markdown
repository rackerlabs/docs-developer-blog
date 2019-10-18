---
layout: post
title: How Rackspace uses Chef to deploy OpenStack in the Private Cloud
date: '2013-02-25 08:00'
comments: true
author: Ryan Richard
categories:
  - OpenStack
  - Chef
  - Private Cloud
---
{% img right 2013-01-09-cooking-with-chef/chef_logo.png "Chef Logo" %}

_This is a guest post from Ryan Richard. Ryan is an OpenStack Engineer for [Rackspace Private Cloud](https://www.rackspace.com/cloud/private/) and is a Red Hat Certified Architect. He has been at Rackspace for almost 6 years and has been working on OpenStack for one year. His current role involves in designing, deploying and supporting OpenStack based private clouds inside and outside of Rackspace data centers. You can follow him on twitter: [@rackninja](https://twitter.com/rackninja)._

Following Hart's previous blog posts, [Cooking With Chef](https://devops.rackspace.com/cooking-with-chef.html),  I am going to describe how Rackspace leverages Chef to deploy our [Private Cloud Software](https://www.rackspace.com/cloud/private/openstack_software/) called Alamo.
<!-- more -->
## What does it all mean?

Hart mentioned the major terms associated with Chef in Part 1. Here is how these relate to to our Private Cloud deployments:

* *Nodes* - All physical servers (Controller(s), Compute, Cinder, Swift, etc) are Nodes.
* *Environments* - An environment is one OpenStack "Cluster". Think of a cluster as one self contained OpenStack instance that includes at least 1 controller and 1 compute node. Everything needed to have an operation OpenStack Private Cloud.
* *Roles* - We primarily use the 2 roles: single-controller and single-compute but many more exist. More on this later.
* *Cookbooks* - Our cookbooks contain all the logic to install and configure OpenStack based on our best practices. More on this later.
* *Data Bags* - Currently we do not use data bags for our environments.
* *Knife* - We set up knife on the controller node so that we can interact with the chef server from a consistent place.

Speaking of the chef server, we do something slightly different than Hart's post regarding where the running cookbooks are stored. We deploy a small KVM based virtual machine that has the open source version of Chef server installed. This virtual machine runs on the controller node as opposed to using Managed Chef or Hosted Chef. We chose this direction because anyone can use our software and it's unknown what sort of access control they have in place for traffic leaving their datacenter. Also we can always be certain where the cookbooks are located in any environment.

## Example Environment

Next, lets have a look at a Chef *Environment* from a running controller in our lab: 
(NOTE: this is a lab so attributes may differ than ones set by standard Alamo install)

`root@infra01:~# knife environment show rpcs -F json`

```json
{
  "override_attributes": {
    "nova": {
      "networks": [
        {
          "bridge": "br0",
          "label": "public",
          "network_size": "510",
          "num_networks": "1",
          "dns2": "8.8.4.4",
          "dns1": "8.8.8.8",
          "ipv4_cidr": "10.241.0.0/23",
          "bridge_dev": "eth0"
        }
      ],
      "config": {
        "allow_same_net_traffic": false,
        "start_guests_on_host_boot": false,
        "cpu_allocation_ratio": 16,
        "use_single_default_gateway": false,
        "resume_guests_state_on_host_boot": false,
        "ram_allocation_ratio": 2
      },
      "network": {
        "multi_host": true,
        "public_interface": "br0",
        "fixed_range": "10.241.0.0/23"
      },
      "services": {
        "novnc": {
          "network": "management"
        },
        "novnc-server": {
          "network": "nova"
        }
      }
    },
    "developer_mode": false,
    "glance": {
      "api": {
      },
      "images": [
        "cirros",
        "precise"
      ],
      "image_upload": false
    },
    "osops_networks": {
      "nova": "10.240.0.0/24",
      "management": "10.240.0.0/24",
      "public": "10.240.0.0/24"
    },
    "osops": {
      "apply_patches": true
    },
    "mysql": {
      "tunable": {
        "log_queries_not_using_index": false
      }
    },
    "apache": {
      "listen_ports": [
        "80",
        "443"
      ]
    }
  },
  "name": "rpcs",
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "cookbook_versions": {
  },
  "description": "",
  "default_attributes": {
    "monitoring": {
      "metric_provider": "collectd",
      "procmon_provider": "monit"
    },
    "horizon": {
      "theme": "Rackspace"
    },
    "mysql": {
      "allow_remote_root": true,
      "root_network_acl": "%"
    },
    "package_component": "folsom"
  }
}
```

Most Alamo installations will look similar to the environment above except the network sections which will differ from deployment to deployment. Beyond what's shown above there are a lot of attributes being set as defaults. I won't go through each attribute but if you're interested you can see them on [GitHub](https://github.com/rcbops-cookbooks). The Nova cookbook attributes for Alamo are [here](https://github.com/rcbops-cookbooks/nova/blob/acc795edd19d0865276adef3fb672959d8050aa3/attributes/default.rb).

Some interesting attributes we set:

* *"osops_networks"* - These networks allow us to separate OpenStack services from management services. Currently they are all set to the same network which is common.
* *"nova""networks"* - This is the fixed network that gets created by nova-manage and is where each instance will get it's IP from.
* *"package-component"* - Specifies whether to install Essex-final or Folsom. Soon Grizzly will be added to this list after it's released.

***
## Roles

Let's jump over to the roles. The following is a list of roles we provide:

	root@infra01:~# knife role list
	  allinone
	  base
	  cinder-all
	  cinder-api
	  cinder-scheduler
	  cinder-setup
	  cinder-volume
	  collectd-client
	  collectd-server
	  glance
	  glance-api
	  glance-registry
	  graphite
	  ha-controller
	  haproxy
	  horizon-server
	  jenkins-allinone
	  jenkins-compute
	  jenkins-controller
	  jenkins-glance
	  jenkins-mysql-master
	  jenkins-nova-api
	  keystone
	  keystone-api
	  mysql-master
	  nova-api
	  nova-api-ec2
	  nova-api-os-compute
	  nova-cert
	  nova-controller
	  nova-misc-services
	  nova-scheduler
	  nova-setup
	  nova-vncproxy
	  nova-volume
	  rabbitmq-server
	  rsyslog-client
	  rsyslog-server
	  single-compute
	  single-controller
	  single-controller-cinder
	  swift-account-server
	  swift-all-in-one
	  swift-container-server
	  swift-management-server
	  swift-object-server
	  swift-proxy-server

That's quite a list but we're mostly concerned with the single-controller and single-compute roles at the moment. *single-controller* is comprised of a number of other individual roles:

    root@infra01:~# knife role show single-controller
    chef_type:            role
    default_attributes:
    description:          Nova Controller (non-HA)
    env_run_lists:
	json_class:           Chef::Role
	name:                 single-controller
	override_attributes:
	run_list:
	    role[base]
	    role[mysql-master]
	    role[rabbitmq-server]
	    role[keystone]
	    role[glance-registry]
	    role[glance-api]
	    role[nova-setup]
	    role[nova-scheduler]
	    role[nova-api-ec2]
	    role[nova-api-os-compute]
	    role[nova-volume]
	    role[nova-cert]
	    role[nova-vncproxy]
	    role[horizon-server]

The role expands to the following roles and recipes once deployed:

	Node Name:   infra01
	Environment: rpcs
	FQDN:        infra01
	IP:          sanitized
	Run List:    role[single-controller]
	Roles:       single-controller, base, mysql-master, rabbitmq-server, keystone, keystone-api, glance-setup, glance-registry, glance-api, nova-setup, nova-network-controller, nova-scheduler, nova-api-ec2, nova-api-os-compute, nova-volume, nova-cert, nova-vncproxy, horizon-server
	Recipes:     osops-utils::packages, openssh, ntp, sosreport, rsyslog::default, hardware, osops-utils::default, mysql-openstack::server, erlang::default, rabbitmq-openstack::server, keystone::server, keystone::keystone-api, glance::setup, glance::registry, glance::api, nova::nova-setup, nova-network::nova-controller, nova::scheduler, nova::api-ec2, nova::api-os-compute, nova::volume, nova::nova-cert, nova::vncproxy, mysql::client, mysql::ruby, horizon::server
	Platform:    ubuntu 12.04
	Tags:

These are the roles necessary to have a functioning OpenStack Controller. The reason why all these roles are separated is because at some point it may make sense to break out various roles onto different nodes. For instance if the single-controller isn't able to keep up with the workload, it may make sense to apply the mysql-master role to a different machine who's sole purpose is to run mysql while the other various controller functions (Dashboard, api, etc) remain on a separate node.

In the next installment of series I'll go into more detail about how we deploy with chef and dig further into a few of the cookbooks.

***
## Credit

I would like to give a big shout out to the Rackspace Private Cloud Software [Development team](https://github.com/rcbops?tab=members) who are consistently updating and adding new features to the cookbooks.
