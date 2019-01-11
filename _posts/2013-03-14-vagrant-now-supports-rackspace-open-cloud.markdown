---
layout: post
title: Vagrant now supports Rackspace Open Cloud
date: '2013-03-14  08:00'
comments: true
author: Tomaz Muraus
categories: []
---
We are happy to announce support for Rackspace Open Cloud in [Vagrant 1.1](http://www.vagrantup.com/)!

Vagrant is a Ruby-based tool for building and deploying virtualized development
environments. Developers love it because it allows them to easily create and
deploy reproducible development environments.

With Vagrant 1.1 and the new Rackspace driver you aren’t limited to your local
machine and VirtualBox anymore. You can now also run your development machines
on Rackspace Open Cloud.

This allows you to utilize all of the
[benefits of Rackspace Cloud](http://www.rackspace.com/cloud/servers/compare/)
such as instances  with up to 30 GB of memory, virtual machine snapshots,
server resizing and more.

For a full list of improvements and other changes in Vagrant 1.1, please see the
[official announcement](http://www.hashicorp.com/blog/vagrant-1-1-and-vmware.html).

<!-- more -->

## Vagrant and Rackspace

We here at Rackspace are early adopters of Vagrant. Our first use dates back to
summer 2010 and a company called Cloudkick. Cloudkick was a San Francisco
based server management and monitoring startup that
[Rackspace acquired in late 2010](http://www.rackspace.com/blog/newsarticles/rackspace-acquires-cloudkick-to-provide-powerful-server-management-tools-for-the-cloud-computing-era/).

I was initially frustrated about how long it takes to set up a new development
environment at Cloudkick. The whole process was painful, error prone, included
many hacky bash scripts and polluted the developer machine with many different
libraries and files. Getting everything up, running and configured for the first
time could take up to three days.

One weekend during summer 2010 I decided to do something about it. I knew I
could reduce initial setup time if I could make the whole process more
repeatable and contained inside a virtual machine. The tool landscape back
then was a lot different so I decided to Google around and try to find a tool
which could help me with that. That’s when I found “Vagrant” and fell in
love with it. I managed to create our very first Chef-powered virtual machine
in less than a day. Keep in mind that at that time Cloudkick was a Puppet shop
and I had zero experience with Chef when starting to work on our Vagrant setup.

{% img center 2013-03-14-vagrant/logo_widecab47086.png "Vagrant project logo" %}

Our initial setup had many flaws and was far from perfect, but it still cut
down time from up to three days to a maximum of couple of hours. This was a
huge  improvement for several reasons. First it allowed new developers to
start contributing sooner. Second, it reduced the overhead of switching
machines for seasoned developers.

After seeing how much vagrant helped with that I became a big Vagrant advocate
inside Cloudkick and later on Rackspace.

Over the years we have learned a lot about Vagrant and other tools such as
Chef. We also had multiple other great people such as Brandon Philips and Phil
Kates work and immensely improve our Vagrant and Chef setup.

To this date we are still very proud and happy users of Vagrant and many
engineers couldn’t imagine life without it. Currently, it’s used by majority
of the product development teams inside the San Francisco office (including
[Cloud Monitoring](http://www.rackspace.com/cloud/monitoring/) and
[Service Registry](http://www.rackspace.com/blog/keep-track-of-your-services-and-applications-with-the-new-rackspace-service-registry/)).
We are excited about the Vagrant’s future and Vagrant 1.1 which brings
multiple provider support, including support for Rackspace Open Cloud provider.

Allowing developers to spin up their Vagrant virtual machines on Rackspace Open
Cloud will save even more time and make working from multiple computers easy
and flexible. More on that below.

## Why use Vagrant with Rackspace Open Cloud

First question you might ask yourself is why would you want to use Vagrant with
Rackspace Open Cloud when you can just run it on your local computer?

Here are several reasons for that:

### Flexibility

When you run a Vagrant virtual machine on your local computer you are tied to
that computer if you want to access things inside the virtual machine.

When you run Vagrant on the Rackspace Open Cloud you are not tied to your
computer anymore - you can access your development machine anywhere as long as
you have internet access and credentials which are required to log in to the
server.

Because Cloud servers accessible on the internet by default this means you can
share server credentials with your friends or fellow co-workers. This makes
debugging some type of problems a lot easier.

### Better resource utilization and bigger time savings

Running a virtual machine on your local computer can be pretty resource
intensive even with the new processors which support hardware virtualization
and VT-X instructions. With a Vagrant virtual machine on a Rackspace Cloud
server you can offload this work to the cloud and use local resources on your
computer for other things.

### Mobility

If you want to be mobile and own a small laptop / ultrabook you are usually
also pretty constrained CPU-speed and memory wise. If you run on Rackspace
Cloud you can create a virtual server with up to 30 GB of ram and up to 8
virtual cores. For example my relatively small and portable maxed out
Thinkpad X220 tops out at 16 GB of memory.

{% img center 2013-03-14-vagrant/tomaz_x220.png %}
<p style="text-align: center">Even with all those stickers on it there is a limit of how much memory I can
put in my X220. This limit is much higher in the Cloud.</p>

### Rackspace Cloud ensures a smooth ride

In the past while using Vagrant developers had quite a lot of problems related
to the VirtualBox hypervisor. Most of those problems were caused by bad kernel
modules and other bugs inside VirtualBox.

{% img center 2013-03-14-vagrant/openstacklogo512.png %}
<p style="text-align: center">Linux Rackspace Cloud Servers are powered by OpenStack and use battle tested XenServer hypervisor.</p>

When you run your Vagrant virtual machine on Rackspace Cloud you avoid this
class of problems all together.

## Getting Started

Here are quick instructions which show you how to get up and started with
Vagrant 1.1 and Rackspace Cloud provider. For more information and more
detailed instructions please have a look at the project’s
[README](https://github.com/mitchellh/vagrant-rackspace/blob/master/README.md)
and [Vagrant's documentation](http://docs-v1.vagrantup.com/v1/docs/index.html).

### 1. Download and install Vagrant 1.1

**NOTE: These instructions are out of date. Make sure you are using the latest version of Vagrant.**

Go to <http://downloads.vagrantup.com/tags/v1.1.0>, find an installer for your
operating system, download it and run it.

### 2. Install vagrant-rackspace Vagrant plugin

This plugin allows you to launch Vagrant virtual machines on Rackspace Cloud.

    $ vagrant plugin install vagrant-rackspace

### 3. Download and install the Rackspace dummy box

    $ vagrant box add dummy https://github.com/mitchellh/vagrant-rackspace/raw/master/dummy.box

### 4. Configurate Vagrantfile

Make a Vagrantfile which looks similar to the one below.

<script src="https://gist.github.com/Kami/5146027.js"></script>

Don’t forget to replace `rs.username` and `rs.api_key` with your Rackspace
Cloud API username and key. If you don’t yet have a Cloud account you can
create one at [https://cart.rackspace.com/cloud/](https://cart.rackspace.com/cloud/).

In this Vagrantfile example we use a Cloud server with 512 MB of memory (flavor
attribute), but you can specify an ID or a regular expression for a name of any
other size supported by Rackspace Cloud. You can find a list of all the available
sizes at
[http://www.rackspace.com/cloud/servers/techdetails/](http://www.rackspace.com/cloud/servers/techdetails/).

### 5. Start Vagrant instance on Rackspace Cloud

    $ vagrant up --provider=rackspace

Keep in mind that this step does a lot of work in the background (talks to
Rackspace Cloud Servers API, synchronizes Chef cookbooks, etc.) so it might
take a while to complete.

### 6. Success!

You are now running Vagrant virtual machine on Rackspace Cloud!

### Quick note about security

Vagrant will by default install a shared public key on the server. The private
key ships with the Vagrant source code which means everyone has access to it
and can login to your server if you don’t use a custom key.

You are strongly advised to use a different public and private key for
authenticating to your cloud servers. You can do so by setting the
`rs.public_key_path` and `config.ssh.private_key_path` attribute.

First attribute should point to a file relative to your Vagrantfile root
directory which contains a public key which will get installed on the server.
Second attribute should point to the private key pair of this key-pair.
This private key will then be used to authenticate to the server.

As a best practice, you are also advised to generate a new public/private key
pair which is only to authenticate to your Vagrant virtual machines.

## Conclusion

From the early Cloudkick to the current Rackspace days, Vagrant played and
still plays an important role in our developer toolbox. It allows our
developers to be more efficient and more easily create re-usable development
environments.

We have been very happy with the project progress over the years and today we
are especially excited about Vagrant 1.1 which among other things and
improvements brings support for different providers including Rackspace Cloud.

Now everyone can easily spin up their development images on our cloud and take
advantages of all the features of our cloud (server resizing, snaphots, etc.).

We look forward to Vagrant development in the future and wish Mitchel the best
with his
[recently launched HashiCorp](http://www.hashicorp.com/blog/announcing-hashicorp.html).

_This is a guest post from Tomaz Muraus. Tomaz is a Racker and a project lead for the Rackspace Service Registry product. He is also a project chair of [Apache Libcloud](http://libcloud.apache.org/), an open-source project which deals with cloud interoperability. Before working on Service Registry he worked on the [Cloud Monitoring](http://www.rackspace.com/cloud/monitoring/) product and before joining Rackspace, he worked at [Cloudkick](https://www.cloudkick.com/) helping customers manage and monitor their infrastructure. In his free time, he loves writing code, contributing to open-source projects, advocating for software freedom, going to the gym and cycling. Be sure to check out his GitHub [page](https://github.com/Kami)._
