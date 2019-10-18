---
layout: post
title: OpenStack Heat Orchestration coming to Rackspace
date: '2013-10-30 11:11'
comments: true
author: Chris Spencer
published: true
categories:
  - Automation
  - Orchestration
  - OpenStack
---

In the spirit of both furthering our position within the [OpenStack](http://www.openstack.org) cloud arena
and making your life in the cloud much easier, Rackspace is excited to announce
that over the next few months we will be expanding our capabilities around
automating the orchestration of customers’ resource provisioning and application
deployment.

In April, we joined forces with the OpenStack [Heat](https://wiki.openstack.org/wiki/Heat) Orchestration
community to help round out the capabilities of the Heat project with the
intent to extend the benefits of Heat Orchestration to Rackspace customers.

<!-- more -->

Now, we are pleased to say that our efforts are nearing a point where users
can use [Heat](https://wiki.openstack.org/wiki/Heat) Orchestration to:

* Automate the provisioning and software installation and configuration management
* Manage the lifecycle of your application or environment with scaling, monitoring and resource management
* Easily codify your configurations across various QE, Dev and Production environments
* Launch from a catalog of existing applications or frameworks
* Build stacks from pre-existing CloudFormation templates

What, you ask, is Orchestration? Orchestration entails both the automation of
cloud resource provisioning AND application and software installation using a
template-based solution. The [OpenStack Heat](https://wiki.openstack.org/wiki/Heat)
 project has created its own template syntax, called the Heat Orchestration
 Syntax, or HOT syntax.  Pun intended.

There are several advantages to what Heat will bring to users at Rackspace:

* A Public API for customers seeking to automate complex and repetitive tasks
* An Open, portable Orchestration Template Syntax (HOT)
* Gives customers ability to write, edit and manage their own templates
* Templates are portable between OpenStack clouds, including both Public and Private Clouds at Rackspace
* Additional interoperability through Rackspace resources such as Auto Scaling and Monitoring


Heat will allow the template author to inject scripts into the resource user
data section, or choose to use a configuration management tool.  Heat is
flexible and agnostic to software configuration suites such as Chef, Puppet,
Ansible or Salt.  Heat templates integrate well with configuration management
tools, and will allow users to select their solution of choice in the very
near future.

Over the next few weeks, we will be rolling out an early access release of
the Heat API and early user interface.  Shortly following, we plan to make
the API generally available and then roll out Heat template and engine
support through our Rackspace Control Panel.  This will allow you to access
the API, as well as view, modify and create your own Heat Templates for your
customized needs.

We are seeking early access users to start using and providing feedback for
this solution as soon as possible. Please [signup](https://rackspace.qualtrics.com/SE/?SID=SV_cCIsIhNHEyymFZb)
to get on our early access list for Heat. If you're interested in signing up to
give it a test run, check out our [developer discount](https://developer.rackspace.com/devtrial/)!

More information about Heat:

* [Heat Template Writing Guide](http://docs.openstack.org/developer/heat/template_guide/hot_guide.html)
* [Heat Template Specification](http://docs.openstack.org/developer/heat/template_guide/hot_spec.html)
* [https://wiki.openstack.org/wiki/Heat](https://wiki.openstack.org/wiki/Heat)

We want to enable you with the tools you need to do your job more effectively.


