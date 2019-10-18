---
layout: post
title: Automating Rackspace Cloud with Ansible
date: '2014-01-27 13:00'
comments: true
author: Michael DeHaan
published: true
categories:
  - Ansible
  - automation
  - devops
  - configuration management
  - developers
  - python
  - orchestration
---


This is a guest post written by Michael DeHaan, CTO at
[AnsibleWorks](http://ansible.com).
AnsibleWorks provides IT orchestration solutions that simplify the way
IT manages systems, applications, and infrastructure.

A while back I wrote about
[Ansible](https://developer.rackspace.com/blog/automate-with-ansible.html)
as a way to simply automate IT infrastructure, and showed how to achieve
some interesting zero-downtime rolling update capabilities.

<!-- more -->

In conjunction with several folks at Rackspace, we now have a lot of quality
modules (and more pull requests underwway) for adding in additional
functionality -- both cloud provisioning, managing Rackspace Cloud load
balancers, and creating new networks.  Those interested should check out
the [Rackspace Cloud Guide](http://docs.ansible.com/guide_rax.html).

What's nice about these modules is they not only bring up new instances --
but allow them to be fully configured at the end of the process, and
repeatedly managed over time.

It's been a very fun time in Ansible land lately, as Ansible is now a top
10 Python project on GitHub in terms of both forks and stars, and it gains a
new contributor every one to two days. At Rackspace, Ansible is helping to
manage customer environments as well as to help orchestrate OpenStack
deployment in production, whole datacenters at a time -- and we're very
thankful for contributions from the likes of Matt Martz (who wrote a large
part of the above guide), Paul Durivage, Jesse Keating (responsible for a
lot of tuning and testing help!), Christopher Laco, and others.

If you are using Rackspace Cloud -- Ansible may be a very very good fit for
you.  Because SSH is cloud native, all you need to do to manage a guest is to
inject an SSH key, which the Ansible modules can help with, and you can begin
managing cloud instances without installing any additional software.  When
it's not managing things, there are no extra daemons running, and you'll have
all of your CPU capacity for the tasks that matter most to you. Additionally,
there are no extra processes to babysit, or ports to open.

In the coming months, look for even more improvements to the Rackspace Cloud modules!

Check us out on github at
[github.com/ansible/ansible](http://github.com/ansible/ansible) and you can
also follow us on twitter at [@ansible](http://twitter.com/ansible).
