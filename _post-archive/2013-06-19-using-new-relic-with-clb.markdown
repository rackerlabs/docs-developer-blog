---
layout: post
title: Using New Relic with Rackspace Cloud Load Balancers
date: '2013-06-19 16:16'
comments: true
author: Jim Battenberg
published: true
categories: []
---
{% img right 2013-06-20-new-relic-clb/logo-new_relic.gif 200 %}
New Relic just released its “[New Relic Platform][1]” product consisting of more than 50 plugins from various ISVs and cloud companies.  The first Rackspace plugin to be released is for our Cloud Load Balancer product, which allows you to see HTTP vs. HTTPS traffic, easily set alerts to your predefined thresholds, and periodically check the health of the nodes associated with your load balancer to ensure they are responding correctly.

It’s pretty simple to try this yourself utilizing the README on GitHub, but I thought I’d walk through the basics and add few things to look out for.<!-- more -->:

##Install prerequsites

First, make sure that your system has the following components installed:

* ruby (version 1.8.7 for later)
* rubygems (version 1.3.7 or later)
* ruby bundler gem

**NOTE**: it does not matter where you load the agent. When configured properly it will see all load balancers set up in that particular region. I simply used Ubuntu 12.04 Cloud Servers.

##Install the plugin

Next, get the zip file from GitHub:

	wget https://github.com/newrelic-platform/newrelic_rackspace_load_balancers_plugin/archive/1.0.0.zip

Extract the contents into a directory of your choice.

Next, run a few commands from within this director to get the gem set up:

	bundle install –binstubs
	./bin/newrelic_rs --sample-config

Modify the `config/newrelic_plugin.yml` with your New Relic key, Rackspace username and API key, and the region in which your load balancer sits. [Here][5] is a good site for YAML parsing help.

**NOTE**: It is crucial to use lowercase for the region – it will not work otherwise. If you have load balancers in multiple regions, you will need to configure a separate plugin per region.

Start the agent: `./bin/newrelic_rs`. The correct output here should say “gathering xx statistics”

Now you can log in to your New Relic account and you’ll see the Rackspace Cloud Load Balancer icon in the left navigation pane. Once there you will see your load balancer(s) and you can view traffic, configure alerts, and you are good to go!

Click [here][2] to start using the plugin today and keep an eye out for more Rackspace plugins that are currently under development.

I’ll post again once the next plugin is available so feel free to follow me on [twitter][3] or [LinkedIn][4].

---

This is a post written and contributed by Jim Battenberg. Jim is a Cloud Evangelist for The Rackspace Cloud. His time in “the cloud” dates back to the late 90’s when the shared hosting, dedicated hosting and ASP markets first began implementing the core concepts of virtualization. During his nearly 20 years in the high-tech industry, his primary roles – spanning from startups to Fortune 50 companies – have been in the fields of Product Marketing, Product Management, Strategic Planning, Strategic Marketing, Corporate Communications IR/PR/AR/PA and Business Development. Jim holds both a BBA in Finance and an MBA in International Marketing from the University of Houston. Jim also likes yoga, poker and dubstep…and sometimes combines all 3! Follow him on twitter at [@jimbattenberg][3] or [LinkedIn][4].

[1]: https://www.newrelic.com/platform
[2]: https://newrelic.com/plugins/rackspace/91
[3]: https://twitter.com/jimbattenberg
[4]: https://www.linkedin.com/in/jimbattenberg
[5]: https://yaml-online-parser.appspot.com/