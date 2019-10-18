---
layout: post
title: 'Introducing Project Meniscus: The Python Event Cloud Logging Service'
date: '2013-03-26 08:00'
comments: true
author: Chad Lung
categories:
  - OpenStack
  - Python
---

**Dream big:** that is our vision on the Rackspace [Project Meniscus](https://projectmeniscus.org) team. In one of our dreams, we
provide a top-tier Logging-as-a-Service (LAAS) solution for the cloud.
In another, we are accepted as an incubator project within
[OpenStack](https://openstack.org). These are lofty dreams, but we are a
focus-driven team, and our dreams are our goals.

Project Meniscus is a better focusing lens for system and application
events. It is completely open source ([Apache 2 License](https://www.apache.org/licenses/LICENSE-2.0.html)) and headed by
[John Hopper](https://github.com/zinic/), the original author of both
the [Repose](https://openrepose.org) and [Atom Hopper](https://atomhopper.org) projects. Both of these projects have
seen great success within Rackspace as well as adoption around the world
by many companies. These projects continue to move forward and benefit
from their initial startup as open- source projects; they also have been
proven to scale to the demands of the Cloud.

<!-- more -->

We are busy laying out the underlying architecture of how Meniscus will
work. The following diagram is an example of a high level overview. Be
sure to check out the latest documentation in the
[wiki](https://github.com/ProjectMeniscus/meniscus/wiki)!

{% img center 2013-03-15-introducing-project-meniscus-the-python-event-cloud-logging-service/proj-meniscus-arch.png %}
<p style="text-align: center">High Level Project Meniscus Architectural Overview</p>

Meniscus takes log data from servers, normalizes it, and saves it into a
data store; this enables customers to quickly locate log entries,
perform metrics, troubleshoot/debug, collect alerts, and much more. The
log data will eventually flow to a longer-term data store where it can
continue to be accessed and retained as needed by end users. The end
user can set data retention times on an as-needed basis. Event-logging
data traffic takes place through a secure transport layer.

When an individual or company deploys a cloud server they typically
store the log information locally. This becomes a burden when an issue
arises, and someone must dig through potential mountains of log data to
find perhaps one or two log entries. Non-rotated log files also have
been known to fill a server's disk capacity and impair the operating
system. In some cases, this has caused outages. Using the well-known and
trusted [Syslog](https://en.wikipedia.org/wiki/Syslog) standard, you can
simply point your log file traffic to Meniscus.

Meniscus will accept two types of log files: structured and
unstructured.

* Structured log files, are those generated in the [Common Event Expression](https://cee.mitre.org/) (CEE) format, which is being
developed by a community that is represented by vendor, researchers, end
users, and coordinated by [MITRE](https://mitre.org/). In their [own words](https://cee.mitre.org/about/faqs.html#a1): "The primary goal of
the effort is to standardize the representation and exchange of logs
from electronic systems". Given this format, Meniscus can provide rich
queries into your log files and provide large-scale feedback into your
data.

* Unstructured log format is supported, but provides less structured
search options than structured log data in the CEE format. The latest
versions of [Rsyslog](https://www.rsyslog.com/) and
[Syslog-NG](https://www.balabit.com/network-security/syslog-ng) both
support structured log data. CEE actually overlaps syslog a bit, making
the above statement true for any syslog implementation. The structured
data elements are new in the latest RFC which is why a newer syslog
implementation is required.

Meniscus is in early development, and much can change between now and
the production-ready release. We would love to see [outside contributions to the project](https://github.com/ProjectMeniscus/meniscus/). If you are
attending the [OpenStack Summit in Portland](https://www.openstack.org/summit/portland-2013/), we hope that
you will attend our [Project Meniscus session](https://openstacksummitapril2013.sched.org/event/25d55fb7629c5d88341354febb130f55#.UUkhGxiGs70).

_Chad Lung is a software engineer on the Rackspace Cloud Integration team and is currently working on [Project Meniscus](https://projectmeniscus.org). Be sure to check out his personal blog at [https://www.giantflyingsaucer.com/blog/](https://www.giantflyingsaucer.com/blog/) and follow [@chadlung](https://twitter.com/chadlung) on Twitter._
