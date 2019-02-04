---
layout: post
title: Deploying Rackspace Private Cloud software on Bare Metal
date: '2013-02-22 08:00'
comments: true
author: Egle Sigler
categories:
  - Private Cloud
  - OpenStack
  - Chef
---
_Egle Sigler is a Private Cloud Architect, who started working at Rackspace in 2008. She was one of the first to receive Rackspace OpenStack certification. Before working with OpenStack, Egle worked on MyRackspace customer control panel, software architecture and enterprise tools. In her spare time, Egle enjoys traveling, hiking, snorkeling and nature photography._

No matter how “cloudy” your environment and processes are, at the end of the day they still need to run on physical infrastructure. Traditionally, physical infrastructure is static in nature and time consuming to work with for a number of reasons. When we were building out the next-generation development and testing platform for [Rackspace Private Cloud Software](http://www.rackspace.com/cloud/private/openstack_software/), we found ourselves face to face with the issues caused by constantly provisioning infrastructure.

<!-- more -->

That is, we needed to have a number of environments constantly in flux. Specifically, we needed three for development, four for staging and two for bug fixes. The constant recycling of the physical infrastructure was fraught with time consuming, resource draining issues and discrepancies. In the end this made troubleshooting and automated testing difficult and threatened deadlines.

To solve this issue, the Rackspace Private Cloud Certification team sought out and tested a number of bare metal provisioning tools. While there are a number of excellent tools on the market, none seemed to fit quite well. On one hand, some tools were all-encompassing in scope and would try to provide an end-to-end solution. On the other hand, tools were too narrow in scope and provided a solution for a specific operating system or did not provide an appropriate amount of flexibility.

Eventually, we picked a deployment model consisting of a combination of tools that would provide the right balance of features and flexibility. We chose the Razor provisioning engine, combined with the OpsCode Chef configuration management tool. After submitting a few patches, we now have a flexible and automated way to deploy and manage the physical layer of our private clouds.

{% img center 2013-02-14-deploying-rackspace-private-cloud-software-on-bare-metal/razor.png "Razor Process" %}

What makes this deployment model great is that one tool is not trying to solve all the issues. In our case, a simple workflow would include Razor discovering hardware, installing an operating system and handing the environment off to Chef. The Chef broker simply installs the Chef client and executes the initial list of server roles, such as "web server" or "database server." With Razor tracking all your physical assets, it is easy to then repurpose that infrastructure to another role using the same workflow. An added benefit of this model is that due to the loosely coupled design of the deployment system, it is very easy to change any of components. For example, it is trivial to substitute Chef with Puppet.


