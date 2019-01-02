---
layout: post
title: Gophercloud Update
date: '2015-04-08 10:00'
comments: true
author: Jon Perritt
published: true
categories:
  - openstack
  - sdk
---

## New Services Supported
Since the release of [Gophercloud v1.0](https://github.com/rackspace/gophercloud) in October 2014, we've been working hard to bring the library into parity with the other Rackspace SDKs. In addition to the services supported at the time of the release ([Rackspace Identity](https://developer.rackspace.com/docs/cloud-identity/getting-started/), [Cloud Servers](https://developer.rackspace.com/docs/cloud-servers/getting-started/), [Cloud Files](https://developer.rackspace.com/docs/cloud-files/getting-started/), and [Cloud Block Storage](https://developer.rackspace.com/docs/cloud-block-storage/getting-started/)), Gophercloud now supports the following Rackspace services:

- [Cloud Load Balancers](https://github.com/rackspace/gophercloud/tree/master/rackspace/lb/v1)
- [CDN](https://github.com/rackspace/gophercloud/tree/master/rackspace/cdn/v1)
- [Cloud Orchestration](https://github.com/rackspace/gophercloud/tree/master/rackspace/orchestration/v1)
- [Cloud Networks](https://github.com/rackspace/gophercloud/tree/master/rackspace/networking/v2)
- [RackConnect](https://github.com/rackspace/gophercloud/tree/master/rackspace/rackconnect/v3)

A Getting-Started guide for Cloud Load Balancers [exists](https://developer.rackspace.com/docs/cloud-load-balancers/getting-started/), and similar guides for the other services are being created.

<!-- more -->

## Automatic Re-authentication
Gophercloud now supports automatic re-authentication. This will enable long-running jobs to continue normally if the users token expires during code execution. To enable it, simply set the `gophercloud.AuthOptions` field `AllowReauth` to `true`:
```go
opts := gophercloud.AuthOptions{
  Username: "myUserName",
  APIKey: "myAPIKey",
  AllowReauth: true,
}
```

## AllPages Method
We've added a new method named `AllPages` that allows users to retrieve all the pages from a `List` call without worrying about pagination. For example, to retrieve all RackConnect Load Balancer Pools:
```go
import "github.com/rackspace/gophercloud/rackspace/rackconnect/v3/lbpools"
allPages, err := lbpools.List(client).AllPages()
if err != nil {
  // handle error...
}
allPools, err := lbpools.ExtractPools(allPages)
```
The `AllPages` method works with all the `List` operations in Gophercloud.

## cs-reboot-info
In late February 2015, Rackspace had to reboot some First Generation and Next Generation Cloud Servers due to a Xen vulnerability. As a means for Rackspace customers to find out if and when their instances would be rebooted, we created a tool called [cs-reboot-info](https://github.com/rackerlabs/cs-reboot-info). Written in Go, cs-reboot-info utilizes Gophercloud for communicating with the Rackspace API. Because the tool needed to query the Rackspace API for both Next Generation and First Generation servers, we had to write a [one-off Cloud Servers v1 service](https://github.com/smashwilson/gophercomputev1) to retrieve First Generation Cloud Servers. Largely due to the simplicity of Go and Gophercloud, this tool was able to be completed and tested in a single day.

## Next Up
There are still several Rackspace services to implement and next up are Cloud Databases and Cloud Images. If you'd like to help with either of those services or any of the others, [contributions](https://github.com/rackspace/gophercloud/blob/master/CONTRIBUTING.md) are always welcome.

## Get the New Features
To pull down the current Gophercloud features, you have the following options:

1. From the command-line, run `go get -u github.com/rackspace/gophercloud`. The `-u` flag will update the Gophercloud package if it already exists on your machine.

2. If you're using [godep](https://github.com/tools/godep), from the command-line run `go get -u github.com/rackspace/gophercloud`. Then, run `godep update github.com/rackspace/gophercloud`. That will update your Godeps.json file with the Gophercloud `master` branch commit at `HEAD`.
