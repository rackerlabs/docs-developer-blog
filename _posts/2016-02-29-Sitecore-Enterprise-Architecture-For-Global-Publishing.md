---
layout: post
title: "Sitecore Enterprise Architecture for Global Publishing"
date: 2016-02-29 00:00
comments: false
author: Grant Killian
authorIsRacker: true
published: true
categories:
    - Devops
    - architecture
---

Sitecore implementations with Content Delivery nodes in multiple locations must keep their databases and content in sync.  The [Sitecore Scaling Guide](https://sdn.sitecore.net/upload/sitecore7/70/scaling_guide_sc70_usletter.pdf) summarizes areas of concern, such as isolating CM and CD servers, enabling the Sitecore scalability settings, maintaining search indexes, etc.  Sitecore runs on top of SQL Server, and one topic touched on in the Scaling Guide is SQL Server replication, and conveniently there is a Sitecore [guide just for that specific subject](https://sdn.sitecore.net/upload/sitecore6/63/sql_server_replication_guide_sc63-64-usletter.pdf).  This guide explains how, with SQL Server Merge Replication, one can coordinate the content of Sitecore databases that are not in the same location.  This is the starting point for what we at Rackspace have found to be a global publishing architecture that meets the needs of enterprise Sitecore customers.

<!-- more -->

### Lessons Learned Through Experience

After numerous global Sitecore deployments, the [Rackspace enterprise Sitecore team](https://www.rackspace.com/en-us/web-content-management/sitecore) has gravitated to a configuration pattern built on top of SQL Server Replication for Sitecore to dramatically improve content publishing performance.  We've observed Sitecore content publishing operations to take a long time, sometimes *hours*, and while there are common sense measures to improve the speed of Sitecore publishes, network latency can always be a big factor.

If one has a Content Management server in London, for example, and publishes to Content Delivery servers in Hong Kong and Dallas . . . that's a long distance for the data to move and the standard Sitecore publish is very "chatty" and inefficient in moving large quantities of items through the Sitecore API.

Content Delivery servers work from the Sitecore Web database, and a Sitecore publish operation is mostly about moving content from the Master database to the Web database.  With that in mind, we at Rackspace create *proxy* web databases that we locate in the same data center as the Content Management server.  Taking our example of a CM server in London with CD servers also in Hong Kong and Dallas, we'd have two additional web databases in London: proxyWebForHongKong and proxyWebForDallas.  On the London CM server, we'd create custom Sitecore [publishing targets](http://www.sitecore.net/learn/blogs/technical-blogs/john-west-sitecore-blog/posts/2011/05/all-about-publishing-targets-in-the-sitecore-aspnet-cms.aspx) for the proxyWebForHongKong and proxyWebForDallas.  We *wouldn't* connect the actual Web databases located in Hong Kong and Dallas to the CM instance in the conventional sense, so there is no globe-spanning publishing operation from London to Hong Kong or Dallas . . . instead, we'll use SQL Server replication to synchronize proxyWebForHongKong with the real Hong Kong Web database, and the same for Dallas.

This is one of those cases where a picture is worth a thousand words.  The diagram below illustrates how this works, building on the example of a Sitecore CM installation in London with CD clusters in remote data centers in Hong Kong and Dallas.

![Sitecore Enterprise Architecture for Publishing](https://grantkillian.files.wordpress.com/2016/02/2016-02-23-sitecore-enterprise-architecture-for-global-publishing.jpg "Sitecore Enterprise Architecture for Publishing")

### Replication Explorations

We're using SQL Server Merge replication, the only type of replication officially supported by Sitecore, but we have initial investigations into whether running [Transactional Replication](https://technet.microsoft.com/en-us/library/ms151254%28v=sql.105%29.aspx) for Sitecore would be a more performant alternative.  Merge Replication is typically used when data flows in high volumes in both directions and conflicts may need to be resolved; Transactional Replication is typically used for one-way flows of data.

In the case of Sitecore publishing, Transactional Replication feels like an intiutive choice, but the current Sitecore database schema isn't a fit for Transactional Replication in a couple of ways:

* not all database tables have primary keys; Transaction Replication requires replicated tables to have primary keys defined
* the timestamp data type isn't valid for Transactional Replication; for example, the EventQueue.Stamp column would need to be moved from a *timestamp* to *binary(8)* data type

These hurdles are fairly easy to overcome, but the *wisdom* of doing so without full support from Sitecore leaves Transactional Replication as an experimental approach.  At Rackspace, we only use Merge Replication for live environments, but we continue to explore other options in our various Sitecore labs.
