---
comments: true
date: 2012-09-12T13:13:50.000Z
layout: post
author: Chad Lung
title: 'Rackspace open sources Atom Nuke - the fast Atom framework'
categories:
  - Cloud Servers
---

_This story is contributed by [Chad Lung](http://www.linkedin.com/in/chadlung), a software engineer on the Rackspace Cloud Integration team. Chad is the lead maintainer of Atom Hopper project. Be sure to check out his personal blog at [http://www.giantflyingsaucer.com/blog/](http://www.giantflyingsaucer.com/blog/) and follow [@chadlung](https://twitter.com/chadlung) on Twitter._

What if you had a tremendous mountain of data, broken up and stored across thousands of servers, and your client wanted some specific portion of that data? You could assemble the whole mountain and send the whole thing to your client, leaving the client to pick out what's needed. But there are reasons you split it up in the first place: it’s too big to store in one place or to transfer without interruption. Additionally there are reasons you manage the data, including security and privacy, so this mountain moving might not be a good idea.

<!-- more -->

{% img center 2012-09-12-rackspace-open-sources-atom-nuke-the-fast-atom-framework/atom-nuke-inmany-outmany.png %}

_What if you could create something as complex as this, with data in multiple formats from multiple origins stored across multiple servers but aggregated for multiple consumers, who could then repackage it for consumers of their own?_

If you couldn't give your client a copy of all your data, you could ask the client to describe the specific data that's needed and then assemble those items the client needs. However, if you had many clients, each with their own mountains of data, would you have to create a direct path from every consumer to every fragment of data they need?

What you need is to easily create a bridge, integrating any number of data origins with any number of data consumers. Enter in Atom Nuke.

{% img center 2012-09-12-rackspace-open-sources-atom-nuke-the-fast-atom-framework/atom-nuke-inall-outall.png %}

_With [Atom Nuke](http://atomnuke.org/), no matter where your data originates and who consumes the data, it could be this simple to think about._

**Atom Nuke Simplifies Integration**

We created [Atom Nuke](http://atomnuke.org/) to give ourselves two kinds of power related to the high volumes of data produced by our Atom feeds.

* _fission_, making it easy to divide data in new ways
* _fusion_, making it easy to combine data in new ways


{% img center 2012-09-12-rackspace-open-sources-atom-nuke-the-fast-atom-framework/atom-nuke-hardway-nonuke.png %}

_A six-way integration requires eighteen paths, connecting three data origins with three data consumers so each has direct and equal access. Adding one new origin or consumer requires adding many new paths._

Atom Nuke is an open-source collection of utilities built on a simple, fast Atom implementation that aims for a footprint of minimal dependency. The Atom implementation has its own model and utilizes a SAX parser and a StAX writer.

* [SAX](http://www.saxproject.org/) (Simple API for XML) makes it simple to read existing data
* [StAX](http://stax.codehaus.org/) (Streaming API for XML) makes it simple to stream data to and from applications

{% img center 2012-09-12-rackspace-open-sources-atom-nuke-the-fast-atom-framework/atom-nuke-easyway-nuke.png %}

_With Atom Nuke providing a bridge, a six-way integration requires six paths, one from each of the three origins and three clients, with each path terminating at Atom Nuke. Adding one new origin or consumer requires._

We designed our Nuke implementation for immutability, maximum simplicity and memory efficiency. Nuke also contains a polling event framework that can poll multiple sources. Each source may be registered with a configured polling interval that governs how often the source is polled during normal operation. That source may have any number of Atom listeners added to its dispatch list. These listeners will begin receiving events on the next scheduled poll.

##Atom as a Building Block

Atom is a self-discoverable and generic syndication protocol. The Internet Engineering Task Force (IETF) describes Atom in several ratified Requests for Comments (RFCs):

* the [Atom RFC](http://tools.ietf.org/html/rfc4287)
* the [Atom Paging and Archiving RFC](http://tools.ietf.org/html/rfc5005)
* the [Atom Publishing Protocol RFC](http://tools.ietf.org/html/rfc5023)

The unique properties of the Atom specification have made it popular as a protocol for generic event distribution, syndication and aggregation. Using Atom as a common interchange format, event publishers add their domain-specific events to an Atom publication endpoint. Downstream, subscribers are notified of events they've pre-identified as relevant, controlling what they consume from potentially-vast collections of published data.

##Atom Nuke Within Rackspace

Within Rackspace, the Cloud Integration team builds tools for all our software development teams to use. We need to provide high-quality tools but we also need them to be easy to use and work smoothly together so that we can encourage adoption throughout Rackspace.

Using Atom Nuke, we collect data from the Atom feeds supplied by [Atom Hopper](http://atomhopper.org/), another of our open-source tools. We then take that Atom data and feed it into several systems, including those that perform analytics on [OpenStack](http://openstack.org/) deployments throughout our data centers. The analytics engine uses Nuke to collect the entire Atom feed data so it can be marshalled into a [Hadoop](http://hadoop.apache.org/) cluster. By combining our Atom Nuke and Atom Hopper tools, we've enabled complete portability of data: we can combine Atom events with data from other sources such as [Rabbit MQ](http://www.rabbitmq.com/) messages and [Flume](http://flume.apache.org/) logs without requiring consumers of that data to deal with the complexities of interacting with those dissimilar sources.

##Nuke Makes Working with Atom Easy

Atom Nuke excels as a an Atom feed crawler, since you can poll multiple feeds from multiple endpoints as well as define the polling intervals down to milliseconds. In addition, you can select events in response to specific triggers, such as when a specific Atom entry contains a subscribed category. However, Nuke is much more than a feed crawler, it can create its own Atom feeds if needed.

We built Atom Nuke with [Java](http://java.com/) but we recently extended support to [Python](http://python.org/). Nuke is licensed under the [Apache 2 license](http://www.apache.org/licenses/LICENSE-2.0.html) and was created by [John Hopper](https://github.com/zinic), a software engineer on the Rackspace Cloud Integration team. We've created some tutorials to get developers [started with Nuke](http://www.giantflyingsaucer.com/blog/?cat=61).

##Building with Boxes, Not Bricks

Writing about a different kind of atom in a world that was just beginning to understand atomic structure and atomic energy, H.G. Wells (1866-1946) imagined a future in which using the power stored within atoms transformed many aspects of human life:

> "I feel that we are but beginning the list. And we know now that the atom, that once we thought hard and impenetrable, and indivisible and final and--lifeless--lifeless, is really a reservoir of immense energy. That is the most wonderful thing about all this work. A little while ago we though of the atoms as we thought of bricks, as solid building material, as substantial matter, as unit masses of lifeless stuff, and behold! these bricks are boxes, treasure boxes, boxes full of the intensest force."

---H.G. Wells, _The World Set Free_, 1914

We're now at a similar point with the technology of our time. We have explored enabling technologies, such as Atom, and have begun fully using and building upon their capabilities, putting them to work in new ways to make new things possible. As we begin building with Atom Nuke, we're using Atom not as a brick, but as a treasure box, containing amazing possibilities for fission and fusion, dividing and combining data to make new applications possible. By making Atom Nuke and some of our other projects such as [Atom Hopper](http://atomhopper.org/) available as open source, we hope we are also creating treasure boxes filled with ideas and possibilities.

To learn more about Atom Nuke, visit our [project site](http://atomnuke.org/) and check out the [source code on GitHub](https://github.com/zinic/atom-nuke/).
