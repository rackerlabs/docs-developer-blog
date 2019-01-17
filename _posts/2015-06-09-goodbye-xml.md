---
layout: post
title: Goodbye XML!
date: '2015-06-09 23:59'
comments: true
author: Brian Rosmaita
published: true
categories:
  - OpenStack
  - Cloud Servers
bio: >-
  Brian Rosmaita is a software developer on the Rackspace team that works on
  Cloud Servers and Cloud Images (that's Nova and Glance in OpenStack
  language).  Upstream at OpenStack, he's a driver for the Glance and
  Searchlight teams.  You can find him on Freenode as rosmaita.  Use @br14nr if
  you want to tweet at him.
---
As a developer working in the cloud, you're probably aware that OpenStack
(and the cloud industry in general) have moved away from supporting XML APIs.
In fact, OpenStack has just eliminated XML support for the Compute v2 API in
its latest "Kilo" release.  In our quest at Rackspace to be as consistent
as possible with upstream OpenStack, we are planning to follow suit.  The
last day of XML support in the Rackspace public cloud will be July 20, 2015.

<!-- more -->

## But what about all the people who use XML?

There actually aren't very many.  In the Rackspace public cloud, only
0.2% of current Next Generation Cloud Servers API requests either pass XML
in the request body or request XML responses.

Remember, we're only talking about XML usage with the Next Generation
Cloud Servers (Compute v2) API.  You're perfectly free to use XML in
any other context you like, for example, as a data interchange format
for messages sent among your fleet of cloud servers.  We're not making
a moral judgement about XML usage, we're just saying that you'll no
longer be able to pass it in a request body or ask for it as a
response format when you communicate with the Rackspace Next
Generation Cloud Servers API.

## Dang! I'm using XML ... what can I do?

### If you're using an SDK ...

If you are using a cloud software development kit (SDK), please
update it. The latest version should be able to communicate with all
OpenStack clouds using the supported JSON serialization format.

### If you're using a custom script ...

If you are using a custom script without an SDK, you'll have to change
your script to process JSON instead of XML. We strongly recommend,
however, that you change your script to use one of the many available
SDKs for various programming languages. The advantage to using an SDK
is that it will expose a well-defined interface to your script, thereby
making your script easier to maintain. You can find a list of SDKs that
you can use to connect to the Rackspace cloud right here on our
developers' website:

[https://developer.rackspace.com/sdks/](https://developer.rackspace.com/sdks/)

### If you like to do it by hand ...

If you prefer to do things by hand, you'll need to modify your scripts
so that instead of sending XML, they'll send JSON request bodies. The
correct format for JSON requests can be found in the [Compute API
documentation](http://docs.rackspace.com/servers/api/v2/cs-devguide/content/ch_preface.html).
Be sure that your scripts specify "Content-type: application/json"
in the request header.

You'll also need to change your scripts to parse JSON responses. Again,
the response format you can expect can be found in the [Compute API
documentation](http://docs.rackspace.com/servers/api/v2/cs-devguide/content/ch_preface.html).
Make sure that your request either contains no "Accept" header, or that
it explicitly specifies "Accept: application/json" in the request
header.

How easy a transition this will be depends upon what scripting language
you are using. Some languages (Python, for example) handle JSON
serialization/deserialization much more easily than others. If you need
to do a major rewrite of your scripts, we strongly recommend considering
using an SDK instead of a "raw" language ... it will make upgrades much
easier on you.

## Could I be using XML without knowing it?

I've spoken with a few customers who were making XML requests without
knowing it.  In some cases, this is because they were using an older
version of an SDK that still used XML.  The most recent versions of
currently maintained OpenStack SDKs don't use XML, so an upgrade will
fix this problem.

## Goodbye XML!

In conclusion, mark July 20, 2015 on your calendar as the last day of
XML support for the Rackspace Cloud Servers API.  If you have questions
or comments about this transition, feel free to reach out to your Account
Manager.
