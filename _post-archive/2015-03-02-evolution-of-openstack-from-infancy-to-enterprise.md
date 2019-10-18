---
layout: post
title: Evolution of OpenStack - From Infancy to Enterprise
date: '2015-03-02 23:59'
comments: true
author: Walter Bentley
published: true
categories:
  - openstack
---

Recently I had the pleasure of hosting a webinar covering the Evolution of OpenStack.  No matter how many times I review the history of OpenStack, I manage to learn something new.  Just the idea that multiple companies, with distinct unique ideas can come together to make what I consider to be a super platform is amazing.  Whether you think OpenStack is ready for prime time or not, it is hard to deny the power and disruptive nature it has in the current cloud market.  

<!-- more -->

#####OpenStack 101 – What is OpenStack
The most simple definition I can provide as to what OpenStack is:  OpenStack is an open source cloud operating platform that can control large pools of compute, storage and networking recourses throughout a datacenter, all managed through a single interface controlled by either a CLI, API and/or dashboard.  The orchestration provided by OpenStack gives administrators control over all those resources while still empowering the cloud consumers to provision resources thru a self-service model.  The platform is built in a distributed and modular way.  This means the platform is built from multiple components, and you can chose which ones you need in reference to your personal use case.  A common analogy is that it is similar to Legos. One of the unique capabilities of OpenStack that stands out to me is the ability to leverage commodity hardware and not to have to rely on a particular make/model. With OpenStack, you don't have to keep all hardware the same.

---
#####The Three W’s - When, Who and Why
Let's jump right in at the beginning, the birth of OpenStack.  The life of OpenStack started back in March 2010 when Rackspace decided to create an open source cloud platform.  At the time Rackspace was primarily focused on a fully distributed object storage product.  Coincidentally a few months earlier, NASA was approached by the US Government to create a platform to assist in the newly passed Open Government Initiative.  NASA soon called their project, Nebula. 

After an email exchange, Rackspace and NASA decided to combine their efforts.  In October 2010 the OpenStack project officially started. Here is the link that provides a bit more context and high-level timeline in an interactive model - [OpenStack Timeline](https://www.tiki-toki.com/timeline/entry/138134/OpenStack-History/#vars!date=2010-03-30_01:52:57!).

---
#####The OpenStack Foundation
For the first two years, the OpenStack project was closely managed by Rackspace and its 25 initial partners. In September 2012, Rackspace decided to transfer the intellectual property and governance of the OpenStack project into a non-profit member run foundation that is known as the OpenStack Foundation.  This OpenStack Foundation consists of a community that collaborates around a six-month, time-based release cycle.  Within the planning phase of each release, the community gathers for a OpenStack Design Summit where project developers have live working-sessions and agree on release items.

The stats below prove that OpenStack is very much an active community platform with improvements happening daily, by the people who actually use and believe in the system.

![OpenStack Community Stats](https://www.hitchnyc.com/content/images/2015/03/Slide06.jpg)

---
#####What Problem Does OpenStack Solve?
Before the cloud, and virtualization capability, came to the life, data centers were growing at an uncontrollable rate.  Data centers were filled with extremely under-utilized servers running one or two applications.  That problem consequently gave birth to virtualization, the concept of using a hypervisor on top of hardware to create a multi-tenant computing platform.  Being able to run multiple virtual machines on a single piece of hardware allows you to reduce the overall server footprint and optimize your hardware use better.  Problem solved right?  Well, not totally.

As we all know, virtualization, over time, became the preferred infrastructure choice. Then data centers were filled with servers running hypervisors, with no real easy way to manage the ever growing virtualization platforms.  This is where OpenStack provides value, because OpenStack allows you to add an orchestration layer on top of many types of hypervisors within your data center. This allows for more efficient management of your hardware and provides the ability to distribute your application workloads based on demand.

---
#####The Guts of OpenStack
The diagram below outlines all the projects/services currently part of the OpenStack platform.

![OpenStack Projects/Services](https://www.hitchnyc.com/content/images/2015/03/Slide11.jpg)

---
#####OpenStack Project Timeline
This timeline visually walks you through the OpenStack project progression, really driving home the point that, over time, the project added a rich feature set.  As mentioned during the webinar, it was not until around the Grizzly/Havana release that OpenStack was ready for primetime.  Fast forwarding to now, with OpenStack turning 5 years old this year, you can see the feature set has only gotten better.  Mainly with the introduction of Heat, Ceilometer and Trove, one could say OpenStack is now ready for Enterprise production workloads.

![OpenStack Project Timeline](https://www.hitchnyc.com/content/images/2015/03/Slide12.jpg)

---
#####OpenStack Is Ready for the Enterprise
During OpenStack’s growth, its features have matured creating a stable reliable platform.  The number of features are too many to mention here in this blog.  Below are just a few of my favorite features, that in my mind makes it “Ready for the Enterprise”.

***OpenStack Features and Benefits***
![OpenStack Features](https://www.hitchnyc.com/content/images/2015/03/Slide15.jpg)

***High Availability Options***
![OpenStack HA](https://www.hitchnyc.com/content/images/2015/03/Slide16.jpg)

---
#####Industry Focus on OpenStack
Over the last year, OpenStack has gained the attention of many traditional IT vendors such as EMC, HP, Cisco and Red Hat.  This has led to some of the most important cloud acquisitions we have seen in years.  All of those acquisitions have one thing in common: OpenStack.

This article says it all - [2014’s Most Significant Cloud Deals Have OpenStack At Heart](https://www.itworld.com/article/2836991/2014s-most-significant-cloud-deals-have-openstack-at-heart.html).

---
#####Enterprise Use Cases
On the openstack.org site there are many [user stories](https://www.openstack.org/user-stories/) you can download and read to help support OpenStack’s wide spread use.  The [Norte Dame](https://www.rackspace.com/blog/accelerating-science-with-openstack-at-notre-dame/) story was very interesting to me.  One of the newest and ground breaking user stories came from Walmart Labs, the eCommerce innovation and development group of Walmart.  I have provided some cliff notes below but, you can read the whole article [here](https://www.walmartlabs.com/2015/02/17/why-we-chose-openstack-for-walmart-global-ecommerce/?awesm=awe.sm_jM31y).  I strongly encourage taking the time out to read this article.

**Walmart Labs have:**

* roughly 100K cores of compute running on OpenStack
* used OpenStack to run the parent company’s Cyber Monday and holiday season sales operations
* started with OpenStack a year and a half ago
* 3.6K employees worldwide using their OpenStack platform
* created a private cloud at public cloud scale

---
#####In Conclusion
Personally I enjoyed recapping the great progress OpenStack has made in almost 5 short years.  The strength and power behind what a community of users can come together to do can make you speechless.  

In my opinion, OpenStack is crossing the line from early adopters to early majority in the adoption cycle model.  This idea is supported by a recent article describing how Walmart, the worlds largest revenue generating company, used OpenStack to run revenue critical applications.  That speaks volumes as to its position in the market, as well as the ever increasing demand to move toward Open Source cloud technologies.  Organizations now seek speed-to-market, agility, and flexibility, and they need a single control plane to manage their infrastructure. OpenStack has proven it provides all the above, and, technically, we are just getting Enterprise ready. Imagine what the next year or two will bring!