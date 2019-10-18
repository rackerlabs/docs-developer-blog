---
layout: post
title: Plans for the (v0.8?) release of pkgcloud
date: '2013-05-14 08:57'
comments: true
author: Ken Perkins
published: true
categories:
  - SDK
  - node.js
---
It’s been a few crazy weeks since I started at Rackspace, and while I’ve already been to San Antonio multiple times, as well as attending my first OpenStack Summit and meeting all of the awesome folks at the SF Rackspace office, I’ve spent the majority of my time getting up to speed on [pkgcloud](https://github.com/nodejitsu/pkgcloud).

For the uninitiated, pkgcloud is a [multi-provider cloud provisioning library](https://blog.nodejitsu.com/introducing-pkgcloud) from [Nodejitsu](https://nodejitsu.com/) for [Node.js](https://nodejs.org/), with bindings for [Rackspace](https://docs.rackspace.com/), [Amazon](https://aws.amazon.com/developertools), [Azure](https://msdn.microsoft.com/en-us/library/windowsazure/ff800682.aspx), [Openstack](https://docs.openstack.org/api/api-specs.html), and [Joyent](https://apidocs.joyent.com/sdcapidoc/cloudapi/) compute clouds. The objective is to define a standard interface for cloud assets, such that you don’t have to spend a significant amount of energy learning multiple APIs; you just focus on the integration.<!-- more -->

For example:

```javascript
var pkgcloud = require('pkgcloud');

var client = pkgcloud.providers.rackspace.compute.createClient({
 username: 'myAccount',
 apiKey: 'myApiKey'
});

client.createServer({
  name: 'myServer',
  flavor: 2,
  image: '9922a7c7-5a42-4a56-bc6a-93f857ae2346'
}, function(err, server) {
 // use your server here
});
```

You could use any of the compute providers here, and (image/flavor details not withstanding) your createServer call will work. In addition to compute support, pkgcloud has support for multiple storage services, as well as a number of database providers.

##What’s Next?

My focus has been on getting the prerequisites out of the way in order to support Rackspace Next Generation Cloud Servers (built on OpenStack) and to refactor the Rackspace client to be based on the OpenStack client. Given these plans, I wanted to be clear about what I was hoping to get merged in as the **v0.8** release of pkgcloud:

1. Rackspace client completely based on OpenStack
2. Support for Rackspace NextGen Cloud Servers
3. Continued Support for Rackspace Cloud Files (implemented as an extension of an [OpenStack swift](https://docs.openstack.org/developer/swift/) client)
4. Lots of samples, test cases, and documentation as appropriate

I’d love to get feedback on the plan, but I wanted to put my thoughts down on paper so I know what I’m shooting for.
