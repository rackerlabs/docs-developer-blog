---
layout: post
title: 'Rackspace Private Cloud - Digging deeper into OpenCenter, high availability'
date: '2013-03-06 07:00'
comments: true
author: Kevin Jackson
categories:
  - Private Cloud
  - OpenStack
---
Today, we unveiled some key updates to [Rackspace Private Cloud](https://www.rackspace.com/cloud/private/), which improve the platform's capabilities. Here, we'll drill into some of the architecture and technology behind this latest update and focus on two key features: High Availability of OpenStack components including MySQL and RabbitMQ; and OpenCenter, the open source Rackspace Private Cloud management API and graphical user interface that includes a powerful command line to allow administrators to harness even more control over their environments.

<!-- more -->

Previous releases of [Rackspace Private Cloud Software](https://www.rackspace.com/cloud/private/openstack_software/) required a download of an ISO to be used for installs, and you were tied to a single operating system, namely Ubuntu. As part of this third software release, you can now choose to run on Ubuntu, RHEL and CentOS, meaning you are able to integrate this into your environment and your own package management deployment systems. This was a frequently requested feature, and we listened, ensuring you get full control of your Private Cloud within your data center.

OpenCenter is an intuitive and easy to use administration dashboard for defining, installing and managing your Rackspace Private Cloud infrastructure. Through a simple drag and drop interface, an administrator can deploy features and services of the Rackspace Private Cloud with ease. Once your environment has been defined, adding and removing nodes is as simple as dragging and clicking on the appropriate option within the dashboard. For the advanced user, a command line tool is available allowing you to administer the environment through the familiarity of the command line.

Rackspace Private Cloud requires three host machines to run the various system controllers: OpenCenter Server, Chef Server and Nova Controller. We have made it easy to try out our platform by giving you the option to install the Private Cloud on a single physical node running two virtual machines. Installation instructions can be found in the [How To Rackspace Private Cloud articles](https://support.rackspace.com/how-to/rackspace-private-cloud-documentation/).

![Private Cloud Architecture](http://ddf912383141a8d7bbe4-e053e711fc85de3290f121ef0f0e3a1f.r87.cf1.rackcdn.com/private-cloud-architecture.png)

The architecture is agent based. Existing Linux servers within your environment run an agent that reports back to the OpenCenter server. These servers then appear within the OpenCenter GUI, exposing the available commands and giving you centralized control of your environment.

Functioning alongside OpenCenter is Chef Server. Chef performs the tasks of managing the roles assigned to our nodes. This involves the installation and configuration of the packages associated with that role. For example, when a node has been designated as a Controller node within OpenCenter, numerous roles are assigned. For example, the role of the OpenStack Dashboard, Horizon, will be assigned to this node and will get all the components of Horizon installed and configured appropriately for use within the Rackspace Private Cloud environment. Management of roles from a central location within the environment allows the nodes in our infrastructure to be assigned roles as appropriate, which gives us a very flexible and dynamic environment while still retaining control and consistency.

The purpose of the Solver is to determine the most effective route to get a node from one state to another. It analyzes the current state and the desired state, and then looks through all of the functions it can perform, including execution of Chef cookbooks and configuration of various OpenStack services. It then determines which function should be executed and in what order.

OpenCenter executes what are known as Adventures, or solutions that comprise multiple actions that run in sequence and are created to manage common changes. For example, Adventures include the installation of the Chef Server, rebooting of nodes and patching the systems.

You are in full control of when and if upgrades are performed and you have the ability to perform these yourself through OpenCenter. Supporting hardware maintenance is done through OpenCenter by evacuating hosts from performing compute functions. This moves the instances running on that host to another compute host within your infrastructure, allowing you to upgrade, repair or retire that node from service – or equally re-assign it to some other function within your infrastructure.

Not only does OpenCenter make it very easy to install Rackspace Private Cloud, but creating your environment to be highly available is as simple as adding more nodes to the infrastructure. OpenCenter gives you the ability to create high availability for all Nova service components and APIs, Cinder, Glance and Keystone, as well as the scheduler, RabbitMQ and MySQL. HA functionality is powered by Keepalived and HAProxy.

High Availability is implemented when you create two Controller nodes in a Nova cluster. When the second node is created, it discovers the IP address of the first node and begins replication; in turn, when a Chef client runs on the first node, it discovers the second and begins replication.

Rackspace Private Cloud gives you the features and benefits to run a very robust, very reliable Private Cloud powered by OpenStack in your own data center, or managed within Rackspace’s highly available data centers. When you install Rackspace Private Cloud, you benefit from the power of OpenStack, Rackspace's long-standing expertise at running clouds at scale and our award-winning Fanatical Support. Through the innovative new management interface, OpenCenter, managing your Rackspace Private Cloud is simple; adding in resiliency of your OpenStack Controllers becomes child’s play; and adding nodes is as easy as dragging and dropping. With Rackspace’s commitment to choice of Linux platform, you are in full control of your own Private Cloud, which gives you all the features and benefits you expect from running OpenStack.

_Kevin Jackson, the author of [OpenStack Cloud Computing Cookbook](http://www.barnesandnoble.com/w/openstack-cloud-computing-cookbook-kevin-jackson/1109250507), is part of the Rackspace Private Cloud Team and focuses on assisting Enterprises to deploy and manage their Private Cloud infrastructure. Kevin also spends his time conducting research and development with OpenStack, blogging and writing technical white papers._
