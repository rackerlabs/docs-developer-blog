---
layout: post
title: 'Scaling horizontally: Handling sessions on the open cloud'
date: '2013-03-28 12:00'
comments: true
published: true
author: Hart Hoover
categories:
  - Cloud Servers
---

{% img right pillars/pillar.png 160 160 %}
Wayne Walls wrote a great article on the Rackspace Blog around
[horizontal scaling](http://www.rackspace.com/blog/pillars-of-cloudiness-no-3-scaling-horizontally/),
a pillar of cloud application design. When designing applications in the cloud,
typically you need more than one server performing specific tasks.

{% tweet https://twitter.com/DEVOPS_BORAT/status/274366602252804096 align='center' %}

These groups of servers or roles or tiers are sometimes load balanced or exist
as a pool of servers polling a message queue for work.

<!-- more -->

In this article, I focus on the former - load balanced servers.

### Traditional session handling

{% img center 2013-03-28-scaling-horizontal/arch1.png %}

In traditional application design shown in the preceding example, you would need
to do something to manage sessions across these three servers. The most popular
ways are typically:

* Store a cookie on the end user's system
* Store sessions in Memcached
* Store sessions in some sort of database

With the advent of "[Do Not Track](http://www.zdnet.com/googles-chrome-finally-embraces-do-not-track-but-with-a-warning-7000007022/)" browser plugins (or DNT being built into the browser itself) the first option may not work for everyone anymore.

Storing sessions in Memcached? It isn't [recommended](https://code.google.com/p/memcached/wiki/NewProgrammingFAQ#Why_is_memcached_not_recommended_for_sessions?_Everyone_does_it!) by the Memcached developers:

> Why is memcached not recommended for sessions? Everyone does it!

> If a session disappears, often the user is logged out. If a portion of a cache disappears, either due to a hardware crash or a simple software upgrade, it should not cause your users noticeable pain.

Storing sessions in a database means extra load on that database - something you definitely do not want in the cloud. It also could mean lag time while replication occurs to any number of slaves (in the case of a relational database) or replica sets (in the case of NoSQL). A less-than-ideal service experience occurs when your end user refreshes a page and hits a node without their session data. At the very least it means they get logged out of your service, at most it could mean their shopping cart gets reset.

So what can be done about sessions? You need a session to live SOMEWHERE and you need it to be trusted. Enter Representational State Transfer ([REST](http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm)) applications and authentication tokens.

### Using a ReSTful application

Some of you may be reading this and thinking "Sessions and REST? That makes no sense." You would be correct. We're basically solving for sessions while scaling... by not using sessions.

RESTful web services are stateless, meaning your application will not store any state information with regards to the client. When the client makes a request, each request happens in isolation. Each request also occurs with an authentication token. Because I'm not a fan of managing authentication ourselves (maintaining a database of authentication tokens) I recommend using a service like [Stormpath](http://stormpath.com). Offloading your authentication to a third party allows you to focus on things that matter to your business, like your application or product.

When your customer or user logs in, they authenticate with Stormpath and receive a token. This token then allows them to interact with any server in your web tier - the token is sent each time. There is no need for a "master" server and "slave" servers, because each server is the same. This allows you to scale horizontally very easily. An example of ReST in action? The Rackspace Open Cloud itself!

### How the open cloud uses authentication tokens

When you authenticate against our Identity service, you receive an authentication token to use for subsequent requests. The token is good for 24 hours and allows you to interact with many cloud services. Each time you perform an API request with that token, a check is made to make sure the token is still valid. The underlying infrastructure doesn't care where the request came from and doesn't care about a session - each request is handled separately. This allows us to scale our API services horizontally to meet demand.

Finally, it's important to note that moving an application to the cloud is not just a simple drag-and-drop process. To truly take advantage of the agility the cloud offers, changes may have to be made to existing applications. Combining horizontally scalable tiers of servers with the agility of a cloud platform makes your entire application scale on demand.
