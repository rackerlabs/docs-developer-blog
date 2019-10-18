---
layout: post
title: 'From the OpenStack Summit: Day 2'
date: '2013-04-16 18:39'
comments: true
author: Hart Hoover
published: true
categories:
  - OpenStack
---
Day two of the OpenStack Summit was even better than the first. It kicked off with a welcome from Jonathan Bryce, Executive Director of the OpenStack Foundation, who set the tone for the day's events. We then heard from companies using OpenStack - Bloomberg, Best Buy, Comcast, and [HubSpot](https://www.rackspace.com/blog/how-hubspot-uses-the-open-hybrid-cloud/) all talked about using OpenStack and what OpenStack had done for their business. Jim O’Neill, HubSpot CIO, experienced network issues during his live demo - but still wanted to show off how HubSpot uses OpenStack.<!-- more -->

{% youtube Vie4G7dKdJE %}

There were also some fantastic sessions today, several of which I want to highlight here.

##Using Heat as a Reference Architecture Baseline

Interoperability was a huge topic in several sessions today, and this was no exception. [Monty Taylor](https://twitter.com/e_monty) and [Rob Hirschfeld](https://twitter.com/zehicle) discussed using [Heat](https://wiki.openstack.org/wiki/Heat) as a vehicle for not only deploying on OpenStack, but using Heat to deploy OpenStack itself. The idea being that if there is a standard way for operators to deploy OpenStack, it will be easier for those operators to get help from each other if something doesn't work. There is discussion among board members on what makes up an OpenStack Cloud - a common deployment method is one way to define it. Monty and Rob made the case for upstreaming operations to encourage collaboration on deployments.

##DevOps Panel
This panel largely discussed bringing a DevOps culture to an organization and what that means for culture. Moderated by Dan Bode from Puppet Labs, the panel was made up of:

* Mike Cohen - Director of Strategic Alliances, Big Switch Networks
* Kevin Jackson - Senior Solutions Architect, Rackspace
* Shriram Natarajan - Head, Cloud Practice, Persistent Systems
* James Penick - Principal Systems Architect, Yahoo!
* Travis Tripp - Master Systems Architect, HP

Most of the readers of this blog probably know this, but DevOps was defined as basically breaking down the wall between a developer team and an operations team. My favorite quote was from Kevin Jackson:

> The most important tools for DevOps are humans. Using Chef and Puppet don't make you DevOps, they just make you efficient.

Practicing DevOps means that you can focus on your product as well as fixing issues that may arise by deploying code more often. The several month-long release cycle is a thing of the past - by deploying several times a day (or hundreds of times a day) you are always improving.

##Building a Cloudy App

Tony Campbell, Director of Training and Certification at Rackspace, led this session on deploying cloud applications to OpenStack clouds once you have them up and running. He followed basic principles that we have outlined on this blog before, but are worth repeating. Make sure your application can be compartmentalized and scale horizontally in tiers. Plan for success as well as failure in application design. You want web and worker nodes to be as stateless as possible, storing state in a relational database like MySQL, a NoSQL solution like MongoDB, Cloud Block Storage, Object Storage like Cloud Files, or a Cache. Check out the [five pillars of cloud application design](https://devops.rackspace.com/blog/categories/five-pillars/) for more on these topics.

I had a great day at the OpenStack Summit! Check back here tomorrow for a day three recap!
