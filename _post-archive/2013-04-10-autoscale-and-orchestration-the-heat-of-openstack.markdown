---
layout: post
title: 'Autoscale and Orchestration: the Heat of OpenStack'
date: '2013-04-11 12:00'
comments: true
author: Duncan McGreggor
published: true
categories:
  - OpenStack
  - Configuration Management
---
Several months before I joined Rackspace last year, there were efforts under
way to provide an Autoscaling solution for Rackspace customers. Features that
we needed in OpenStack and Heat hadn't been released yet, and there were no
OpenStack experts on the Autoscaling team. As such, the engineers began
developing a product that met Rackspace customer needs, integrated with the
existing monitoring and load-balancing infrastructure, and made calls to
OpenStack Nova APIs as part of the scaling up and down process.<!-- more -->

At PyCon this year,
<a href="https://github.com/emonty">Monty Taylor</a>,
<a href="https://launchpad.net/~lifeless">Robert Collins</a>,
<a href="https://fewbar.com/">Clint Byrum</a>,
<a href="https://www.linkedin.com/in/devanandavdv">Devananda van der Veen</a>,
and I caught up and chatted about what their views were of the
current status of autoscaling support in OpenStack Heat. It seems that the two
pieces we need the most -- LBaas and support for external monitoring systems
(perhaps via webhooks) -- are nascent and not ready for prime-time yet.
Regardless, Monty and his team encouraged us to dive into Heat, contribute
patches, and in general, release our work for consumption by other Stackers.

Quick aside: OpenStack <a href="https://wiki.openstack.org/wiki/Heat">Heat</a>
is a service to orchestrate multiple composite cloud applications using the AWS
CloudFormation template format, through both an OpenStack-native ReST API and a
CloudFormation-compatible Query API. Heat has gained a lot of traction in the
last year and already has well over 1000 commits in its
<a href="https://github.com/openstack/heat/">repo</a>.

Deeply encouraged by these interactions, we took this information to Rackspace
management and, to quote Monty Python, there was much rejoicing. Obviously
OpenStack is huge for Rackspace. Even more, there is a lot of excitement about
Heat, the existing autoscaling features in OpenStack, and getting our engineers
involved and contributing to these efforts.

In the course of these conversations, we discovered that Heat was getting lots
of attention internally. It turns out that another internal Rackspace project
had been doing something pretty cool: they were experimenting with the
development of a portable syntax for application description and deployment
orchestration. Their work had started to converge on some of the functionality
provided by Heat, and they had a similar experience as the Autoscaling team.
The timing was right to contribute what they have learned and align all of
their continued efforts with adding value to Heat.

Along these lines, we are building
<a href="https://lists.openstack.org/pipermail/openstack-dev/2013-April/007126.html">two new teams</a>
that will focus on Heat development: one contributing to features related to
autoscaling (not necessarily limited to Heat) and the other contributing to the
ongoing conversations regarding the separation of concerns between
orchestration and configuration management. Everyone -- from engineers to
management -- is very excited about this new direction in which our teams are
moving. Not only will it bring new developers to OpenStack, but it is aligning
our teams with Rackspace's OpenStack roots and the company's vision for
supporting the growing cloud community.

Simply put: we're pretty damned pumped and looking forward to more good times
with OpenStack :-)
