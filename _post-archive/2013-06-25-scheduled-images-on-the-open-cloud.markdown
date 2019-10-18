---
layout: post
title: Scheduled Images on the Open Cloud
date: '2013-07-02 08:00'
comments: true
author: Brian Rosmaita
published: true
categories:
  - Cloud Servers
---

So there's this feature in our first generation Cloud Servers called
**backup schedules**. You may have heard of it.  A lot of people liked
it so much that they told us that they didn't want to move to the
Rackspace Open Cloud until we built something like it there.  So we did.
We're calling this feature **Scheduled Images.**

<!-- more -->

First, let me explain what this feature does: it takes a daily snapshot of your server
without any intervention by you.   Whether the resulting image is a
backup depends on what you've got going on in your server.
For instance, with some RDBMS software, simply copying the files
underlying a running database and restoring those files is not a good
idea if you want a working database, so this feature may not be
suitable for all backup scenarios.

Second, about  scheduling:  with this feature, the image is
scheduled by us, and we don't tell you when since it's subject to
change at any time.  The reason for this is that we don't want
automatic snapshots to interfere with normal cloud image operations or to
adversely affect throughput througout the cloud.  We can spread out
the load more equitably and increase the probability of successfully  taking scheduled
images  if we make the schedule ourselves.

Third, there is one configuration option, the "retention" value.  It's
the number of scheduled images that your account will retain.
When a new automatic snapshot has been taken successfully, the
scheduled images service will remove the oldest scheduled images until
the retention value is reached.  The retention value can be
independently set for each of your servers.

Finally, there's no charge for using the scheduled images service--you
simply pay for the storage of your scheduled images at the same rate
you pay for storing your regular snapshots.

Scheduled images can be activated for any of your servers by using the
Cloud Control Panel, the Cloud Servers API (with the Rackspace
Scheduled Images Extension) or by using the python-novaclient (with
the Rackspace Scheduled Images Novaclient extension). It's a very simple feature to understand and
use.

The following links tell you pretty much everything you need to
know to use it:

*  [Rackspace Scheduled Images API Extension documentation](https://docs.rackspace.com/servers/api/v2/cs-devguide/content/ch_extensions.html#scheduled_images)
*  [Using the python-novaclient to manage scheduled images](https://support.rackspace.com/how-to/using-python-novaclient-to-manage-scheduled-images/)
*  [The Scheduled Images FAQ](https://support.rackspace.com/how-to/scheduled-images-faq/)
