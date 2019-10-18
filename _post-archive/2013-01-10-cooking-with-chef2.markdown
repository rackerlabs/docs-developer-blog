---
layout: post
title: 'Cooking with Chef, part 2'
date: '2013-01-16 08:00'
comments: true
author: Hart Hoover
categories:
  - Cloud Servers
  - Chef
  - Configuration Management
---
{% img right 2013-01-09-cooking-with-chef/chef_logo.png "Chef Logo" %}

Continuing the series on Chef that I started in [part one](https://devops.rackspace.com/cooking-with-chef.html), you should now have an account with Opscode and a working knife install. In this post, I will explain how cookbooks and roles work and we will deploy our first application with Chef.
<!-- more -->
##Cookbooks?

That's right, Emeril Lagasse, managing infrastructure with Chef means you are using cookbooks. Cookbooks are the way Chef users package, distribute, and share configuration details. A cookbook usually configures only one service. Let's look at the structure of a common cookbook like [Apache](https://github.com/opscode-cookbooks/apache2):

	knife cookbook site install apache2

	apache2
    	attributes
    	definitions
    	files
    	recipes
    	templates
    	test
    	CHANGELOG.md
    	CONTRIBUTING.md
    	Gemfile
    	LICENSE
    	README.md
    	metadata.rb

The first directory to look into is `attributes`, specifically `default.rb`. Here you can see all the things you can set for your Apache installation. Your recipes will read the attributes files for configuration details. You can see that there are different settings for different operating systems, meaning you can run this cookbook against Ubuntu, Red Hat, and other servers. This means the underlying operating system doesn't really matter - your Apache settings matter.

The next directory to look into is `recipes`. Recipes are Ruby files in which you use Chef's Domain Specific Language (DSL) to define how particular parts of a node should be configured. The default.rb file will be run through first to install the service, followed by module recipes. Inside a recipe you will see something similar to this:

```ruby
when "debian"

  package "libapache2-mod-php5"

when "rhel"

  package "php package" do
    if node['platform_version'].to_f < 6.0
      package_name "php53"
    else
      package_name "php"
    end
    notifies :run, "execute[generate-module-list]", :immediately
    not_if "which php"
  end
```

As you can see again, the cookbook is making decisions on what to do based on the operating system of the instance. In the case of Red Hat, it makes a decision on which version of PHP to install packages based on the version of RHEL you are running. There are hundreds of [community cookbooks](https://community.opscode.com/cookbooks) available to choose from, or you can [write your own](https://wiki.opscode.com/display/chef/Guide+to+Creating+A+Cookbook+and+Writing+A+Recipe).

Last but not least, look into the `templates` directory. This directory holds templates for your Apache configuration files. The template is filled in with information from your recipes and attributes files. Here is a snippet from the `apache2.conf` template, called `apache2.conf.erb`:

	ServerRoot "<%= node['apache']['dir'] %>"

This is typically set to /var/www but you can set it to whatever directory you like programmatically. Now that you have a very general idea of how cookbooks and recipes work, let's figure out how to apply these cookbooks to servers.

##Roles

We need to know how to define which servers get what cookbooks. Roles allow us to do that in Chef. Each role you specify would have a list of recipes it requires and in what order. In the Chef repository you should have from the first post in this series you have a roles directory:

	chef-repo/
		.chef/
		certificates/
		config/
		cookbooks/
		data_bags
		environments/
		roles/   <===== HERE

Role files can be Ruby DSL files that look like this:

```ruby
name "role_name"
description "role_description"
run_list "recipe[name]", "recipe[name::attribute]", "recipe[name::attribute]"
env_run_lists "name" => ["recipe[name]"], "environment_name" => ["recipe[name::attribute]"]
default_attributes "node" => { "attribute" => [ "value", "value", "etc." ] }
override_attributes "node" => { "attribute" => [ "value", "value", "etc." ] }
```

or JSON like this:

```json
{
  "name": "webserver",
  "chef_type": "role",
  "json_class": "Chef::Role",
  "default_attributes": {
    "apache2": {
      "listen_ports": [
        "80",
        "443"
      ]
    }
  },
  "description": "The base role for systems that serve HTTP traffic",
  "run_list": [
    "recipe[apache2]",
    "recipe[apache2::mod_ssl]",
    "role[montior]"
  ],
  "env_run_lists" : {
    "production" : [],
    "preprod" : [],
    "dev": [
      "role[base]",
      "recipe[apache]",
      "recipe[apache::copy_dev_configs]",
    ],
     "test": [
      "role[base]",
      "recipe[apache]"
    ]
   },
  "override_attributes": {
    "apache2": {
      "max_children": "50"
    }
  }
}
```

You can manage roles with the `knife` command:

	knife role create ROLE_NAME

This opens a text editor for you to create a role. Once created, apply it to servers:

	knife node run_list add NODE_NAME "role[ROLE_NAME]"

##Deploying with Knife

We have Chef installed, a very general grasp of roles and cookbooks, and you're ready to deploy an application. We're going to use the Opscode getting-started cookbook. The following steps will download the cookbook and put it in your Hosted Chef account for our use:

	cd ~/chef-repo
	knife cookbook site install getting-started
	knife cookbook upload getting-started

Create a role with this cookbook in the run list:

	knife role create startmeup

```json
{
  "name": "startmeup",
  "description": "Getting started with Rackspace",
  "json_class": "Chef::Role",
  "default_attributes": {
  },
  "override_attributes": {
  },
  "chef_type": "role",
  "run_list": [
    "recipe[getting-started]"
  ],
  "env_run_lists": {
  }
}
```

Now create a server with that role. I'm using a 512M instance with Ubuntu 12.10:

	knife rackspace server create -r 'role[startmeup]' --server-name startserver --node-name startserver --image 8a3a9f96-b997-46fd-b7a8-a9e740796ffd --flavor 2

You will see Chef creating the server and running the list of recipes we specified in the role “startmeup”, followed by this summary:

	Instance ID: 9bdc2a23-fbd3-4cda-a65a-1352a1ee9031
	Host ID: 047eafc7515bb90df88d799b735cd609e4f16333ab1463092d5c15cc
	Name: startserver
	Flavor: 512MB Standard Instance
	Image: Ubuntu 12.10 (Quantal Quetzal)
	Metadata: {}
	Public DNS Name: 65-61-189-188.static.cloud-ips.com
	Public IP Address: 65.61.189.188
	Private IP Address: 10.180.25.193
	Password: (redacted)
	Environment: _default
	Run List: role[startmeup]

**Congratulations**! You just bootstrapped a Cloud Server with Chef. Stay tuned for future posts on Chef - this series isn't over!
