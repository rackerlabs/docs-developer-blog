---
layout: post
title: Getting Bureaucratic with Papertrail
date: '2012-12-21 09:05'
comments: true
author: Hart Hoover
categories:
  - Cloud Servers
---
Imagine the situation: you're a Racker, and a customer calls. Their servers are up, but their application or site is offline. Time to shine! Unfortunately, they don't have any idea what is going on and they are frantic. The account has 20 servers listed and they are named after the characters in [The Hobbit](https://en.wikipedia.org/wiki/Characters_in_The_Hobbit).

It's an emergency situation, and you are wandering into a dark room with a lighter as a flashlight. In the cloud, with the possibility of hundreds (or thousands) of servers, that dark room becomes [Cowboys Stadium](https://stadium.dallascowboys.com/).  Where do you start?

Hopefully the customer has good monitoring in place so you can pinpoint the failure to a single server or a group of servers. With [Papertrail](https://papertrailapp.com), it becomes easier to find issues present in your application, and more importantly, _take action_ on the issue in an automated way. Papertrail helps detect, resolve, and avoid infrastructure problems using log messages. You can aggregate and manage log messages from Cloud Servers, Managed Hosting, Hybrid Hosting, and other servers — both flat files and rsyslog.
<!-- more -->
##Setting up Papertrail Manually
Once you [sign up](https://papertrailapp.com/) for an account, Papertrail has pretty quick setup instructions:

* Find out what logger you're running:
`ls -d /etc/*syslog*`

* Assuming you have rsyslog, edit your rsyslog.conf file and put this at the bottom:
`*.*          @logs.papertrailapp.com:12345`

The port may be different for your account. Be sure to check your settings! This also logs everything - if you only want to monitor certain logs (for example, application logs) make sure you specify only those log files.

* Restart syslog:
`sudo /etc/init.d/rsyslog restart`

Done! Papertrail will start getting your logs. That's great and all, but editing files by hand across hundreds of servers? _No, thank you._ I'd rather automate this with [Puppet](https://puppetlabs.com/puppet/what-is-puppet/). (Need help getting started with Puppet? Check out this [prior post](https://devops.rackspace.com/using-puppet-with-cloud-servers.html) for a refresher.)

##Automating Papertrail setup using Puppet
Luckily, there is a [Puppet module](https://github.com/Benjamin-Ds/puppet-module-papertrail) you can use to automate Papertrail setup (Thank you, Mr. Santos). It's just a matter of installing the module on your puppetmaster, configuring it for your needs, and making sure your puppet clients update with the new configuration. For this example, I'm using Ubuntu 12.10.

* Install git and clone the GitHub repository

```bash
apt-get -y install git
git clone git://github.com/Benjamin-Ds/puppet-module-papertrail.git /etc/puppet/modules/papertrail
```

* Edit `/etc/puppet/modules/papertrail/manifests/init.pp` and change the settings to match your account.
* Edit your puppet configuration file (example: `/etc/puppet/manifests/site.pp`) and add the following:

```ruby
node nodename {
    class {
        'papertrail':
        port => 12345,
        optional_files => ['/var/log/something.log']
    }
}
```

* Run puppet!

You should see the configuration on your nodes, and you should also see them show up in the Papertrail dashboard. If you have issues, try disabling the TLS encryption configuration present in the Puppet module.

##I'm logging to Papertrail. Now what?
Time to put those logs to work. Log into your Papertrail dashboard and search for something important to you. As an example, I've sent all my logs to Papertrail and I want to set up an alert for login failures:

{% img center 2012-12-18-getting-bureaucratic-with-papertrail/ssh-login.png %}

Save the search and create an alert. Papertrail will ask you where the alert should be sent. You can pick from the following services:

* [Boundary](https://boundary.com/): annotate a Boundary network traffic graph with the log message.
* [Campfire](https://campfirenow.com/): send a chat message to a Campfire room. It contains the logs and a link.
* Email: send an email to a set of addresses of your choosing.
* [GeckoBoard](https://www.geckoboard.com/): update a custom "number" widget with the count of matches.
* [HipChat](https://hipchat.com/): send a chat message to a HipChat room. It contains the logs and a link.
* [Librato Metrics](https://metrics.librato.com/): graph the number of occurrences over time.
* [PagerDuty](https://pagerduty.com/): invoke an alert escalation policy, such as generating text messages.

You can also send the alert to a [webhook](https://help.papertrailapp.com/kb/how-it-works/web-hooks) for custom alert handling.

##For more information
If you're interested in adding Papertrail to your solution, there is a seven day free trial you can take advantage of to test it out. More details are available from Papertrail's [website](https://papertrailapp.com).

**UPDATE**: I need to clarify the free trial: Papertrail has a free tier of service that never expires, and provides a bonus of extra storage for the first month. You can select any plan with a risk free trial of seven days.
