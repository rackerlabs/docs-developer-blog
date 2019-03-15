---
layout: post
title: OpenStack.NET 1.4 and beyond
date: '2015-07-13 23:59'
comments: true
author: Carolyn Van Slyck
authorIsRacker: true
authorAvatar: 'https://secure.gravatar.com/avatar/8b96f8872eb3f398809daf017ee3a8ab'
published: true
categories:
  - OpenStack
---

[OpenStack.NET 1.4.0](https://github.com/openstacknetsdk/openstack.net/releases/v1.4.0.0)
has just been pushed out the door! This release has two things going for it:
the release provides support for Content Delivery Networks (CDN), and it heralds
some big changes for the future of OpenStack.NET.

<!-- more -->

### CDN support

[Rackspace CDN](http://www.rackspace.com/cloud/cdn-content-delivery-network/features)
allows you to add a CDN service to your existing website with a single API call.
The service pulls content from your website and caches it on Akamai's global
network. From there you can control caching rules, restrict access, and purge
cached content.

The following small example helps you to get started. The
[QuickStart for Rackspace CDN](https://developer.rackspace.com/docs/cdn/getting-started/?lang=.net)
has a complete walk-through, and you can download the example project from the
[OpenStack.NET Demo repository](https://github.com/openstacknetsdk/Demos/tree/master/RackspaceQuickstart).

```
var cdnService = new ContentDeliveryNetworkService(authProvider, region);
var serviceDefinition = new ServiceDefinition("Example CDN Service", "cdn",
    domains: new[] {new ServiceDomain("www.example.com")},
    origins: new[] {new ServiceOrigin("example.com")});
string serviceId = await cdnService.CreateServiceAsync(serviceDefinition);
string service = await cdnService.WaitForServiceDeployedAsync(serviceId);
```

### OpenStack.NET today

OpenStack.NET has been a labor of love, passed down from maintainer to maintainer,
which is amazing. However, this has given the SDK an inconsistent experience, as
each developer did things a wee bit differently. Some services use async, some
have a dozen optional parameters, and some are missing useful methods such as
revoking a token. This is not criticism, rather it is an acknowledgement that
we have a ways to go.

That said, you can do quite a bit with what we have today:

* Provision multiple application servers with Cloud Servers
* Secure your network with Cloud Networks
* Meet high availability requirements with Cloud Load Balancers
* Associate a domain name to your server using Cloud DNS
* Scale your server's drive space with Cloud Block Storage
* Deploy your website's static files with Cloud Files
* Setup a MySQL database with Cloud Databases
* Use durable message queueing with Cloud Queues
* Enable Akamai with Rackspace CDN

Plus you can monitor all of the above with Cloud Monitoring!

### To Async and beyond!

I have big plans for OpenStack.NET, mainly **anything you can do in the Rackspace Cloud Control Panel, you should be able to automate with the SDK**. In the coming months, you will see regular releases, all focused on delivering new functionality. Once the feature gaps have been hunted down and dealt with, the existing services will be revisited so that they have similar, predictable interfaces.

Here is what you can expect from new services going forward:

 * **Async by Default** Synchronous extension methods will continue to be provided for those who need them.
 * **Clean Method Signatures** It should be much easier to understand what is required and not deal with a dozen optional parameters.
 * **Testable** The SDK now uses the standard HttpClient and with [Flurl it is very straightforward to fake API responses](http://tmenier.github.io/Flurl/testable-http/).

My final goal is that the SDK should be welcome wherever .NET is: Windows Desktop,
iOS, Android, Windows Phone, Mac, and Linux. The SDK isn't quite there yet, but
we'll be taking advantage of
[Microsoft's new direction for .NET](http://www.hanselman.com/blog/AnnouncingNET2015NETAsOpenSourceNETOnMacAndLinuxAndVisualStudioCommunity.aspx),
which has been in development for a while and will be released at the end of
the month. I'm looking forward to building demo applications which showcase
OpenStack.NET on as many platforms as possible.

The future for OpenStack.NET is very bright indeed, and I hope you'll come along
for the ride!
