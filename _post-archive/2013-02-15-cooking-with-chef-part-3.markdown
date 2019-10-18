---
layout: post
title: 'Cooking with Chef, part 3'
date: '2013-02-15 08:00'
comments: true
author: Hart Hoover
categories:
  - Cloud Servers
  - Chef
  - Configuration Management
---
{% img right 2013-01-09-cooking-with-chef/chef_logo.png "Chef Logo" %}

This is the third post in a series on Chef:

* [Part one](https://devops.rackspace.com/cooking-with-chef.html): Introduction to Chef
* [Part two](https://devops.rackspace.com/cooking-with-chef2.html): Cookbooks and Deploying with Knife

In those posts I used Opscode's Hosted Chef platform. There are three options for running the Chef Server:

* **Hosted Chef**: Hosted Chef is a version of a Chef server that is hosted by Opscode. Hosted Chef is cloud-based, scalable and available (24x7x365), with resource-based access control. Hosted Chef has all of the automation capabilities of Chef, but without requiring it to be set up and managed from behind the firewall.
* **Private Chef**: Private Chef is a version of a Chef server that is designed to provide all of the infrastructure automation capabilities of Chef and is set up and managed from within the organization.
* **Open Source Chef**: Open Source Chef is an open source version of the Chef server that contains much of the same functionality as Hosted Chef, but requires that each instance be configured and managed locally, including performing data migrations, applying updates to the Open Source Chef server and ensuring that the Open Source Chef server scales as the local infrastructure it is supporting grows. Open Source Chef includes support from the Chef community, but does not include support directly from Opscode.

This post focuses on installing your own Open Source Chef.
<!-- more -->
##Why would I want to run Chef on my own?
You may want to run more than five nodes without a monthly fee. You may want to manage how Chef itself gets updated. You may want to host Chef privately, but without the expense of Private Chef. Whatever the reason, installing the Chef server will help you further understand how Chef works.

##Get started
For this example we'll use Ubuntu 12.04. Opscode provides packages via an APT repository for Debian and Ubuntu servers, which makes this process a lot easier. First, we'll create a server using the `rackspace-novaclient` with an SSH key:

	nova boot --image 5cebb13a-f783-4f8c-8058-c4182c724ccd --flavor 3 --file /root/.ssh/authorized_keys=/Users/hhoover/.ssh/id_rsa.pub chefserver

If you like your servers to be fully updated before you start work, you can update all the packages and reboot:

	apt-get update && apt-get -y upgrade && reboot

Next, you need to install the Opscode repository and the GPG key:

	echo "deb https://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
	
	mkdir -p /etc/apt/trusted.gpg.d
	gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
	gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
	
Then update your repositories again and install the opscode-keyring package. This package keeps your key up to date. Then install Chef:

	apt-get update && apt-get install opscode-keyring
	apt-get install chef chef-server

Installing Chef also installs several dependencies. You prompted for some configuration details:

* URL for Chef - https://chef.example.com:4000
* A password for RabbitMQ
* A password for the Web UI

Congrats! You have a self-hosted Chef Server. I recommend following this up by [configuring `knife`](https://wiki.opscode.com/display/chef/Installing+Chef+Server+on+Debian+or+Ubuntu+using+Packages) to work with your new Chef server.
