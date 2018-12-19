---
comments: true
sharing: true
date: 2012-08-27T15:02:25.000Z
layout: post
author: Wayne Walls
title: Using raxmon to configure Rackspace Cloud Monitoring
categories:
  - Cloud Monitoring
  - nodejs
  - mailgun
  - jenkins
  - cloud networks
  - java
  - neutron
  - configuration management
---

With the [launch](http://www.rackspace.com/blog/monitor-any-cloud-or-web-infrastructure-with-new-rackspace-cloud-monitoring-now-in-unlimited-availability/) of Rackspace Cloud Monitoring (RCM) earlier this week, Rackspace has added an additional tool to your belt that shows you how your servers and applications are behaving. Cloud Monitoring makes it easy to configure monitors and alerts from the Control Panel, but today I want to focus on raxmon, one of the most flexible CLI tools available today for RCM.

<!-- more -->

Raxmon is a CLI tool written in python and uses the libcloud library to interface with the RCM API. We will use the [rackspace-monitoring-cli](http://pypi.python.org/pypi/rackspace-monitoring-cli/0.4.5) package which gives us the raxmon binary. The source code is currently hosted on [github](https://github.com/racker/rackspace-monitoring-cli), so if you find the tool valuable you can start contributing today!

Here, I will walk you through the installation and setup of raxmon and the five simple steps to follow to create and deploy a monitor:
	
  * Create or review Entities
  * Create a Check
  * Create a Notification Type
  * Create a Notification Plan
  * Create an Alarm

#### Installation and Setup - raxmon on CentOS 6.3


To install the rackspace-monitoring-cli package, you will need the python 'pip' command.  If you don't already have access to that tool, following these steps will put you in the driver's seat.

	$ yum install -y python-setuptools
	$ easy_install pip
	$ pip install rackspace-monitoring-cli

Now that the raxmon client is installed, the next step is to set up your credentials file.

	$ vi ~/.raxrc

`Sample .raxrc file`
	
{% codeblock lang:bash %}
[credentials]
username=YOUR_USERNAME_HERE
api_key=YOUR_APIKEY_HERE
	
[api]
url=https://monitoring.api.rackspacecloud.com/v1.0
	
[auth_api]
url=https://identity.api.rackspacecloud.com/v2.0
	
[ssl]
verify=true
{% endcodeblock %}

#####[Here](http://www.rackspace.com/knowledge_center/article/rackspace-cloud-essentials-1-generating-your-api-key) is where you can find your username and API key info

By now, you should have a working raxmon installation configured for use. Now we can move into monitor creation and deployment!


#### Review Entities


An entity is the target of what you are monitoring; this is where it all starts. If you already have Cloud Servers in your account, as I do in this example, you can run the following command to see what entities are available for monitoring.

	$ raxmon-entities-list

For this example, we will focus on the test domain www.datawithbenefits.com. Since "entity-id QnHuuY803S" is a little cumbersome to remember, I will assign it to an environment variable named "$ENTITY."  As more resource IDs are created throughout this exercise, I will use this same practice for standardization.


#### Create a Check


A check is the foundational building block of RCM. It determines the parts or pieces of the entity you wish to monitor. Checks contain many configurable options, but in this example I will set up a remote http check from three monitoring zones with an easy to remember label.


	$ raxmon-checks-create --entity-id=$ENTITY --label=CheckLabel_01 --type=remote.http --monitoring-zones=mzlon,mzdfw,mzord --details="url=www.datawithbenefits.com,method=GET" --target-hostname=www.datawithbenefits.com
	Resource Created ID:  $CHECK


**NOTES**:
	 
  * Monitoring zones:  mzdfw - mzord - mziad - mzlon - mzhkg
  * Available check types: remote.http, remote.tcp, remote.ping, remote.smtp, remote.mysql-banner, & [more](http://docs.rackspacecloud.com/cm/api/v1.0/cm-devguide/content/service-check-types.html#service-check-types-list)


#### Create a Notification Type


The next step is creating a notification. This is where you choose how you would like to be notified of event state changes. The two methods available today are email and webhook.


	$ raxmon-notifications-create --label=NotificationLabel_01 --type=email --details="address=wayne.walls@rackspace.com"
	Resource Created ID: $NOTIFICATION


#### Create a Notification Plan


Now that you have a notification setup, you need to attach a notification plan. In short, a notification plan contains a set of notification actions that RCM executes when triggered by an alarm.


	$ raxmon-notification-plans-create --label=NotificationPlanLabel_01 --ok-state=$NOTIFICATION --critical-state=$NOTIFICATION
	Resource Created ID: $NOTIFICATION_PLAN


In this example I set the OK state and the CRITICAL state to execute the same notification. If you created multiple notifications, you could assign each one to a particular state; for example, OK state goes to on-shift sysad and CRITICAL state goes to on-call engineer.


#### Create an Alarm


Alarms bind alerting rules, entities and notification plans into a logical unit. Alarms are responsible for examining the state of one or more checks and executing a notification plan.  An alarm will be triggered for www.datawithbenefits when an http GET is performed against the webserver and detects a state change -- 200 / 300 responses an return "OK," while 400 / 500's return "CRITICAL" --  as they are usually considered bad.


	$ raxmon-alarms-create --check-id=$CHECK --criteria="if (metric[\"code\"] regex \"^[23]..$\") { return OK } return CRITICAL" --notification-plan-id=$NOTIFICATION_PLAN --entity-id=$ENTITY_ID
	Resource Created ID: $ALARM


You have now completed the steps necessary to setup a monitor using raxmon. But before we call it a wrap, I recommend checking your work. Two ways to check that your monitor is working as expected is to check the access logs on your webserver for "Rackspace Monitoring" polls from multiple IPs.

	50.57.61.5 - - [24/Aug/2012:05:58:36 +0000] "GET / HTTP/1.1" 200 5039 "-" "Rackspace Monitoring/1.1 (https://monitoring.api.rackspacecloud.com)"
	50.56.142.147 - - [24/Aug/2012:05:58:36 +0000] "GET / HTTP/1.1" 200 5039 "-" "Rackspace Monitoring/1.1 (https://monitoring.api.rackspacecloud.com)"
	78.136.44.8 - - [24/Aug/2012:05:58:38 +0000] "GET / HTTP/1.1" 200 5039 "-" "Rackspace Monitoring/1.1 (https://monitoring.api.rackspacecloud.com)"


Or you can manually run your check from raxmon itself.

	$ raxmon-checks-test --entity-id=$ENTITY --type=remote.http --monitoring-zones=mzdfw --details="url=datawithbenefits.com,method=GET" --target-hostname=datawithbenefits.com
	[{'available': True, 'timestamp': 1345787969193, 'monitoring_zone_id': 'mzdfw', 'status': 'code=403,rt=0.070s,bytes=5039', 'metrics': {'code': {'data': '403', 'type': 's'}, 'tt_firstbyte': {'data': '70', 'type': 'I'}, 'truncated': {'data': '0', 'type': 'I'}, 'bytes': {'data': '5039', 'type': 'i'}, 'duration': {'data': '70', 'type': 'I'}, 'tt_connect': {'data': '34', 'type': 'I'}}}]

That's it folks! I hope you learned something useful today. If you see a way to do something different or more efficiently, please feel free to leave a comment. Your feedback is always welcome! Check back soon for more walkthroughs, tips and announcements!
