---
comments: true
date: 2012-10-02T08:00:41.000Z
layout: post
title: 'Continuous Integration and Rackspace, part 3'
author: Jeff Ness
categories:
  - Cloud Servers
---

_This is part 3 of a series of using continuous integration with Rackspace. This is a guest post by Jeff Ness, a developer for the Rackspace RPM Development team.
_

Since 2006, the RPM Development Team has provided and maintained packages for the latest versions of PHP, MySQL and other common software on the Red Hat Enterprise Linux platform. Internally, we maintain a number of package sets for an audience of thousands of production servers. Until recently, these packages were only available internally to Rackspace customers. After a while we began thinking: Why not make this available publicly for everyone to benefit?

The [IUS Community Project](https://iuscommunity.org) is an Open Source community created by the RPM Development Team that aims to provide up to date and regularly maintained RPM packages for the latest upstream versions of PHP, Python, MySQL and other common software specifically for Red Hat Enterprise Linux. IUS can be thought of as a better way to upgrade RHEL -- when you need to.

<!-- more -->

#### The Problem


The team runs both internal and external RPM packaging and has a need for many automated task for doing all sorts of jobs. Some of these jobs consist of signing packages with the correct GPG key, pushing packages to a web accessible server and creating yum repositories. These jobs typically ran as cron, and ran on a number of servers and user accounts. The solution was not ideal for a number of reasons:

•    Lack of centralized monitoring.
•    No viable solution to review job output and job status.
•    Documentation on which server ran which job and with what account began to become unmanageable.


#### The Idea


The RPM Development Team recently adopted Jenkins into our workflow. We see Jenkins as an ideal tool for handling many of our automated tasks, and a simple way to centralize.


#### The Solution


In the current model, the RPM Development Team uses Jenkins to run many automated jobs. The jobs normally consist of Python code, but can be anything the machine is able to execute.

Originally, we had many scripts running across multiple servers and user accounts. This was a way to separate our internal roles from the external, and add security. In order to keep this method we took advantage of Jenkins node functionality.

Jenkins node functionality makes it simple to connect to external servers by means of the SSH protocol, this also allows us to connect as the appropriate user.

We have configured our nodes using the availability option, which means they are not constantly connected with SSH. Each of our node's availability is set to On Demand with a one minute 'In demand' and 'Idle' delay.

Our jobs are then configured to use 'Restrict where this project can be run,' which tells the project which node to run under.


#### Conclusion


The RPM Development Team is very impressed with the power and flexibility of Jenkins. As a new user of the application I can see us running many new projects in conjunction with Jenkins CI.
