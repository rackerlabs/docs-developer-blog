---
layout: post
title: Indiegogo uses Rackspace and Chef to handle massive traffic
date: '2013-06-19 08:00'
comments: true
author: Hart Hoover
published: true
categories:
  - Chef
  - Cloud Servers
---
{% img right 2013-01-09-cooking-with-chef/chef_logo.png "Chef Logo" %}

Recently, Opscode released a case study on Rackspace customer [Indiegogo][1] and their use of [Chef][2] to power their fundraising efforts. Last year, MTV came to Indiegogo and asked them to power their telethon fundraiser for Hurricane Sandy. Oh, and it had to be ready in FOUR DAYS. Indiegogo used the Opscode Hosted Chef platform and more than 500 [Rackspace Cloud Servers][3] to have 100% uptime throughout the entire event.<!-- more -->

Indiegogo coupled the scalability of the cloud with physical database servers to handle the immense traffic they received during the telethon. Using Hosted Chef and its [Knife API plugin for Rackspace][4], Indiegogo was able to configure all the necessary servers in one day’s time, an unprecedented undertaking for the crowd-funding leader.

You can read the Opscode blog post [here][5] or [read the case study][6].

[1]: https://www.indiegogo.com/
[2]: https://www.opscode.com/chef/
[3]: https://www.rackspace.com/cloud/servers/
[4]: https://github.com/opscode/knife-rackspace
[5]: https://www.opscode.com/blog/2013/05/28/indiegogo-crowd-funds-projects-around-the-world-wchef/
[6]: https://www.opscode.com/customers/indiegogo/
