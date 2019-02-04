---
layout: post
title: 'Service registry use cases: Storing service metadata in the registry'
date: '2013-02-21 08:04'
comments: true
author: Tomaz Muraus
categories:
  - General
---

_This is a guest post from Tomaz Muraus. Tomaz is a Racker and a project lead for the Rackspace Service registry product. He is also a project chair of [Apache Libcloud](http://libcloud.apache.org/), an open-source project which deals with cloud interoperability. Before working on Service Registry he worked on the [Cloud Monitoring](http://www.rackspace.com/cloud/monitoring/) product and before joining Rackspace, he worked at [Cloudkick](https://www.cloudkick.com/) helping customers manage and monitor their infrastructure. In his free time, he loves writting code, contributing to open-source projects, advocating for software freedom, going to the gym and cycling. Be sure to check out his GitHub [page](https://github.com/Kami)._

In November, we launched Service registry into preview. You can read all about it in the blog post titled [Keep Track Of Your Services And Applications With The New Rackspace Service registry](http://www.rackspace.com/blog/keep-track-of-your-services-and-applications-with-the-new-rackspace-service-registry/).

That post describes some common use cases for Service registry and contains information on how you can use it to make your application more highly available and responsive to changes. In this series of posts we take a deep look at some common use cases and illustrate them with code samples.

<!-- more -->

### Storing service metadata in the registry

Today we look at a simple use case of storing service metadata in the Service registry. This is one of the simplest use cases and allows you to get started with the product very easily.

Each service object in the Service registry has a metadata field that can store arbitrary string key and value pairs. Examples of some common values you can store in this field:

* Application version (e.g. git hash or svn revision number)
* Region where the service is running
* Datacenter where the service is running
* Timestamp when the service was started
* JMX port for Java services
* Stats port (if service is exposing metrics through fb303 or a similar interface)

{% img center 2013-02-21-service-registry-use-cases-storing-service-metadata-in-the-registry/service-registry-image.png %}

You can then use this information for different purposes:

* Displaying a list of services with their metadata on an internal dashboard
* Client side filtering based on some metadata attribute (e.g. all the services with a specific version, etc.)
* Finding services that are out of date (version metadata attribute doesn’t match the latest deployed version)
* Finding all the API services that have been running for more than 14 days

In this example, we use the [Node.js Service registry client](https://github.com/racker/node-service-registry-client) to retrieve all of the services with the tag “api” and perform client side filtering on the returned list to find all the services that have been running for more than 14 days.

This example only performs service retrieval and assumes that you already have multiple services registered in the Service Registry. You can find instructions on how to do that in the [Integration Instructions](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/integration-instructions.html) part of the documentation.

<script src="https://gist.github.com/Kami/211c73c307339f356279.js"></script>

### When to use configuration storage or service metadata?

Service registry offers another feature similar to service metadata storage called [Configuration Storage](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/overview.html). Outwardly, it may appear that these features serve identical purposes, but that is not true. They complement each other nicely and you get more out of the Service Registry if you use them together.

The primary purpose for the service metadata field is to store different values related to a service instance which are unlikely to change during the service lifetime. Examples of such attributes include:

* Unix timestamp of when the service has been started
* Service version
* IP address on which this service listens on
* Datacenter and region where this service is running

Configuration storage, on the other hand, is not linked to a particular service or session. It stays around when sessions and services come and go. The primary purpose of Configuration storage is to store configuration values that can and usually do change during a service lifetime. Examples of such values include:

* Number of partitions / shards some service is responsible for
* Database connection timeout
* A list of ip:port pairs of database server addresses
* Maximum thread pool size
* Connection retry delay
* Service state

Because this feature is geared toward values that change relatively often, you get notifications via the [events feed](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/concepts.html) when a value is updated or deleted. Your code can then consume those notifications to react to changes faster (e.g. re-initialize a connection pool with a new list of server addresses) without requiring a service restart.

Additionally, you may use namespaces to organize configuration values to suit your needs.

### Conclusion

Service registry is a new and unique product in the market. This means there are probably use cases we have not thought about. If you have use case for it that we have not described yet, [let us know](mailto:sr@rackspace.com)!

In subsequent posts we will look at more advanced use cases such as using Service registry for middle-tier load balancing and using events feed as one of the information sources for your automation system.

Note: Service registry is currently in closed preview available free of charge. If you don’t have access yet you can request it by filling out [this survey](https://surveys.rackspace.com/Survey.aspx?s=f3d6e51580ab4510a564487fafdafdfd).
