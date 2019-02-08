---
layout: post
title: 'DevOps automation series: Images vs. config management'
date: '2014-03-04 15:00'
comments: true
author: Matthew Thode
published: true
categories:
  - DevOps
  - Configuration Management
---


A question that often comes up is "why should I use config management when I
can just use images?" In this article, we’ll explore the differences between
images and configuration management, and talk about the benefits and drawbacks
of each.

<!-- more -->

### The case for images

The primary use case for images is to quickly spin up a base server that you
can then make minimal modifications to in order to reach your desired end state.

Another common use case is to use imaging as a way to create backups of
running servers. This however is not a good backup strategy, which we'll
discuss in the next section.

### The case against images

Images are by definition inflexible and out of date because as soon as you
build an image, any change to the base server will invalidate the image you
took. Images are also more difficult to backup safely and add an additional
layer of complexity in deployment.

As mentioned above, taking an image of an instance does not make a backup.
There are several reasons for this: 1. Snapshotting an entire disk will
capture far more data than is actually needed for a backup. Backups should
focus solely on the important content. 2. Snapshots do not stop processes
that may be writing to the filesytem (i.e. your database). 3. Using images as
a backup means you'll probably be overzealous with your snapshots because
you'll be taking snapshots of multiple machines possible capturing the same
data multiple times. 4. File-level restore is very difficult if not impossible
with a snapshot. This also doesn't scale far as you get into tens or hundreds
of machines.

### The case against configuration management

Complexity can be a big issue for some since it means a larger learning curve
and can seem like more to manage. It can also require bringing more people up
to date with the new way of doing things, which can be expensive in both time
and money.

It's also easier to log in and make a small change on a machine instead of
following a complicated process to change a cookbook, upload it and re-run
you configuration management tool.


### So, what to use...

{% img center 2014-03-04-devops-automation-series-images-vs-config-management/advice_dog.png %}

We recommend a slightly dynamic approach: use both. Use an image to build up a
base, install the things needed everywhere like Chef, a custom version of
Ruby, Java, the Nokogiri gem, etc., but always install items that can be
configured after the fact with your configuration management tool if needed.
You can then boot it with your chosen configuration management solution and
continue the configuration in a speedier manner. It’s the best of both worlds.


### The case for configuration management

One of the biggest benefits of configuration management is speed of deployment.
When using configuration management, you define all of the steps needed to go
from a base image to a fully configurable and usable image. By doing this you
take out a lot of downtime between steps of deployment. You are able to enter
one command, which will create an instance, configure it and then start using
it. You can even speed this up a little further, but I'll get into that soon.

Next is consistency. Positive confirmation of the state of an instance can be
a powerful thing. By using configuration management you are able to ensure
that your systems are in a known state. If you need to edit your sshd_config
file to deny root logins, you can do that to all instances at once and be told
if the configuration applied correctly. You can also ensure that your backups
are done consistently and even verify them in an automated manner.

Configuration management also brings flexibility to the application by
allowing the configuration you deploy to inspect the environment for the
status of other instances. For example, we can do some automated configuration
of an Apache server's environment variables by searching for the values that
those variables need to be and automatically setting them (issuing a reload if
the file changes). If you add or remove an instance whose value causes one of
the variables to change then it updates automatically. This allows you to be
more dynamic and flexible with your deployments.

