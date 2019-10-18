---
layout: post
title: Using Rackspace Cloud Monitoring to help reduce food waste.
date: '2014-03-03 12:00'
comments: true
author: Bill Hertzing
published: true
categories:
  - Cloud Monitoring
---

Losing a large amount of food in a freezer can be a costly and grueling task
to clean up. I know from personal experience. A few months ago we lost a
considerable amount of food due to a GFCI outlet that disconnected the
electrical circuit in our detached garage.

<!-- more -->

## The Problem

As Wikipedia explains, "A ground fault circuit interrupter
([GFCI](https://simple.wikipedia.org/wiki/GFCI)) is a device that shuts off an
electric circuit when it detects that current is flowing along an unintended
path, possibly through water or through a person. It is used to reduce the risk
of electric shock." Safety is always important. However, there is no
notification as to when an outlet has tripped.

In our case, the interrupter cut the flow of electricity (for a yet to be
determined reason) to the outlet the freezer was using in the garage.

This freezer holds food for long term storage meaning that we access it not
on a daily basis but only a few times a month. Another problem was that there
was no alarm or notification that the circuit had been disconnected and freezer
was without power.

## The Solution

To solve the problem I turned to the cloud. The primary goal was to find an
inexpensive way to monitor that circuit so that if it should fail, I would be
notified immediately.

The first thing was to put a device in the garage on the same outlet as the
freezer. I knew that if the freezer lost power, any device plugged into that
same outlet would also lose power. A small little Raspberry Pi Model: B is
perfect for this task. (Actually any small computer will do that is capable of
running a web browser.)  It's small, solid state and inexpensive. On the
device a simple default webpage is present on Port 80.

With the Raspberry Pi in place the next challenge is to let it be accessible
from the outside world. Residential broadband services often have dynamic IP
addressing. This means the IP address will change from time to time. This makes
constant, reliable monitoring a bit of a challenge.

To solve for this I used the services of DNSExit.com.  DNSExit provides a free
Second Level Domain service that allows you to create a host name that points
to a dynamic IP address. A small application runs on your computer and reports
the current dynamic IP address back to the service. When the IP address changes,
 the DNS records are immediately updated.

Finally, with the Raspberry Pi and DNS problems solved, it's just a matter of
setting up monitoring. For that I used Rackspace Cloud Monitoring. I created an
HTTP URL check that monitors the second level domain of the Raspberry Pi.
Creating the monitoring check is simple and easy. Just choose the check type,
give it a check name, and then provide the URL. Using URL with content match
was considered but not necessary.

With all three pieces in place, I now have an inexpensive monitoring system for
the electrical circuit. If the power is lost, the Raspberry Pi goes dark and I
get a monitoring alert sent to my email notifying me of the event.

Here's a photo of what it looks like.

{% img center 2014-03-03-using-rackspace-cloud-monitoring-to-help-reduce-food-waste/raspi.png %}

Next steps: I am debating as to whether or not I want to go wireless. I fear
it will create false alarms that could be avoided. Another added feature would
be one of a temperature sensor. They can be found online for around five
dollars. Naturally, the project can grow exponentially if you were to then use
a language like Python to capture and report on the data.
