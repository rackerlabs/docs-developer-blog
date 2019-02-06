---
layout: post
title: Rackspace Autoscale is now Open Source
date: '2013-06-12 12:39'
comments: true
author: Felix Sargent
published: true
categories:
  - Cloud Servers
  - Cloud Monitoring
---

Our Autoscale project -- codenamed **otter** -- is now open source.

Autoscale takes the work out of capacity planning, allowing [Rackspace Cloud Monitoring][1]
alerts or scheduled events to create and delete servers. Through the use of
webhooks, Autoscale can be integrated into countless deployment scenarios.

Why did we do this, you ask? Well, when [meeting with folks][2] in the OpenStack
community at PyCon earlier this year, we were deeply encouraged to share our code.
Then, a month later, [we were blown away][3] by the OpenStack Summit in Portland.
The Heat design sessions were an incredible example of the power and speed with
which open source communities can operate. We decided to open source Autoscale
so we can better communicate with the OpenStack Heat project, provide a real-world
example to inform future plans and help align all of our visions for how OpenStack
[might implement autoscaling in the future][4].

<!-- more -->

We invite you to [dive into our code][5], [check out our docs][6], and [ask questions][7].

### FAQ:

#### You've released the libraries, but is the product itself available for use by Rackspace customers?

We're finishing up integration with the rest of Rackspace services. We are
currently doing limited previews. If you're interested in trying out Autoscale,
we invite you to [complete this survey][8].

#### How can I build this?

Our interest in open sourcing the product was to enable transparency and
collaboration.The code we have shared in the repository does not include any of
our deployment scripts. We do have plans to make Autoscale easier to use outside
of the Rackspace infrastructure, so stay tuned! We also accept pull requests :-)

#### If I can't use this right now, why are you releasing it?

Rackspace is committed to open source software and developer communities.
Anything we have helped build that could be useful, now or in the future, we
want to put in your hands as soon as possible. We will be adding features and
making the software generally easier to use and we will also accept pull requests!

[1]: https://www.rackspace.com/cloud/monitoring/
[2]: http://technicae.cogitat.io/2013/04/autoscale-and-orchestration-heat-of.html
[3]: http://www.rackspace.com/blog/the-heat-is-on-for-autoscaling-at-openstack-summit-portland/
[4]: http://technicae.cogitat.io/2013/04/openstack-developer-summit-heat-followup.html
[5]: https://github.com/rackerlabs/otter
[6]: https://rackspace-autoscale.readthedocs.org/en/latest/
[7]: mailto:autoscale@rackspace.com
[8]: http://www.rackspace.com/blog/autoscale-survey-tell-us-what-you-want/