---
layout: post
title: Cloud Monitoring adds PagerDuty integration
date: '2013-04-23 12:00'
comments: true
author: Justin Gallardo
published: true
categories:
  - Cloud Monitoring
---

{% img right 2013-04-22-cloud-monitoring-pagerduty/cloud_monitoring_pagerduty.png 160 160 %}[Cloud Monitoring](http://www.rackspace.com/cloud/monitoring/)
now supports [PagerDuty](http://www.pagerduty.com)
integration! With this new notification type, alarm notifications can
automatically create new incidents and resolve them once Cloud Monitoring
detects things are okay.

<!-- more -->

Because the [Cloud Control Panel](https://mycloud.rackspace.com/)
doesn't support creating notifications and notification plans,
[raxmon](https://github.com/racker/rackspace-monitoring-cli) is
one of the easier ways to set up PagerDuty notifications. If you haven't used raxmon
before, there is a great guide for setting things up
[here](http://devops.rackspace.com/using-raxmon-to-configure-rackspace-cloud-monitoring.html).

In order to do this, we just have to go through the following steps:

1. Figure out your PagerDuty service key.
2. Create the new PagerDuty notification.
3. Create or update a Cloud Monitoring notification plan.
4. Update an alarm to use your new notification plan.
5. Do a [happy dance](http://i.imgur.com/aqQK8IE.gif).

If you'd like to dive right into things, there is a [tl;dr](#tldr) at
the bottom of the page.

The first thing you need to do is make sure you have configured a
PagerDuty service to use with Cloud Monitoring.

1. In your PagerDuty account, under the Services tab, click "Add New Service."
2. Enter a name for the service, select an escalation policy, and choose "Generic API system" for the Service Type.
3. Click the "Add Service" button.
4. Once the service is created, the service page displays. On this page, you see
   the "Service key," which you need when you create your notification.

Next, you need to create the Cloud Monitoring
[notification](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-notifications.html) to
attach to a notification plan with the service key you've obtained from
PagerDuty. To do this with raxmon, do the following:

	 raxmon-notifications-create --type=pagerduty \
	 --details=service_key=abcd1234abcd1234abcd1234abcd1234

After you do this, raxmon returns a new ID for the notification that
looks similar to `nt23k123`. Keep this ID handy for the next step of creating a
[notification plan](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-notification-plans.html).

To view a detailed list of your existing notification plans, you can use the following
raxmon command:

	 raxmon-notification-plans-list --details

By default Cloud Monitoring has a single, dynamic notification plan
named `npTechnicalContactsEmail` that sends an email notification to each of the
technical contacts on your Rackspace account. If this is the only
notification plan you see, create a new one to take
advantage of the new PagerDuty integration.

Notification plans allow you to specify what notifications you want to
use per alarm state (that is, **OK**, **WARNING**, **CRITICAL**). This gives you the
flexibility of doing something like emailing on **WARNING** and actually
creating an incident in PagerDuty for **CRITICAL** events.
Use raxmon to do this by using the following command:

	 raxmon-notification-plan-create --ok-notifications=nt23k123 \
	 --warning-notifications=nt23k123 --critical-notifications=nt23k123

This command creates a new notification plan and returns an ID
that looks similar to `npTY46f7`. Your new notification plan
trigger an incident per alarm on **WARNING** and **CRITICAL** events and automatically
resolves the incident when an **OK** event is triggered.

**Note**: Incidents are triggered per alarm, meaning that a new incident is
created per alarm, as opposed to creating an incident per check or
entity. Any additional alarm state changes for an incident are appended
to the currently active incident until it is resolved.

If you wanted to trigger incidents on **WARNING** and **CRITICAL**
events and resolve the incidents with PagerDuty while also sending an
email notification (e.g. `nt76df3U`) on **OK** events, you could run the
following command:

 	 raxmon-notification-plan-create --ok-notifications=nt23k123,nt76df3U \
	 --warning-notifications=nt23k123 --critical-notifications=nt23k123

**Note**: Once you've created or updated your notification plan, you can use the
[Cloud Control Panel](https://mycloud.rackspace.com/) to configure
alarms to use it. Read on for how to do this with raxmon.

Next, identify which alarm you want to update. To do
this, list your alarms for an entity with the id of `enKEb23jB` by using:

	 raxmon-alarms-list --entity-id=enKEb23JB

This shows you the alarms associated with an entity and their
labels. If you would like more information about the alarms, you can use
the `--details` flag.

Your final step to take advantage of the new PagerDuty integration is
to [update your alarms](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-alarms.html#service-alarms-update)
to use your newly-created notification plan. Use
the ID that your call to `raxmon-notification-plan-create` returned and
the alarm ID you've picked out, and run the following command:

	 raxmon-alarms-update  --entity-id=enKEb23JB --id=alwp0UoI45 \
	 --notification-plan=npTY46f7

After doing this you are all set! Cloud Monitoring now
automatically triggers and resolves incidents through PagerDuty.

For more information visit the [Cloud Monitoring API documentation](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/overview.html).
If you have any questions or feedback, feel free to email the
[Cloud Monitoring team](mailto:monitoring@rackspace.com) or
join #rackspace on [irc.freenode.net](http://webchat.freenode.net?channels=rackspace).

<a name="tldr">**tl;dr**</a>

	# Create a new PagerDuty notification using the service key you've
	# created for Cloud Monitoring. This will return an ID that you'll use
	# when creating/updating a notification plan.

	raxmon-notifications-create --type=pagerduty \
	--details=service_key=abcd1234abcd1234abcd1234abcd1234

	# List existing notification plans to determine if you need to create
	# a new notification plan or can update an existing one.

	raxmon-notification-plans-list --details

	# Create a new notification plan using your newly-created PagerDuty
	# notification. Use the ID that this returns to update an alarm's
	# associated notification plan.

	raxmon-notification-plan-create --ok-notifications=nt23k123 \
	--warning-notifications=nt23k123 --critical-notifications=nt23k123

	# List your existing alarms for a specific entity to grab the alarm id
	# for the alarm you'd like to use PagerDuty notifications on.

	raxmon-alarms-list --entity-id=enKEb23JB

	# Update your alarm to use your new notification plan.

	raxmon-alarms-update --entity-id=enKEb23JB --id=alwp0UoI45 \
	--notification-plan=npTY46f7

