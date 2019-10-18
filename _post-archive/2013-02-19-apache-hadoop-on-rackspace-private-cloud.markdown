---
layout: post
title: Apache Hadoop on Rackspace Private Cloud
date: '2013-02-19 08:00'
comments: true
author: Sudarshan Acharya
categories:
  - Private Cloud
  - OpenStack
---
I truly believe that in the next five years, cloud will be the default way that IT resources like compute and storage will be consumed. As a provider of [public](https://www.rackspace.com/cloud/) and [private](https://www.rackspace.com/cloud/private/) clouds powered by OpenStack, we at Rackspace are committed to making OpenStack the preferred infrastructure layer for a lot of platforms and applications.
<!-- more -->
Along with cloud computing, big data has been a major trend in enterprise computing. And a recurring question from our customers is how well these interesting technologies like Apache Hadoop and Apache Cassandra work on top of OpenStack?

Deploying and maintaining a decent sized Hadoop cluster can be a daunting task by itself. We chose the Hortonworks Data Platform (HDP) and wrote some Chef cookbooks and an OpenStack knife plugin to make the installation of Apache Hadoop easier and more cloud-like on OpenStack. Using the Rackspace [Private Cloud Software](https://www.rackspace.com/cloud/private/openstack_software/) and the Chef cookbooks, launching a Hadoop cluster is just as easy as booting a few virtual machines with proper Chef roles. This way, I can easily get a Hadoop cluster anytime I
need, and this is especially powerful for development and testing.

Quick and easy installation on cloud makes it so easy to consume Hadoop. There are several advantages to running Hadoop in the cloud, and most of it has to do with the agility and the elasticity of the cloud and the open nature of OpenStack. However, the combination of Hadoop and OpenStack (and virtualization in general) is not without challenges. While the I/O overhead due to virtualization comes up on everyone’s mind, there are other issues that you need to understand to ensure reliability
and integrity of the data.

You can read about deploying [Apache Hadoop on Rackspace Private Cloud](https://www.rackspace.com/knowledge_center/article/apache-hadoop-on-rackspace-private-cloud) at the [Private Cloud Tech Center](https://www.rackspace.com/knowledge_center/article/private-cloud-tech-resources) to understand more about the pros and cons of the approach, and why you may want to move your big data workload to the cloud.

With Apache Hadoop and OpenStack both being open source, and vital to the future of enterprise computing, we think this combination works pretty well together and has even bigger potential in the future.
