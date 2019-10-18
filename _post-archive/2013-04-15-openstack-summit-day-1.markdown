---
layout: post
title: 'From the OpenStack Summit: Day 1'
date: '2013-04-15 18:57'
comments: true
author: Hart Hoover
published: true
categories:
  - OpenStack
---
Greetings from the OpenStack Summit! A lot happened in the world of OpenStack today. For a recap of all of the news, check out [Niki Acosta](https://twitter.com/nikiacosta)'s [blog post](https://www.rackspace.com/blog/openstack-summit-portland-day-1-recap/) on the Rackspace Blog. Read on for a recap of some sessions I attended today! <!-- more -->

##Cloud Foundry

Part of my day was spent in a session given by [Ferran Rodenas](https://www.linkedin.com/in/frodenas) and [Dekel Tankel](https://www.linkedin.com/in/dekel/) on Cloud Foundry. Cloud Foundry is a platform service that can run on multiple IaaS services, including OpenStack. Cloud Foundry is an open platform as a service, providing a choice of clouds, developer frameworks and application services. Initiated by VMware, with broad industry support, Cloud Foundry makes it faster and easier to build, test, deploy and scale applications. To run on OpenStack, Cloud Foundry uses an open source tool chain for release engineering, deployment and lifecycle management of large scale distributed services called BOSH to interact with the underlying IaaS.

Using a platform service on top of OpenStack infrastructure allows your development team to deploy new applications (or new features on existing applications) without having to manage underlying infrastructure. More information on deploying Cloud Foundry is available [here](https://www.cloudfoundry.org).

##Upgrading OpenStack through Continuous Deployment

Another session I attended was on upgrading OpenStack through continuous deployment given by [Rob Hirschfeld](https://twitter.com/zehicle). Upgrading OpenStack from release to release has been problematic in the past for users and operators, especially with major releases occurring every three months. Do you take your cloud down during a maintenance window, upgrade, and bring it back up and hope for the best? How do you upgrade between services? Nova interacts with Cinder, Glance, and other projects. Which do you upgrade first?

The OpenStack [Grenade project](https://wiki.openstack.org/wiki/Grenade) has been created to try to address these issues by giving OpenStack operators a way to upgrade services in a continuous way. Through continuous deployment you can quickly fix issues that arise in your upgrade by either resolving the issue immediately or rolling back your deployment to a known good version.

Rackspace handles upgrades in our public cloud through continuous integration and delivery to staging, then pushes out updates during release windows to production. We can do this without downtime due to the way we've deployed our cloud. More information on how Rackspace accomplishes this is available from this [blog post from Troy Toman](https://www.rackspace.com/blog/how-rackspace-re-wrote-the-cloud-with-openstack-continuous-delivery/).

Keep checking back here for information from the OpenStack Summit!
