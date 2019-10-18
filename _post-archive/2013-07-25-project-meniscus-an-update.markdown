---
layout: post
title: 'Project Meniscus: Logging as a service (update)'
date: '2013-07-25 08:00'
comments: true
author: Chad Lung
published: true
categories:
  - OpenStack
  - Python
---

It’s been a while since my
[last post](https://developer.rackspace.com/blog/introducing-project-meniscus-the-python-event-cloud-logging-service.html)
on [Project Meniscus](http://projectmeniscus.org), which is an open-source,
[Apache 2 Licensed](http://www.apache.org/licenses/LICENSE-2.0.html),
cloud-scale logging service that collects logging data from cloud servers and
services, makes the data easily searchable through
[ElasticSearch](http://www.elasticsearch.org/), and dispatches it into numerous
other data stores, including [MongoDB](http://www.mongodb.org/) and
[Hadoop](http://hadoop.apache.org/). Today, I want to update everyone about the
current status of the project and our future plans.

<!-- more -->

### Update

* Our session at the [OpenStack](http://openstack.org) Summit in Portland was a
success. Many interested people attended, and they asked great questions about
the project. We returned with some useful feedback. If you haven't already, check
out the video of our session [here](http://www.youtube.com/watch?v=1mi7N4tDKA4).

* Recently, the funding for the [Common Event Expression](http://cee.mitre.org/)
(CEE) organization was cut, which means that all work on CEE has stopped. With
that said, we don't see this change affecting our project.

* Several [supporting sub-projects](https://github.com/ProjectMeniscus/) have
been created to help the Meniscus effort, including [pywebhdfs](https://pypi.python.org/pypi/pywebhdfs)
(Python wrapper for the Hadoop WebHDFS Rest API) and [pylognorm](https://github.com/ProjectMeniscus/pylognorm)
(native Python bindings for liblognorm).

* We have changed our original architecture. Instead of using a pipeline pattern
with workers that act as HTTP and TCP heads, correlators, normalizers, storage,
and so on, we have combined those into one multi-worker. This change enables
easier deployment and more immediate project delivery and provides a less
challenging way to incorporate failover, such as what to do when the network
between the workers and the storage goes down.

{% img center 2013-07-25-project-mensicus-logging-as-a-service-update/updated-arch.png %}

* We've introduced some additional technologies like [Celery](http://www.celeryproject.org/)
to handle the distribution of incoming messages and processing.

* For authentication/authorization and rate limiting, we will use projects like
[Repose](http://openrepose.org) and possibly emerging projects like [pyrox](https://github.com/zinic/pyrox).

* We will allow any valid JSON logging messages via HTTP, including formats like
[GELF](http://www.graylog2.org/about/gelf).

* Currently we test on Python 2.7.x, but we plan to eventually support Python 3.3.x.

* We have continued to improve our continuous integration and continuous deployment
infrastructure so that our latest code changes can be easily built, tested, and
rolled out to our Meniscus grid. For integration testing, we've hooked up
[Cloud Cafe](https://github.com/stackforge/cloudcafe).

* Although we haven't begun the code yet, we plan to work on alerting logic, a
well as to the ability to have our coordinator workers scale the Meniscus grid
as needed.

* We continue to pursue inclusion in [OpenStack](http://openstack.org).

* We have put [a lot of effort](https://github.com/ProjectMeniscus/chef-cookbooks)
into automating our deployments via tools like [Chef](http://www.opscode.com/chef/).

* We are now in the process of brining on our first internal customer for our
first round of alpha testing.

* Stay tuned to our [wiki](https://github.com/ProjectMeniscus/meniscus/wiki) for
updated documentation as well as an upcoming article on getting Meniscus installed
on a single computer (for testing and development purposes).

### What about Logstash?

We often are asked why we didn't just use [Logstash](http://logstash.net/). Good
question! Although Logstash is a well established and trusted project, and is a
great solution for many companies and individuals, internal testing by our
operations team found that it didn't handle certain loads. Second, because the
Project Meniscus team has a goal of producing a solution that can handle massive
amounts of data (two terabytes per day) and be a project that OpenStack can use,
this (currently) means writing the project in [Python](http://python.org)
(Logstash is written in JRuby). Additionally, we need a solution that handles
multiple tenants or customers. Stated simply, we had certain criteria that we
had to meet, which meant we had to develop an alternative to what is currently
available.

We did evaluate several other logging solutions initially but none filled our
particular criteria.

Feel free the [browse the code](https://github.com/ProjectMeniscus/) and remember,
pull requests are welcome.

### About the author

_Chad Lung is a software engineer on the Rackspace Cloud Integration team and is
currently working on [Project Meniscus](http://projectmeniscus.org). Be sure to
check out his personal blog at
[http://www.giantflyingsaucer.com/blog/](http://www.giantflyingsaucer.com/blog/)
and follow [@chadlung](https://twitter.com/chadlung) on Twitter._
