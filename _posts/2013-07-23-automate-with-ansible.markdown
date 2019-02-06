---
layout: post
title: Automate application updates with Ansible
date: '2013-07-24 12:00'
comments: true
author: Michael DeHaan
published: true
categories:
  - Ansible
---

This is a guest post written by Michael DeHaan, CTO at [AnsibleWorks][1].
AnsibleWorks provides IT orchestration solutions that simplify the way IT manages
systems, applications, and infrastructure.

----

When developers and systems administrators work to automate the rollout of
application updates, a common problem is automating web and SaaS architectures
that span more than a single machine and, more importantly, managing those systems
in a way that preserves uptime. This is especially critical in high-traffic web
sites and services.

When looking at the automation modelling itself, it is insufficient to model the
actions that happen on one machine at a time, or even all classes of machines at
a time, because simultaneous updates can introduce outages.

<!-- more -->

Performing updates on live infrastructure is one of those problems that historically
results in your IT team locked in a conference room late at night or on a Saturday,
again and again, and it’s not a fun place to be. Not only is an arduous process,
but getting a step wrong means customers will experience problems (lost orders,
dropped connections, etc.).

Ansible is a configuration, app deployment and orchestration solution that provides
powerful tools to roll out multi-tier applications, on either physical or cloud
infrastructure. Ansible does that with a serverless, agentless solution (it just
uses SSH) that can finely control what order operations happen on what machines.
It’s also particularly good at multi-tier app rollout, and even more so at
implementing those vital rolling updates and making them more or less a *push button*
process.

Ansible makes this easy by having a push-based, explicitly ordered system that
can talk to one group of hosts, talk to another on behalf of others, and then
move on to other groups, to model all sorts of configuration, application
deployment and rollout processes.

As shown in our [ansible-examples][2] repository, here’s an example of what that
looks like for a simple HAProxy setup.

```
- hosts: webservers
  user: root
  serial: 1

  # These are the tasks to run before applying updates:
  pre_tasks:
    - name: disable nagios alerts for this host webserver service
      nagios: action=disable_alerts host={{ ansible_hostname }} services=webserver
      delegate_to: "{{ item }}"
       with_items: groups.monitoring

     - name: disable the server in haproxy
       shell: echo "disable server myapplb/{{ ansible_hostname }}" | socat stdio /var/lib/haproxy/stats
       delegate_to: "{{ item }}"
       with_items: groups.lbservers

     roles:
       - common
       - base-apache
       - web

     # These tasks run after the roles:
     post_tasks:
     - shell: echo "enable server myapplb/{{ ansible_hostname }}" | socat stdio /var/lib/haproxy/stats
       delegate_to: "{{ item }}"
       with_items: groups.lbservers

     - name: re-enable nagios alerts
       nagios: action=enable_alerts host={{ ansible_hostname }} services=webserver
       delegate_to: "{{ item }}"
      with_items: groups.monitoring
```

In the above example, we’re removing the node from a pool, signaling a monitoring
outage, updating it by applying three configuration roles and then putting it
back into the pool and monitoring system. Ansible is also smart and knows to
restart all the required services prior to putting them back in the pool, and
to stop the update if a batch of systems fails, leaving you with the rest of
your systems online.

The above example uses haproxy, but this can easily be extended to work with
other types of load balancers, whether physical or cloud based. While the above
example takes one node out of rotation at a time, if you had 500 servers and
wanted to take 50 out of rotation at a time, simply set serial to “50” and you
have a configurable rolling update policy. You can decide how much load capacity
you can handle in the middle of an update process. Some AnsibleWorks users use
this system to do continuous updates every 15 minutes, all day long.

Ansible can be used for things other than rolling updates, including configuration
management, more basic application rollout or running shell commands on remote
nodes. To learn more about Ansible, see our [documentation section][3] and be
sure to check us out on [GitHub][4]. There is also a free [two-hour quickstart][5]
training video.

Thanks and happy Ansibiling! I think that’s a word :)

[1]: http://ansibleworks.com/
[2]: https://github.com/ansible/ansible-examples
[3]: http://ansibleworks.com/docs/
[4]: https://github.com/ansible/ansible
[5]: http://www.ansibleworks.com/quickstart/
