---
layout: post
title: 'Cooking with Chef, part 1'
date: '2013-01-11 08:00'
comments: true
author: Hart Hoover
categories:
  - Cloud Servers
  - Chef
  - Configuration Management
---
{% img right 2013-01-09-cooking-with-chef/chef_logo.png "Chef Logo" %}

As I said in a [prior post](https://devops.rackspace.com/using-puppet-with-cloud-servers.html) on Puppet, many of our customers use configuration management packages to manage their cloud infrastructure. These packages include Opscode’s [Chef](https://www.opscode.com/chef/), [CFEngine](https://cfengine.com/), Red Hat’s [Spacewalk](https://spacewalk.redhat.com/), and Puppet Labs’ [Puppet](https://puppetlabs.com/puppet/what-is-puppet/). Here, I’ll dive into Chef to show you how easy it is to manage Cloud Servers using a configuration management solution. In this series I'll walk you through setting up Hosted Chef using Opscode's platform, deploying your first application to Rackspace with Chef, and more.
<!-- more -->
##¿Habla usted Chef?
When using any new technology, it's important to know the terms associated with it so you can speak the language. Using Chef you will run into the following terms:

* Nodes - these are servers: physical machines or cloud instances.
* Environments - a group of nodes with different functions.
* Roles - a means of grouping nodes with the same function. Nodes can have multiple roles.
* Cookbooks - a collection of recipes, attributes, and templates that Chef uses to configure a node.
* Data Bags - a global variable that is stored as JSON data and is accessible from a Chef server. They usually contain sensitive information such as passwords.
* Knife - a command line utility to manage Chef.

Here is a way to use these terms in describing a WordPress environment:

>An Apache cookbook and a PHP cookbook are used to install Apache and PHP on nodes that fall into the "webserver" role in the "Production" environment. A MySQL cookbook is used to install MySQL on nodes that fall into the "database" role in my "Production" environment. The "Production" environment is a WordPress blog that has web nodes with Apache/PHP and database nodes with MySQL.

##Get started with Opscode
You can host and manage your own Chef server, but Opscode offers a free trial for five nodes or less so it's perfect for our purposes. You can create an account for the free trial [here](https://www.opscode.com/hosted-chef/).

Once your account is created, you will need to [set up your local machine as a management workstation](https://docs.opscode.com/install.html) to manage Chef. The Chef documentation is very detailed on the steps required, which differ depending on your local operating system. In the Opscode walkthrough, you will set up a chef repository that looks like this:

    chef-repo/
		.chef/
		certificates/
		config/
		cookbooks/
		data_bags
		environments/
		roles/

Your local machine does not need to be a Chef client. You will need three files on your local machine in your `.chef` directory, all downloadable from Opscode:

    knife.rb
    ORGANIZATION-validator.pem
    USER.pem

##Use Knife with Rackspace
After you have gone through the Opscode setup, knife is installed and configured. Now you need to install the [knife-rackspace](https://github.com/opscode/knife-rackspace) plugin:

    gem install knife-rackspace

Next, add the following to your `knife.rb` file:

    knife[:rackspace_api_username] = "Your Rackspace API username"
	knife[:rackspace_api_key] = "Your Rackspace API Key"
	knife[:rackspace_version] = 'v2'
	
You also can specify a region if you always build in the same place.

	knife[:rackspace_endpoint] = "https://dfw.servers.api.rackspacecloud.com/v2"

If your `knife.rb` file will be checked into a SCM system (ie readable by others) like GitHub or SVN you may want to read the values from environment variables:

    knife[:rackspace_api_username] = "#{ENV['RACKSPACE_USERNAME']}"
	knife[:rackspace_api_key] = "#{ENV['RACKSPACE_API_KEY']}"

##To be continued!
Now that you know a little about Chef and have knife working on your local machine, you are ready to start deploying Rackspace Cloud Servers with Chef. In part two of this series, I'll go into cookbook structure and provision your first application with Chef on the Rackspace Cloud. Stay tuned!
