---
layout: post
title: Using OpenStack to speed up your Chef tests
date: '2013-08-21 08:00'
comments: true
author: Ryan Richard
published: true
categories:
  - OpenStack
  - Chef
---

In today's configuration management landscape, the general motto is "infrastructure
as code", and as good [devopsians](http://www.youtube.com/watch?v=Md1MDHroXGU),
we should be testing our code. This blog post takes a look at test-kitchen +
OpenStack to make your life of testing chef cookbooks easier, faster and fun.

<!-- more -->

**Warning:** test-kitchen is still in beta.

### test-kitchen

At ChefConf 2013, there was a lot of talk about testing your cookbooks. Up until
this point, there were many ways to approach testing, and no one main harness
stood out out. Enter [test-kitchen](https://github.com/opscode/test-kitchen),
which leverages [vagrant](http://www.vagrantup.com/) by default to provide a
simple and flexible test harness. Sprinkle a little [berkshelf](http://berkshelf.com/)
on top, and you've got magic.

For this post, I'll be replacing the default Vagrant driver with OpenStack.

### The setup

To get started, make sure you have the following gems installed on your machine
(see each site for specific install instructions):

**Note:** I'm using `test-kitchen 1.0.0.alpha.7` and `kitchen-openstack 0.4.0.`
At the time of this writing, [this issue](https://github.com/opscode/test-kitchen/commit/d1f3134181bce6467f21c00726c03d6c0ba43674)
causes problems with the OpenStack driver and `test-kitchen 1.0.0.beta.2`.

1. [test-kitchen](https://github.com/opscode/test-kitchen)
1. [kitchen-openstack](https://github.com/RoboticCheese/kitchen-openstack)
1. [berkshelf](https://github.com/RiotGames/berkshelf)

If you're looking to add support to an existing cookbook, follow the test-kitchen
and berkshelf instructions:

Next, we'll add a .kitchen.local.yml file in the root directory of your cookbook which will tell test-kitchen we want to boot instances on OpenStack instead of vagrant:


	 driver_plugin: openstack

	 platforms:
	 - name: ubuntu-12.04
  	 driver_config:
    	openstack_username: <%= ENV['OS_USERNAME'] %>
    	openstack_api_key:  <%= ENV['OS_PASSWORD'] %>
    	openstack_auth_url:  <%= "#{ENV['OS_AUTH_URL']}/tokens" %>
    	image_ref: <%= ENV['UBUNTU_1204'] %>
    	flavor_ref: 1
    	key_name: <%= ENV['KEY_NAME'] %>
    	public_key_path: <%= ENV['SSH_KEY_FILE'] %>
    	openstack_tenant: <%= ENV['OS_TENANT'] %>
    	username: ubuntu

We can leave the test suites in the standard **.kitchen.yml** file because
test-kitchen overrides the driver and platform sections when a **.kitchen.local.yml**
file is present.

You need SSH access to the instances from the machine that kicks off test-kitchen.
For me, this means connecting a VPN to the private cloud environment because my
instances have private IPs only.

### Performance

Let's compare performance of running the [chef-client](https://github.com/opscode-cookbooks/chef-client)
tests locally versus on my private cloud:

**Test:**

18 instances total during the "all tests" runs (9 Ubuntu 12.04, 9 CentOS 6.4),
512MB RAM, 1 cpu core per instance

{% img center 2013-08-20-using-openstack/test-kitchen-performance.png %}

In general, the private cloud is slightly faster but notice the considerable
improvement using the parallel flag. I am lucky to have a beefy laptop (8 cores,
16GB RAM, SSD), so I would expect the vagrant times to increase if local hardware
is not as performant. Newer versions of test-kitchen appear to run even faster.

If you need a lot of resources have a look into the public cloud providers for
test-kitchen like [kitchen-rackspace](https://github.com/RoboticCheese/kitchen-rackspace).

### Other benefits

 - Use the same images between engineers and dev/prod environments.
 - Don't have to ship images or store them locally.
 - Won't kill your workstation when running a bunch of VMs.
 - Admins get used to working with OpenStack and API driven infrastructure.
 - **Allows you to enforce testing by kicking off runs from jenkins for commits, etc**.
 - The use of a **.kitchen.local.yml** file means you can apply your specific
   driver without impacting a community cookbook. We use a separate branch for
   this and checkout the specific local file before starting the test.

In closing, I think it's apparent that running workloads on servers is better
than workstations. Who knew! But more importantly, the tools exist now to make
this a easy and fun experience. Writing the actual tests is still up to
[you](http://devopsreactions.tumblr.com/post/52368854242/writing-unit-tests) though.
For ideas on testing, the [chef-client](https://github.com/opscode-cookbooks/chef-client)
has both the standard [minitest](https://github.com/opscode-cookbooks/chef-client/tree/master/files/default/tests/minitest)
method and the newer
["testing cookbook within the main cookbook"](https://github.com/opscode-cookbooks/chef-client/tree/master/test/cookbooks/chef-client_test) method.

Good luck and start testing those cookbooks.
