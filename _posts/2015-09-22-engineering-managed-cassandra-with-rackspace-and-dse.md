---
layout: post
title: Engineering Managed Cassandra with Rackspace/DSE
date: '2015-09-22 08:00'
comments: true
author: David Grier
authorIsRacker: true
authorAvatar: 'http://1.gravatar.com/userimage/52111727/971866c998c4e064a3c958aa33c82053'
published: true
categories:
  - architecture
---

Managing infrastructure and database technology has grown at Rackspace and our list of supported technologies in the data umbrella has grown tremendously.

My name is David Grier and I am a product engineer at Rackspace. I concentrate most of my time on Cassandra, Hadoop and related components in the Big Data ecosystem.

We are proud to announce our partnership with Datastax, with whom we are providing a managed DataStax Enterprise (DSE) solution. This article is a high level view of that managed solution and how we are providing it to our customers.

<!-- more -->

The DSE solution we created is based on best practices from our partner Datastax, the Cassandra community, and our growing expertise–including OS tuning and SSD’s 10G private network and hardware specifics. Deployments of our managed DSE solution can live in any Rackspace Datacenter (DC) and are sized to each customer’s use case and needs.

Correct fits start in the 8 core 64G range for lighter workloads and dialing memory up to 256G if search is required.

We created a Reference Architecture to explain at a high level some common infrastructure layouts for your DSE deployment at Rackspace.

We have templated some layouts (shown below) which are horizontally scalable to accommodate ongoing growth. These layouts come with standard hardware configurations designed to fit a wide range of use cases. Here are a couple examples:



### Small Reference Architecture (consolidated):

![DSE Small]({% asset_path 2015-09-22-engineering-managed-cassandra-with-rackspace-and-dse/cassandra_small.png %})


* Multi-node cluster with OpsCenter deployed on its own node
This layout is necessary when resource utilization on the cluster nodes is expected to be too high to facilitate the addition of [OpsCenter](http://www.datastax.com/products/datastax-enterprise-visual-admin) on a cluster node.

* Distributed cluster which traverses multiple DCs
The main choke point in these builds is the firewall where it is potentially necessary to handle many transactions being passed between redundant clusters.



### Reference Architecture (Distributed):

![DSE Distributed]({% asset_path 2015-09-22-engineering-managed-cassandra-with-rackspace-and-dse/cassandra_dist.png %})

For more in depth information on these please refer to the reference architecture.

Rackspace uses Ansible internally for deployments and for maintaining infrastructure. Deploying dedicated DSE at Rackspace is [fully automated via Ansible](http://github.com/rackerlabs/ansible-dse), though some special tuning may be required after the cluster is up and operational. You can view Rackspace’s Ansible Playbook for DSE, as well as other useful tools, at the [Rackerlabs GitHub organization](https://github.com/rackerlabs).

The Rackerlabs GitHub organization holds many useful tools including our base provisioning software which we use for Cassandra deployments.

We are happy to talk with you about managing your data in Cassandra or any of our other supported datastores. Please feel free to reach out to our [data services sales team](http://www.rackspace.com/data) to start a conversation about how Rackspace can best meet your managed data storage needs.

[Reference Architecture]({% asset_path 2015-09-22-engineering-managed-cassandra-with-rackspace-and-dse/ReferenceArchitectureCassandra.docx.pdf %})
