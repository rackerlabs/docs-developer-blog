---
layout: post
title: Creating dynamic host files with Chef
date: '2013-09-04 08:00'
comments: true
author: Sri Rajan
published: true
categories:
  - Chef
  - Automation
---

Maintaining hosts files on standard *nix system has been traditionally done by hand. This becomes a challenge as the number of systems grow and this is more true in the Cloud model where you might add/delete servers at a higher rate.   One solution would be to use DNS and use a local zone to store your host name to IP mapping.  If you are in the automation using Chef world, here is another example on how to automatically generate the host file entries.<!-- more -->

Start by creating a cookbook

	knife create cookbook host_file_update

Then create the recipe

	recipes/default.rb

	---
	hosts = search(:node, "*:*")
	template "/etc/hosts" do
  	source "hosts.erb"
  	owner "root"
  	group "root"
  	mode 0644
  	variables(
    	:hosts => hosts,
    	:hostname => node[:hostname],
    	:fqdn => node[:fqdn]
  	)
	end

The above recipe uses this template file 

	templates/default/hosts.erb 
	---
	127.0.0.1   localhost
	8.8.8.8  google_dns

	<% @hosts.each do |node| %>
	<%= node['ipaddress'] %> <%= node['hostname'] %> <%= node['fqdn'] %>
	<% end %>

Since this is a regular Chef template file you can include static entries that you may want on all servers.  For the remainder you loop through your search results and populate the host entries. Once you apply this recipe to all servers in your setup, every chef run will automatically populate the host entries with the server names and IP

This recipe does a search across all nodes in your environment. Note, you can modify the search to return certain nodes only. For e.g you can limit it to production servers only. 
The same concept can be extended to a variety of other use cases. For e.g adding servers to a load balanced pool using the same search functionality

	search(:node, "chef_environment:_default")
	search(:node, "role:webserver")

Search is quite powerful and you can read more at [Chef Search](https://docs.opscode.com/essentials_search.html)

This simple example demonstrates the power of infrastructure as code as you can take principles of programming and configuration management and apply it to system administration.  

