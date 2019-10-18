---
comments: true
date: 2012-09-12T14:00:00.000Z
layout: post
title: Using your iPhone to bootstrap Cloud Servers
author: Hart Hoover
categories:
  - Cloud Servers
---

With the announcement of the latest [iPhone](https://www.apple.com/iphone/), the tech world is in a frenzy once again. In previous posts, I discussed configuring [Puppet on Cloud Servers](https://devops.rackspace.com/using-puppet-with-cloud-servers.html) and bootstrapping new servers with [libcloud](https://libcloud.apache.org/) and [Puppet](https://puppetlabs.com/puppet/what-is-puppet/). Here, I will go through the process of creating a new server with the Rackspace Cloud iPhone app that automatically bootstraps with Opscode's [Chef](https://opscode.com) or Puppet. With Chef you have the option to use either your own Chef server or Opscode's Hosted Chef platform.

<!-- more -->

#### Install the app

You can find the app in the [iTunes App Store](https://itunes.apple.com/us/app/rackspace-cloud/id327870903?mt=8). Once you install the app, log in with your username and password. After you sign in, click "Settings" on the account screen.

{% img center 2012-09-12-using-your-iphone-to-bootstrap-cloud-servers/app_settings.jpg %}

From here, you can see the options for both Chef and Puppet. I am starting with Puppet.

#### Using Puppet to bootstrap your servers

On the settings screen, click "Puppet" and toggle the switch from "Off" to "On". You will be presented with a text area where you can provide the URL of your puppetmaster server.

{% img center 2012-09-12-using-your-iphone-to-bootstrap-cloud-servers/app_puppet.jpg %}

Go back to your account page and click "Cloud Servers" then the "+" symbol to add a new Puppet client. After you choose the region, the iPhone app will give you the option to create multiple servers at once, as well as give you the option to use Puppet. Puppet will log to /var/log/puppet.out and /var/log/puppet.err on your new server(s).

{% img center 2012-09-12-using-your-iphone-to-bootstrap-cloud-servers/add_server_puppet.jpg %}

#### Using Chef to bootstrap your servers

If you would rather use Chef as a configuration management platform, the Rackspace Cloud app works just as well. You will need the Chef server URL (or you can use Opscode's Hosted Chef) and your Chef Validator Key. This can be entered manually or you can sync your key from iTunes. Using the same process as with Puppet, you can create multiple servers at once that are automatically bootstrapped with Chef.

{% img center 2012-09-12-using-your-iphone-to-bootstrap-cloud-servers/configure_chef.jpg %}

#### For more information...

You can find the full list of features of the Rackspace Cloud app for iPhone on the Rackspace [mobile page](https://www.rackspace.com/cloud/mobile/).
