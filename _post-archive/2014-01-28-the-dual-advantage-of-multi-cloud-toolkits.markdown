---
layout: post
title: The dual advantage of multi-cloud toolkits
date: '2014-01-30 9:30'
comments: true
author: Everett Toews
published: true
categories:
  - jclouds
  - sdk
  - developers
---
{% img right 2014-01-28-the-dual-advantage-of-multi-cloud-toolkits/multi-cloud.png 200 %}

The goal of using a multi-cloud toolkit is avoiding cloud vendor lock-in. I
examined why avoiding vendor lock-in is important in [
Keep the Cloud Honest](http://blog.phymata.com/2013/07/31/keep-the-cloud-honest/).
Toolkits such as Apache jclouds (Java), Apache libcloud (Python), Fog (Ruby), and
pkgcloud (node.js) enable this by allowing you to write code that will work the
same across multiple clouds such as Amazon Web Services (AWS), DigitalOcean,
Google Compute Engine, and Rackspace.

<!-- more -->

Exactly how the toolkits achieve this matters a great deal. Most people think
it’s those interfaces within the toolkit that work the same across multiple
clouds that are responsible for this. They’re right but there’s more to it than
that.

Those interfaces are sometimes called abstraction layers or portable APIs. First,
let’s look at the portable APIs. I’m most familiar with jclouds, so I’ll use
examples from our community.

### Portable APIs

These are the APIs that allow you to write code that can run with multiple clouds.

For example, you can write code that stores an object in the cloud and that exact
same code can run with storage services such as HPCloud Object Storage, AWS S3,
and Microsoft Azure. Companies like Maginatics use this to great effect to store
billions of objects across many clouds. Smaller projects like ElasticInbox use
it to increase redundancy using multiple clouds.

The same goes for computing resources. You can write code that starts a virtual
machine in the cloud and that exact same code can run with compute services such
as Rackspace Cloud Servers, CloudSigma, and SoftLayer. This allows a Jenkins
plugin to start slaves on different clouds or Apache Stratos to run it’s Platform
as a Service across multiple clouds.

The portable APIs do this by supporting features that are common across many
clouds. Because these features are common, they are naturally a subset of all
of the possible features that a cloud may provide. But what happens when your
application requires a feature that isn’t common and isn’t part of the portable
API?

No problem. All of the multi-cloud toolkits allow you write code to specific
APIs for each cloud so you can use those particular features. But then you’re
seemingly headed down the path of vendor lock-in. Not so.

### Easing the transition to another cloud

Without multi-cloud toolkits, the normal course of action for a developer working
with a cloud is to download the toolkit for that cloud only and write their code
using it. For example, a developer downloads the AWS Java toolkit and uses it
throughout their application with AWS.

To switch to another cloud, not only do the developers have to tear out the AWS
Java toolkit and all of the associated code. They have to download the toolkit
for another cloud and that toolkit is going to have a different architecture,
different idioms, and a different programming paradigm. Developers will have to
understand how it works, learn its nuances and idiosyncrasies, and re-architect
their application around it. This is a high cost proposition and high barrier to
leaving AWS. Lock-in pure and simple.

With multi-cloud toolkits, a developer downloads the multi-cloud toolkit and
writes their code using it, possibly using specific APIs for particular features
to a cloud. For example, a developer downloads the Apache jclouds toolkit and
uses it throughout their application with Rackspace.

To switch to another cloud, a lot of code has to be replaced and refactored
but they do not have to download another toolkit. All of the cloud providers in
jclouds are architected and written in a similar style so there is a lot of
consistency between them. Developers already understand how it works, and are
comfortable and efficient with it. They can use their intuition when transitioning
their code to a new cloud provider. This is a lower cost proposition and a lower
barrier to leaving Rackspace. No lock-in. You can choose the cloud provider that
works the best for you.

### Conclusion

The value of multi-cloud toolkits is not only in their portable APIs but also
in how they can ease the transition from one cloud to another by allowing the
developer to reuse all of the knowledge and experience they have gained with the
multi-cloud toolkit.

At Rackspace, we believe so strongly in our cloud that we don't feel the need to
lock-in developers. We want to earn your loyalty by delivering consistent
performance and an excellent developer experience. Don’t get locked into a cloud
provider because the cost of switching is too high.
[Choose a multi-cloud toolkit](https://developer.rackspace.com/).
