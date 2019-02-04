---
layout: post
title: Protect your infrastructure servers with bastion hosts and isolated Cloud Networks
date: '2012-11-27 09:13'
comments: true
author: Brandon Philips
categories:
  - Cloud Networks
---
*This guest post was contributed by [Mr. Brandon Philips](http://www.linkedin.com/in/brandonphilips).
Brandon is part of a small team of Rackers getting the Rackspace Cloud Monitoring
Agent ready for launch. The Agent helps customers monitor the internals of their
servers and application. You can check out his site at <http://ifup.org>, find
him at local San Francisco meetups and check out his code on [Github](https://github.com/philips).*

The public internet can be a scary place for servers. Log files of servers
attached to public addresses shows regular port scans and URL snooping. These
log entries are the inescapable reminder that your hosts are always one
misconfiguration away from disaster.

This guide teaches you how to create a bastion host and an isolated cloud network,
so you can reduce the number of servers that have to encounter these threats.
<!-- more -->

And the best thing? With a bit of SSH magic, logging into these hosts is
completely transparent. SSH can take care of proxying connections through the
bastion host.

### Security Architecture

{% img center 2012-12-06-protect-your-infrastructure/arch.png %}

[Bastion hosts](https://en.wikipedia.org/wiki/Bastion_host) are simply a choke
point that provides access to the hosts behind it only to authorized users. A
bastion host serves the same purpose as a bouncer at a bar: like the bouncer the
bastion host checks everyone’s ID before they are allowed inside.

Using [Cloud Networks](http://docs.rackspace.com/servers/api/v2/cn-gettingstarted/content/ch_overview.html),
you can create Rackspace Cloud Servers that do not have a public IP and attach
to only an isolated Class A, B or C network that only your Cloud Servers can
talk to.

#### Building it out

First, let’s create our isolated cloud network, “Infrastructure Network”. Our
bastion host connects to both this network and the public network. Every other
host connects to the infrastructure network exclusively. Because I don’t need a
huge network space, I will create a small class C network in the 192.168.3.0 subnet.

Throughout this guide I will use the supernova command line client. See
[this article](http://docs.rackspace.com/servers/api/v2/cn-gettingstarted/content/section_gs_install_nova.html)
on configuration of supernova. You can also create this configuration using the
[Cloud Control Panel](https://mycloud.rackspace.com/).

	 $ supernova production network-create "Infrastructure" "192.168.3.0/24"
	 +----------+--------------------------------------+
	 | Property | Value                                |
	 +----------+--------------------------------------+
	 | id       | 014bb147-4455-450e-99bd-319f9c8430b1 |
	 | label    | Infrastructure                       |
	 | cidr     | 192.168.3.0/24                       |
	 +----------+--------------------------------------+

Next, let’s create our bastion host and attach it to this bastion network. You
specify the network using the nic flag and the UUID of the network that you can
find in the command output above.

Flavor 2 is for a 512MB cloud server, and the image UUID is for Ubuntu LTS 12.04.

	 $ supernova production boot bastion --flavor 2 --image 5cebb13a-f783-4f8c-8058-c4182c724ccd --nic net-id=014bb147-4455-450e-99bd-319f9c8430b1
	 +-------------------------+--------------------------------------+
	 | Property | Value                                               |
	 +-------------------------+--------------------------------------+
	 | flavor   | 512MB Standard Instance                             |
	 | image    | Ubuntu 12.04 LTS (Precise Pangolin)                 |
	 | name     | bastion                                             |
	 | status   | BUILD                                               |
	 +-------------------------+--------------------------------------+

After the build completes, all of our IP addresses are assigned. Great!

	 $ supernova production show bastion
	 +--------------------------------+-------------------------------+
	 | Property               | Value                                 |
	 +--------------------------------+-------------------------------+
	 | Infrastructure network | 192.168.3.1                           |
	 | public network         | 198.61.224.109                        |
	 +--------------------------------+-------------------------------+

Now, we can create a host that attaches only to the “Infrastructure” network.
Let’s call this server “safe.” Again, use the UUID for the network and also tell
Cloud Servers not to attach the server to the public internet or Rackspace’s
ServiceNet.

	 $ supernova production boot safe --flavor 2 --image 5cebb13a-f783-4f8c-8058-c4182c724ccd --nic net-id=014bb147-4455-450e-99bd-319f9c8430b1 --no-service-net --no-public

After a bit of waiting, our machine completes its build and is assigned a
private IP address. Now that we have the hosts built up, we can setup SSH to
transparently log us into our safe host via our bastion host.

	 $ supernova production show safe
	 +--------------------------------+-------------------------------+
	 | Property               | Value                                 |
	 +--------------------------------+-------------------------------+
	 | Infrastructure network | 192.168.3.2                           |
	 +--------------------------------+-------------------------------+

### Configuring SSH

SSH has a powerful configuration file format that lets you modify how SSH
behaves depending on the hostname you provide on the command line. Let’s look
at using some of those features including the `Hostname` and `ProxyCommand`
directives to make SSHing into our new environment easy.

First, instead of introducing the complexity of DNS to this article, let's use
host aliases in our `$HOME/.ssh/config` file. This lets us SSH to these newly
created hosts without specifying a user or IP, for example, `ssh bastion`

	Host bastion
	User root
	Hostname 198.61.224.109

	Host safe
	User root
	Hostname 192.168.3.2

Now you can get into the bastion host by running `ssh bastion`. However, trying
to `ssh safe` fails because your workstation won’t be able to route to the
private network. So, let’s tell ssh that it needs to proxy through the bastion
host to reach this host:

	Host safe
	User root
	Hostname 192.168.3.2
	ProxyCommand ssh -W %h:%p bastion

After making this modification, `ssh safe` drops you into the terminal of the
host. Awesome!

### Conclusion

Using this pattern of a bastion host and isolated network is great for a lot of
common uses:

* Setup Jenkins or Buildbot masters on the bastion and put all of the slaves on the “Infrastructure” network
* Protect database servers behind the public facing server that is running the web server
* Run your development environments in the cloud without concern for OS updates or firewall configuration

### Future Setup

These are the bare bones basics of setting up a bastion host. Here are some ideas on where to go next:

* Configure SSH keys to save typing two passwords in order to proxy through the bastion host
* Setup iptables to have bastion act as a NAT gateway so the safe host can download OS updates and packages
* Use a common DNS hostname pattern and glob matching in `.ssh/config` to make it easy to SSH into all machines behind the bastion host

Adding an isolated network to your cloud environment can simplify the
configuration of a strong security stance. And with a bit of configuration the
added security is mostly transparent to your day to day work.

Ready to get started? Cloud Networks is being rolled out to Rackspace Customers
now; you may already have access. If you don’t yet have access,
[sign up](https://www.iwantcloudnetworks.com/).
