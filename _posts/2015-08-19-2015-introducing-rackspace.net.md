---
layout: post
title: Introducing Rackspace.NET
date: 2015-08-19T00:00:00.000Z
comments: true
author: Carolyn Van Slyck
authorIsRacker: true
authorAvatar: 'https://secure.gravatar.com/avatar/8b96f8872eb3f398809daf017ee3a8ab'
published: true
categories:
  - OpenStack
---

The Rackspace .NET SDK beta is now available! This is the first step towards improving the .NET
experience for OpenStack and Rackspace developers. Rackspace.NET enables you to work with both
 Rackspace services, which are based on OpenStack, and unique Rackspace offerings, such as hybrid cloud.
This is in the same spirit as the new [Rack CLI](rack-cli) which was announced last week.

OpenStack users will have a clean SDK dedicated to their needs
and moving at the pace of OpenStack. Rackspace customers will have a native experience,
seeing only functionality that is supported by Rackspace, using Rackspace terminology.

For more details on how this will improve OpenStack.NET, checkout
[Rackspace.NET and OpenStack.NET: Peas and Carrots][rackspacenet-openstacknet].

<!-- more -->

## Roadmap ##
Rackspace.NET is built on top of [OpenStack.NET](http://openstacknetsdk.org), because many of
Rackspace's solutions use OpenStack. We are in the process of moving Rackspace specific
solutions out of OpenStack.NET. When this migration is completed, OpenStack.NET
v2.0 will be pure OpenStack and Rackspace.NET v1.0 pure Rackspace.

The project's [beta milestones][rackspacenet-milestones] outline the full roadmap.
Here's a peek at the first few releases:

* [v0.1][rackspacenet-0.1] - Cloud Networks. This coincides with the release of [OpenStack.NET v1.5.0][openstacknet-1.5] with support for OpenStack Networking v2.
* v0.2 - RackConnect Public IPs
* v0.3 - Cloud Servers
* v0.4 - Rackspace Identity

## Cloud Networks Support

[Rackspace Cloud Networks][cloud-networks] enable you to create isolated networks and provision server instances with Rackspace networks or the isolated networks that you created.

The following small example helps you to get started. The [QuickStart for Rackspace Cloud Networks][quickstart] has a complete walk-through, and you can download the sample project from the [Rackspace.NET repository][rackspacenet-samples].

```csharp
var networkService = new CloudNetworkService(identityService, region);

var networkDefinition = new NetworkDefinition { Name = "{network-name}" };
var network = await networkService.CreateNetworkAsync(networkDefinition);

var subnetDefinition = new SubnetCreateDefinition(network.Id, IPVersion.IPv4, "{cidr}");
await networkService.CreateSubnetAsync(subnetDefinition);

var portDefinition = new PortCreateDefinition(network.Id) { Name = "{port-name}" };
await networkService.CreatePortAsync(portDefinition);
```

[cloud-networks]: http://www.rackspace.com/cloud/networks
[quickstart]: https://developer.rackspace.com/docs/cloud-networks/getting-started/?lang=.net
[rack-cli]: https://developer.rackspace.com/blog/introducing-rack-global-cli/
[rackspacenet-0.1]: https://github.com/rackspace/rackspace-net-sdk/releases/tag/v0.1.0
[rackspacenet-milestones]: https://github.com/rackspace/rackspace-net-sdk/milestones
[rackspacenet-openstacknet]: https://github.com/openstacknetsdk/openstack.net/wiki/Rackspace-and-OpenStack.NET
[rackspacenet-samples]: https://github.com/rackspace/Rackspace.NET/tree/master/samples/Rackspace.Samples
[openstacknet-1.5]: https://github.com/openstacknetsdk/openstack.net/releases/tag/v1.5.0.0
