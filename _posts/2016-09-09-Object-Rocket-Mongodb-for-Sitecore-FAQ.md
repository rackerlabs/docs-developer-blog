---
layout: post
title: "Object Rocket MongoDB for Sitecore FAQ"
date: 2016-09-09 00:00
comments: false
author: Juan Daniel Garza
authorIsRacker: true
published: true
categories:
  - Devops
  - database
  - aws
  - architecture
---

Using Sitecore with the experience database requires a connection to MongoDB, which can add quite a bit of complexity to your Sitecore installation. Here are some frequently asked questions about using Object Rocket to host Mongo DB for Sitecore.

<!-- more -->

Do I have to use MongoDB to use Sitecore?
No. If the collection database (MongoDB) is not available, or the licenses for Sitecore XDB are not present, Sitecore starts in ‘CMS only mode’ or Experience Management, which disables several of the analytics features within Sitecore that rely on the Experience Database. For more information about CMS only mode reference the following Sitecore documentation.
[Sitecore Experience Management](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/experience_management/configuring/experience_management_compatibility)

How big should my Mongo instance/plan be to start?
The ‘5Gb Medium’ plan is large enough to start with, but if you anticipate significant data growth, you can use the ‘20Gb Medium’ plan to take advantage of using Wired Tiger as the storage engine. Wired Tiger provides some added efficiency via compression as the database grows, and yes the database grows.
[How to calculate the growth of Sitecore’s Collection Database](https://developer.rackspace.com/blog/Calculating-the-growth-of-Sitecores-collection-database)

Do I need to use the SSL connection strings?
Yes. If the Object Rocket server is in the same secured network (like using Rackspace Service-Net), risk can be reduced so you could use non-SSL communication. However, risk of data exposure still exists, so you do not want to use such a configuration in Production.

What version/s of Mongo should I use for Sitecore 8.1?
Sitecore Experience Platform 8.1 (rev. 151003) supports the following MongoDB Database versions:
MongoDB 2.6 mmapv1
MongoDB 3.0.4 mmapv1
MongoDB 3.0.4 WiredTiger
for
Sitecore 8.1 Update-1 (rev. 151207)
Sitecore 8.1 Update-2 (rev. 160302)
Sitecore 8.1 Update-3 (rev. 160519)
*Though documentation only references version 3.0.4, this is due to the time of publication. Through discussions with Sitecore support, the latest version of 3.0.X should work, though Sitecore has not yet performed enough testing to validate this claim.
Sitecore supports the Mongo .NET 1.10 drivers only. The Mongo 2.0 driver is not supported.
[Install supported driver](https://www.nuget.org/packages/mongocsharpdriver/1.10.0)

Object Rocket currently offers the following MongoDB Versions:
2.4.6, 2.6.10, 3.2.8
*You can open a support request to have an instance created using an older version when needed

How do I scale my instance?
RocketScale is an agent unique to ObjectRocket that scales sharded instances in an automated fashion as the instance grows. RocketScale watches each MongoDB instance, and, when RocketScale threshold on the settings page is exceeded, it adds a shard to the instance.
The RocketScale threshold is based on total percentage of storage consumed on the cluster. The current storage usage is viewable on Instance Details by clicking the instance name on the Instances page. For example, if the plan is 20GB, and there are currently 2 shards for a total available storage space of 40GB, and Rocketscale is set to 75%, then when the storage usage reaches 30GB a shard will be added.
RocketScale may be turned off by setting it to zero or by removing any value from the field on the settings page.

Do I need to do my own backups?
Each instance is protected by replication. Should any component fail, the replica set architecture of MongoDB provides the primary level of high availability, fault tolerance, and uptime. However, as a last resort and for overall data protection, backups are taken daily at ObjectRocket, which can be restored or downloaded by submitting a support request.

Can I run my analytics databases on the same instance I am using for session state?
While it technically works, the session state DB is accessed very frequently, and the performance could suffer. Sitecore strongly recommends using separate instances for the Analytics collection database and the session state DB. In most cases, the geographic proximity of the MSSQL database to the Content Delivery servers make SQL a more logical solution to Session management.

My datacenter is geographically far from Object Rocket, can I still use Object Rocket? , What about Latency?
Yes! Our testing has yielded positive results when using Object Rocket’s MongoDB both within Rackspace hosted instances and using AWS hosted instances. Sitecore installations can be hosted in various AWS and Azure hosting regions with relatively low impact. You should still attempt to select a hosting instance that is as close to your webhosting facility as possible to minimize latency. We experienced more dramatic performance reduction when using an Instance based in another country though only when the site was under heavy load.
