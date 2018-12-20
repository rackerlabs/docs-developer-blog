---
layout: post
title: Using stackforge/os-ansible-deployment to review OpenStack Patches
date: '2015-05-29 23:59'
comments: true
author: Ian Cordasco
published: true
categories:
  - Ansible
  - Openstack
  - Private Cloud
---

As someone who works daily on libraries that power OpenStack, OpenStack
itself, and deployment strategies for OpenStack, it's nice to be able to
combine all of these roles when possible. As a core reviewer for the OpenStack
Image Service (Glance), it's crucial that I not simply review the code in the
a given change by eye but also test it to ensure:

- It doesn't introduce new bugs
- It fixes the bug, or provides the functionality, it claims to

Lately, I have been using the [os-ansible-deployment][] (a.k.a., OS-A-D) to
test changes that I review in OpenStack. This provides me with several
benefits.

1. Working on OS-A-D is my primary responsibility so the more I use it, the
   more familiar I become with it.

1. It deploys all of the OpenStack services similar to how Rackspace Private
   Cloud deploys them but on a single server instead of on hundreds.

1. It runs all of the services inside containers, so, if OpenStack is (at that
   point in time) not co-installable, it isn't a problem for my testing since
   I only care about testing how the patch works with the given service and
   other affected services, not that the dependencies of different services are
   incompatible.

1. It's easy to use Ansible to continuously redeploy a service inside a
   container (assuming you're already familiar with Ansible). All of that
   said, it isn't a complete replacement for DevStack. DevStack, used by the
   Jenkins jobs in OpenStack to ensure a patch will pass the gate, is also
   necessary. If you're developing a patch for OpenStack, Ansible becomes a
   bit more cumbersome than DevStack to use, especially since you need to
   worry about how DevStack interacts with your patch.

That aside, let's look at an example of how you might review a change with
OS-A-D with an example. I do all of my development on servers in Rackspace's
public cloud. Let's start by creating a new server:

```
$ nova boot --key-name my-key \
    --flavor performance2-15 \
    --image 8226139f-3804-4ad6-a461-97ee034b2005 \
    --poll osad-glance_store-review
```

We'll need a few things before we can start the OS-A-D playbooks:

```
# apt-get update
# apt-get install -y fail2ban tmux vim git
```

`tmux` is optional, but I tend to use it heavily in my development
environment. After everything finishes installing, I usually start up a tmux
session and do the following:

```
# git clone https://github.com/stackforge/os-ansible-deployment
/opt/os-ansible-deployment
# cd /opt/os-ansible-deployment
```

In here, we have a directory with vars for playbooks and a sub-directory with
vars that decide which versions to install of certain OpenStack services and
dependencies OS-A-D will install. In the example, I'm going to walk through
with you, we will be editing
`playbooks/vars/repo_packages/openstack_other.yml`. We'll want to update it to
read:

```yaml
glancestore_git_repo: https://github.com/sigmavirus24/glance_store
glancestore_git_install_branch: bug/1263067
```

In our example, we'll be testing out https://review.openstack.org/168507 from
`glance_store`. You'll notice we're pulling from my fork of `glance_store`.
This is largely due to the fact that OS-A-D is meant for deployments, and it's
unlikely anyone would deploy from Gerrit. So to test a change, I will happily
push it to my fork, since I usually check it out locally to review it anyway.
Once we've edited that, all we need to do is run
`./scripts/gate-check-commit.sh` and wait for it to build an all-in-one
version of OS-A-D. This will also run a subset of tempest's tests against the
AIO as well as defcore's tests. These should provide a good indication that
the AIO is functional.

If you want to check what version of `glance_store` we have installed, you can
do:

```
# ansible glance_all -m shell -a "pip freeze | grep store"
```

You can also do

```
# pip install -d . glance_store
```

This downloads the wheel that was built from the local package index. Now that
we have an functioning cloud, we can test the actual patch. But that's
something I'll leave as an exercise for the reader.

When you want to test your patch at scale, the best way to do it is with
[os-ansible-deployment][]. You can easily scale your test environment from one
machine to tens (or hundreds) of machines and ensure that everything works in
a production environment. It manages your dependencies for you, builds them
from source, and gives you a way to have a reproducible set of build artifacts
by giving you a private package index that you can reuse and clone for future
use.

[os-ansible-deployment]: https://github.com/stackforge/os-ansible-deployment
