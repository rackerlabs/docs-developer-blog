---
layout: post
title: Agility in the Rackspace Open Cloud
date: '2013-03-21 8:00'
comments: true
author: Hart Hoover
categories: []
---
{% img right pillars/pillar.png 160 160 %}
Being able to roll with the punches in a cloud environment is extremely important. The cloud can be used for a steady state environment, but really shines when coupled with monitoring and the API. Every application in the cloud should fit in one of these four buckets:

* On and Off
* Variable Workloads
* Consistent Workloads
* Fast Growth

Each workload makes you work a little differently, but using a traditional hosting model where you have the same number of compute workers all the time invariably creates waste.<!-- more -->

Let's look at these cloud workloads:

{% img center 2013-03-19-agility/workloads.png %}
<p style="text-align: center; font-size: 85%">The red line represents resource usage. The dashed line represents infrastructure capacity.</p>

If you are successful and get more traffic than expected, your application performance suffers because there aren't enough resources to go around. You hope the application remains available but eventually your application may just get knocked down if you don't react quickly to meet demand.

Testing your application with tools like [Apache Benchmark](https://httpd.apache.org/docs/2.2/programs/ab.html), [Siege](https://www.joedog.org/siege-home/), [Phoronix Test Suite](https://www.phoronix-test-suite.com/), or [Apica](https://www.apicasystem.com), [uTest](https://www.utest.com), [CapCal](https://www.gridrobotics.com/solutions/capcal-web-performance-testing) or [SOASTA](https://www.soasta.com) allows you to know ahead of time when to scale your infrastructure up or down. Once you know what your limits are, you can use Cloud Monitoring and the API to create or delete Rackspace Cloud Servers as needed to meet demand. Going back to the above image, you want the dashed line of "used infrastructure" to be as close to the needed capacity (the red line) as possible. On top of that, you can now use [Vagrant with the Rackspace Cloud](https://devops.rackspace.com/vagrant-now-supports-rackspace-open-cloud.html) if you want to test new features outside of production.

Assuming you have already tested your application or service and know the limits. Now you need to plug those limits into [Rackspace Cloud Monitoring](https://www.rackspace.com/cloud/monitoring/) and set a webhook to scale on demand. Cloud Monitoring has three statuses: "OK", "WARNING", and "CRITICAL". Setting thresholds for "WARNING" and "CRITICAL" gives you the flexibility to send a notification if either status change occurs, or take no action on one status change but not the other. A webhook notification payload will contain the following fields:

* **eventId**: The ID for the event in the system.
* **logEntryId**: The ID for the log entry.
* **entity**: The entity record that triggered the alert.
* **check**: The check record that triggered the alert.
* **alarm**: The alarm record that triggered the alert.

Customers today are using webhooks for a variety of tasks, including talking to other notification services like [Twilio](https://www.twilio.com/) or [PagerDuty](https://www.pagerduty.com/). The absolute best outcome is to have your webhook talk to your application directly to request more resources. Your application can then scale itself up or down based on the monitoring status change. For example, when a status changes from "OK" to "WARNING" or from "WARNING" to "CRITICAL", you can tell the API to create more servers. In this example, I'm using the [Python SDK](https://github.com/rackspace/pyrax) because I want to create a new 512MB Ubuntu 12.04 server:

```python
#!/usr/bin/env python
import pyrax

pyrax.set_credential_file("/path/to/credential/file")
cs = pyrax.cloudservers

ubu_image = [img for img in cs.images.list()
        if "Ubuntu 12.04" in img.name][0]

flavor_512 = [flavor for flavor in cs.flavors.list()
        if flavor.ram == 512][0]

server = cs.servers.create("new_server", ubu_image.id, flavor_512.id)
```

When the status changes back to "OK", you can start to scale back down. In this example we are deleting the server we just created:

```python
#!/usr/bin/env python
import pyrax

pyrax.set_credential_file("/path/to/credential/file")

pyrax.cloudservers.servers.find(name="new_server").delete()
```

These examples are pretty basic, but they illustrate the fundamental change you can make with the agility of the cloud. Each notification you send can be sent to a different script to perform specific tasks. Tying Cloud Monitoring to your application allows you to really save money - you are truly only paying for what you need!
