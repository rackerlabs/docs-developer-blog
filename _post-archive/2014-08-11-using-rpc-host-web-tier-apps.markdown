---
layout: post
title: Using Rackspace Private Cloud to Host Your Web Tier Applications
date: '2014-08-11 14:00'
comments: true
author: James Thorne
published: true
categories:
  - openstack
  - private-cloud
---

Last week, I presented a live webinar on [why web tier applications are a good fit for Rackspace Private Cloud](https://youtu.be/mknyC4tccBQ).

The following post, the third of several in the [RPC Insights series](https://www.rackspace.com/blog/welcome-to-rpc-insights/), will be a summary of that live webinar. I will be covering why Rackspace Private Cloud is a great fit for your cloud ready web applications, why you may need to migrate your web application from a public cloud to a private cloud, discuss and provide a concept architecture of a cloudy web tier application, and discuss an overview of bursting into the Rackspace Public Cloud from your Rackspace Private Cloud.

<!-- more -->

For all of this to work, you need to understand and be able to use OpenStack in general. In the last webinar I demonstrated how to begin consuming your Rackspace Private Cloud environment through the Horizon Dashboard.

I showed you how to do such things as upload OpenStack Cloud Images to Glance, how to create Neutron Networks, and how to spin up your first OpenStack Instance. All of these things are necessary to begin using your OpenStack environment and ultimately deploy your applications on top of it all.

If you happened to miss the last webinar and are intersted in watching it, please go [here](https://developer.rackspace.com/blog/spinning-up-your-first-instance-on-rackspace-private-cloud/). There you will find a link to the recorded webinar as well as a blog post detailing how to do everything I demonstrated in the Horizon Dashboard using the OpenStack Python command line tools.

Why?
----

So, why are web tier applications such a good fit for cloud environments?

Web applications have traditionally been architected in a multi-tiered fashion. The first tier may be optional, depending on your use case, and would be a caching layer. The second, but possibly first tier, is the application or web tier. The code for your web application resides at this layer. The last layer is the database tier. The data your web application needs to store and retrieve lives at this layer.

All of these tiers could exist on one server, but if that one server failed everything would obviously go down with it. But, because of the tiers, each tier can be separated onto their own server. However, if one of the servers in one of the tiers fails, the web application isn't going to function, so you have to distribute the web application in a way that allows for various components to fail.

The caching and web tier are usually easy to distribute and horizontally scale. Simply add more servers, deploy your code, and put some sort of load balancing in front of it.

Traditionally, the database tier has been a bit more difficult.

Relational databases do not easily horizontally scale. As the web application grows there are going to be more and more reads and writes to the databases. The database tier can vertically scale only so far and there is going to be a point where horizontal scaling is required.

If your application requires a relational database, tools such as [Galera](https://galeracluster.com/) can help make horizontal scaling easier. Otherwise, you may need to re-write your web application to use some sort of NoSQL database like [Cassandra](https://cassandra.apache.org/) or [MongoDB](https://www.mongodb.org/).

The Narrative
-------------

So, let's build a narrative around this.

Your company has been running your web application on the Rackspace Public Cloud for some time without any issues.

However, as the web application has grown it is starting to make more sense to migrate the web application to a Rackspace Private Cloud.

What are some of the main factors contributing to the decision to move the web application from the Public Cloud to a Private Cloud?

### Cost

First, cost.

As you create and use more Cloud Servers in a public cloud there is a tipping point where it begins to make more sense from a cost perspective to use a private cloud. This tipping point is different for every public cloud and may depend on the types of Cloud Servers you are using.

A Rackspace Private Cloud has a fixed cost every month because you are paying for dedicated gear. As you create new OpenStack Instances in the Rackspace Private Cloud the cost will stay the same. The cost will only increase if you add more physical servers to your dedicated environment.

### Privacy and Security

Second, privacy and security.

As your web application has grown you have begun accepting and storing sensitive data. A public cloud is a multi-tenant environment and has security implications because your Cloud Servers and data are running next to other customer's Cloud Servers and data.

In Rackspace Private Cloud, your entire environment is running behind your dedicated firewalls on your dedicated gear. You are the only tenant on that gear and have complete control over it.

In addition, Rackspace Private Cloud is currently the only product at Rackspace that you can host in your own data center. So, if you have additional security requirements that keep you from hosting your servers at a third-party data center, you can just as well run Rackspace Private Cloud in your data center and have Rackspace help support it.

### Single-tenancy

Third, single-tenancy.

The Rackspace Public Cloud is a multi-tenant environment. Depending on the size of the flavor used for the Cloud Server, there could be many customers on the same compute node your Cloud Servers are running on.

What those other customers are doing within their Cloud Servers can affect the performance of your web application running on your Cloud Servers. This is called the noisy-neighbor affect.

Rackspace Private Cloud is a single-tenant environment. What you do within your Private Cloud is entirely up to you. No one else shares your environment and you can spread out and distribute OpenStack Instances in whatever way you wish so you do not negatively affect the performance of your applications.

### More Control

Fourth, more control.

Most public clouds come with prescribed flavors. You cannot create your own Cloud Server with a particular amount of vCPU, RAM, or storage. You can only select from what is available in the service catalog.

There are many situations where you need a Cloud Server with a lot of vCPUs but do not need all of the storage, or maybe you need a lot of RAM but not all of the vCPU. With a Rackspace Private Cloud environment you can create flavors exactly to your preference.

Being able to do this allows you to better distribute your OpenStack Instances so you can better utilize the compute nodes in your environment.

Deploying on Rackspace Private Cloud
------------------------------------

So, because of these four factors, the decision has been made to move the web application from the Rackspace Public Cloud to the Rackspace Private Cloud.

The following screenshot is from the Network Topology section of the Horizon Dashboard.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/horizon-network-topology.png horizon-network-topology %}

The configuration is similar to the last webinar, but I now have two software defined neteworks: one for the web tier and one for the database tier. Both of these networks are attached to the same software defined Neutron router so they can communicate with each other and for external connectivity. Neutron Security Groups can be used to ensure only the web tier can talk to the database tier.

What you see in the screenshot represents a web application running two tiers: the web tier and the database tier. The web tier is a Django application called Twissandra. Twissandra is a "hello world" application that has Twitter like functionality that uses Cassandra on the backend. You can begin playing with Twissandra by going to its [GitHub repository](https://github.com/twissandra/twissandra).

If Twissandra was the application that you had to scale then you could easily continue adding web frontend OpenStack Instances. As you need more storage you could also easily add OpenStack Instances to expand the Cassandra cluster.

To continue with our narrative, because this web application was running in the Public Cloud, there is a good chance you have been using configuration management tools to deploy and scale the application. Using tools such as Ansible, Chef, Puppet, or Salt will greatly increase your ability to easily scale your web application at a moment's notice. If you do not use these tools, or some other similar method, it is eventually going to become impossible to manage and scale your web application in a timely manner.

Bursting into the Rackspace Public Cloud
----------------------------------------

So, lets continue with our narrative but fast forward about a year.

You've been running your web application in the Rackspace Private Cloud successfully, but some of the factors above that required you to originally move from Rackspace Public Cloud to Rackspace Private Cloud have been removed and you can now leverage the Rackspace Public Cloud again. But, you don't want to just abandon the Rackspace Private Cloud. So, what you can do, if you host in a Rackspace data center, is utilize [RackConnect](https://www.rackspace.com/cloud/hybrid/rackconnect/) to use both the Rackspace Public and Private Cloud.

RackConnect allows a customer's private and public Clouds to talk to each other. With this connectivity you begin to get into Hybrid Cloud territory.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/rackconnect-priv-pub.png rackconnect-priv-pub %}

But, how do you use all of this? How can you “burst” into the Rackspace Public Cloud from your Rackspace Private Cloud without having to manually spin up Cloud Servers?

This is where automation and monitoring come into play.

### AutoScale Group

First, log into your Rackspace Public Cloud account and create an AutoScale Group.

When triggered, an AutoScale Group will specify what Load Balancer to add the Cloud Server to, what Cloud Image to use, what Cloud Flavor to use, and the number of Cloud Servers to create.

The AutoScale Group has a webhook that you can use to trigger it. This will be used in the alarm you create later.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/autoscale-group.png autoscale-group %}

The AutoScale Group is only the first piece of the puzzle, next you need to setup Monitoring.

### Monitoring

Each of the OpenStack Instances running in the Rackspace Private Cloud have an agent running to collect all the typical metrics. That agent is saving those metrics to the Rackspace Intelligence Portal.

As you can see in the screenshot below, the load average is being monitored on the database and web OpenStack Instances in the Rackspace Private Cloud. The web tier OpenStack Instances would be monitored as well.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/monitoring.png monitoring %}

With this metric being recorded, an alarm can be created.

### Alarm

When you create an alarm you can configure the criteria you want it to alarm on.

In the screenshot below, the alarm is configured to trigger when the load average on the web OpenStack Instance goes above .7.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/load-alarm.png load-alarm %}

This is obviously not a realistic number for a production environment, but it works well for testing purposes.

Once the alarm is created, you tie it to a Notification Plan.

### Notification Plan

The Notification Plan wraps everything together.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/notification-plan.png notification-plan %}

When the load alarm is triggered, it triggers the Notification Plan which will trigger one of the webhooks that were created when you setup the AutoScale Group.

So, when the load average goes above .7, the CRITICAL notification is triggered which kicks off the AutoScale Group to add servers.

When the load back down, below the alarm threshold, the OK notification is triggered which kicks off the AutoScale Group to remove servers.

### Test

To trigger a load test, you can use a tool like [ApacheBench](https://httpd.apache.org/docs/2.2/programs/ab.html).

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/apache-bench.png apache-bench %}

In the screenshot above, ApacheBench is being used to trigger 20000 requests with 100 requests at a time.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/load-metric-spike.png load-metric-spike %}

In the screenshot above, you can see the load average of the Rackspace Private Cloud OpenStack Instance clearly rising above .7. The load alarm will now be triggered and begin creating new Cloud Servers.

### Bursting

Going back to the AutoScale Group you can see at the bottom of the screenshot that another Cloud Server is being created.

{% img matte full 2014-08-11-using-rpc-host-web-tier-apps/autoscale-group-triggers.png autoscale-group-triggers %}

Once the Cloud Server is online, it will be added to the Cloud Balancer (optionally a hardware load balancer with a bit more work) and ready to be used to spread load across the Rackspace Public and Private Clouds.

What's Next
-----------

So, I have discussed why Rackspace Private Cloud is a great fit for your cloud ready web applications, why you may need to migrate your web application from a public cloud to a private cloud, discussed and provided a concept architecture of a cloudy web tier application, and discussed an overview of bursting into the Rackspace Public Cloud from your Rackspace Private Cloud.

This concludes the third of several posts in the [RPC Insights series](https://www.rackspace.com/blog/welcome-to-rpc-insights/).

Join us on August 20, 2014 at 10:00 AM CDT for a live webinar on [Using Rackspace Private Cloud to Support Your Software Development Lifecycle](https://go.rackspace.com/rpc-to-support-your-software-development-lifecycle.html).
