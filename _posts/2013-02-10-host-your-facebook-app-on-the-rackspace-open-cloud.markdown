---
layout: post
title: Host your Facebook app on the Rackspace open cloud
date: '2013-02-10 22:20'
comments: true
published: true
author: Garry Prior
categories:
  - Cloud Servers
  - Cloud Networks
  - Cloud Monitoring
  - Cloud Files
---

We live our lives on the web. And [social media and networking has established itself a dominant force](http://blog.nielsen.com/nielsenwire/social/2012/), becoming the most visited sites on the web – and among the most popular social media sites, [Facebook has become the colossus](http://www.internetworldstats.com/facebook.htm), amassing more than an estimated 930 million users.

One aspect that sets Facebook apart is the applications – games, quizzes, you name it. While they may have a brief shelf-life, they can achieve massive popularity in a very short period of time. At Rackspace, we can help you plan for this unpredictable demand by hosting your Facebook app on our open cloud platform.

<!-- more -->

First, Facebook requires the use of SSL encryption to secure applications running on its platform. You can achieve this by using a Rackspace Cloud Load Balancer with SSL termination.
The network diagram below shows one possible configuration for hosting your Facebook app on the [Rackspace open cloud](http://www.rackspace.com/cloud/):

![Sample Facebook App Architecture](http://ddf912383141a8d7bbe4-e053e711fc85de3290f121ef0f0e3a1f.r87.cf1.rackcdn.com/facebook-app.png)

The above diagram comprises the following components:

1. [Cloud Load Balancers](http://www.rackspace.com/cloud/load-balancing/): You need to make sure your Facebook application can cope with demand, whether it's predictable or not (you could go viral in just minutes on Facebook). By putting a Cloud Load Balancer in front of your Cloud Servers, you'll be set up to provide a great experience to your end customers, both now and in the future. Adding more servers as you grow is easy; you don't even need to worry about new IP addresses as you spin servers up and down.  Cloud Load Balancers also have an SSL termination option, which Facebook requires for all applications running on its platform.

2. [Cloud Servers](http://www.rackspace.com/cloud/servers/): Facebook apps can often have a short shelf-life. You don't want to invest a fortune in infrastructure to support them, but you must still be prepared for your app to go viral and achieve huge demand. By running your application on Rackspace Cloud Servers you can easily scale up or down as required in a matter of minutes - you'll always provide a great service to your customers, but only pay for the infrastructure when you need it. Using our powerful APIs you could even automate this scaling.

3. [Memcached](http://memcached.org/): You need to look at all options to speed up delivery of content to your end customers. Memcached is an open-source (and free) third-party application that alleviates database load and improves Facebook application performance by serving as an in-memory key/value store.

4. [Cloud Databases](http://www.rackspace.com/cloud/databases/): Setting up and running your own database can be a hassle. Maybe you don't have the expertise in-house. Even if you do, you probably want it working on activities that will actually drive your business forward and not be tied up with the day-to-day administration that databases require. Cloud Databases can free up your IT resources by providing a highly available MySQL database purpose-built and optimized for high performance and scalability. It reduces your operational costs by automating tasks related to deployment, configuration and patching.

5. [Cloud Files](http://www.rackspace.com/cloud/files/): You want to provide the best possible experience to your end customers. By storing the images and media contained within your Facebook application in Cloud Files, you can take advantage of the Akamai Content Distribution Network. This delivers content at blazing speeds to your end customers, wherever they are in the world. Cloud Files also provides unlimited object storage for server "images" and back-ups.

6. [Cloud Monitoring](http://www.rackspace.com/cloud/monitoring/): You can't watch your application 24x7 - we know you've got a business to run. But Facebook is a 24x7 global platform, so your users never sleep. Cloud Monitoring allows you to define a series of "checks" on your infrastructure; including resources outside of Rackspace (you can check anything with an IP address or URL). By choosing when and how alerts should be triggered, you can get on with more important things, safe in the knowledge that we're watching your infrastructure around the clock. If something goes wrong, you'll know about it. And, importantly, we will too; with our [Managed Cloud](http://www.rackspace.com/cloud/managed_cloud/) you can use Cloud Monitoring to automatically raise a support ticket to Rackspace, so we can start working on the problem right away.

### Rackspace Support

We also provide a Fanatical Experience to our users when they host their Facebook app on the Rackspace open cloud. Our Managed Cloud offering makes sure support techs are available to help you 24x7x365 via phone, chat or ticket. They also provide support for your operating system and many applications, so you can focus on running your business, not your IT. To learn more about this please see our Managed Service spheres of support. (Please note that Memcached is currently outside our sphere of support - we can help install it, but can't offer full support on an ongoing basis).

Don't need our Managed Cloud? No problem. We provide a Fanatical Experience to all Rackspace cloud customers. Our techs are here for you 24x7x365 via phone, chat and ticket. They'll provide OS-level support, but won't be able to login to your server to perform advanced trouble shooting, or provide application-level support.

### Other tools

A number of leading cloud application providers bring you apps, software and functionality to complement your cloud infrastructure, including the following:

   -   Track and manage your spend with [Cloudability](https://www.cloudability.com)
   -   Enhanced application and performance monitoring with [New Relic](https://newrelic.com)
   -   Performance and load testing of your application up to web-scale level with [SOASTA](https://www.soasta.com)
   -   Easy browser-based management of your Cloud Files storage with [Cyberduck](https://cyberduck.io)

That should get you started in hosting your Facebook app on the Rackspace open cloud!

_This post was authored by Garry Prior who joined Rackspace in April 2012 as a Senior Product Manager in the UK, and played a key role in launching the open cloud product set in our International business.  Prior to joining Rackspace Garry held various product management/development roles during eight years at UK mobile operator O2.  Outside of Rackspace, Garry also founded and runs a mobile-web based business called Taxi for two.  He is married with two young kids and lives just outside of London, UK._
