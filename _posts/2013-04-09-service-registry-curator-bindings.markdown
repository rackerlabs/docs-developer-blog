---
layout: post
title: Service registry bindings for Netflix Curator
date: '2013-04-10 08:00'
comments: true
author: Gary Dusbabek
published: true
categories:
  - General
---

### The problem

Have you ever set out to do something new, only to find yourself encumbered by a list of prerequisites that
must be figured out first?  For example, you would like to implement Awesome Feature X in your application.
But before doing that you have to figure out how to use a new library.  Except the documentation for that
library is not very good, or the examples are out of date, or... the list goes on.

<!-- more -->

Well, you are not alone. I feel that way all the time.  Good APIs don’t just do their jobs well--they are
also easy to consume.

{% img center 2013-04-09-service-registry-curator-bindings/feetshures.png %}

### We are here to help

One of the overarching goals of the [Rackspace Service registry](https://dfw.registry.api.rackspacecloud.com/)
(RSR) has been to ease consumption.  Some examples:

1. The REST API is public, but we maintain open source idiomatic client libraries to help developers including
   ([java](https://github.com/racker/java-service-registry-client),
   [node.js](https://github.com/racker/node-service-registry-client),
   [python](https://github.com/racker/python-service-registry-client),
   [twisted-python](https://github.com/racker/python-twisted-service-registry-client)).
2. We published an [integration guide](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/integration-instructions.html).
3. Based on feedback, we removed features that were not useful.

We can do better though.  We want it to be super easy to integrate the RSR into your software.
To that end, we are looking at ways to integrate the RSR into APIs and interfaces that are already
well established.

One API that we use in several places at Rackspace is
[Netflix Curator](https://github.com/netflix/curator).  Curator is a value-added wrapper around
[Apache Zookeeper](http://zookeeper.apache.org/).  Curator recently added some API interfaces that allows programmers
to use it as a [simple service registry](https://github.com/Netflix/curator/wiki/Service-Discovery).  We think that
is a good place to implement application-specific coordination.  In this case we wanted to make it easier for
programmers to use RSR.  We decided to create
[Curator bindings](https://github.com/racker/java-service-registry-client/pull/20) so that the Netflix API could be
used to register services with RSR.  The nice thing about the RSR
is that all calls are HTTP using a publicly specified API.  And of course you also benefit from our fanatical support.

Those bindings have been pushed and you are welcome to try them out now.

### Sample code

If you are already using Curator to register your services, it should be easy to give our the RSR a try.
Just follow these steps:


1. Make sure you have a [Rackspace Cloud](http://www.rackspace.com/cloud/) Account.  You need to know your user
   name and API key.
2. Add the following dependencies to your project <code>pom.xml</code>:
   <script src="https://gist.github.com/gdusbabek/5338824.js?file=pom_snippet.xml" type="text/javascript"></script>
3. Instrument your service class with <code>@Meta</code> tags and implement the implied <code>convert</code> interface
   (two methods):
   <script src="https://gist.github.com/gdusbabek/5338824.js?file=service_class_0.java" type="text/javascript"></script>
4. Replace your <code>ServiceDiscovery</code> instance with a Rackspace instance:
   <script src="https://gist.github.com/gdusbabek/5338824.js?file=rsr_discovery_build.java" type="text/javascript"></script>

That’s it!  Everything else should work the same.

There ere are a few differences you should be aware of:

1.  RSR will use one thread per client to heartbeat your service.  In the case of Curator, this is done by the
    Curator client instance that is required before you can register services.  This should not be a problem for
    most users, as we have observed that a single process generally maps to a single service.
2.  Curator and RSR use different means to serialize your service object.  Curator serializes the whole thing to
    JSON.  RSR only serializes the fields you annotate with <code>@Meta</code>.

A full [demonstration project](https://github.com/gdusbabek/rsr_curator) that shows how to use both a Zookeeper-backed
registry and a RSR-backed registry can be found among my github projects.  Feel free to use it as a jumping off point
for your own project integration.  Also, the gists from this blog post are all
[available on github](https://gist.github.com/gdusbabek/5338824).

### Future plans

We plan more integrations like this.  Where it makes sense, we will try to get our work committed upstream.

Our goal is for the RSR to be a building block that can be used by anyone for any application--including
applications that do not already use Rackspace products or APIs.  If you would like to find out more about how you can
use the RSR, fill out [this survey](https://surveys.rackspace.com/Survey.aspx?s=f3d6e51580ab4510a564487fafdafdfd),
and we’ll get it enabled for your Rackspace Cloud account.  Also, we are keen to hear your feedback.  If you need help
with anything mentioned in this blog post, or are stuck in any way using the RSR, help is only an email
away: [sr@rackspace.com](mailto://sr@rackspace.com).

