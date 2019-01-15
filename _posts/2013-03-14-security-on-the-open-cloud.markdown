---
layout: post
title: Security on the Open Cloud
date: '2013-03-14 08:00'
comments: true
author: Hart Hoover
categories:
  - Security
---
{% img right pillars/pillar.png 160 160 %}
Security is a major concern for all hosting platforms, but in the cloud security has traditionally been a detractor to cloud adoption. Security concerns include:

* Identity and Access Management
* Configuration and Patch Management
* Endpoint and Network Protection
* Vulnerability and Asset Management
* Data Protection

I'll go through each one of these, including how to mitigate these risks on the Rackspace Open Cloud. We may highlight services and products you didn't know we had.<!-- more -->

##Identity and Access Management

When you sign up for a Rackspace Cloud account, you are given one username and API key to manage the entire account. What if you have multiple teams? What if you want to use different account credentials for development and production? You used to have to maintain seperate accounts for these functions. Today you can create additional users that can authenticate against the API with their usernames and passwords.

First, authenticate:

    curl -X POST https://identity.api.rackspacecloud.com/v2.0/tokens \
    -d '{ "auth":{ "RAX-KSKEY:apiKeyCredentials":{ "username":"$USERNAME", "apiKey":"$APIKEY" } } }' \
    -H "Content-type: application/json"

With your token, you can then create a user:

	curl –X POST https://identity.api.rackspacecloud.com/v2.0/users \
	-d '{"user": {"username": "$USERNAME", "email":"email@domain.com", "enabled": true, "OS-KSADM:password":"$PASSWORD"}}' \
	-H "Content-type: application/json" -H "X-Auth-Token: $TOKEN”

More information on the Identity API is available in the [documentation](http://docs.rackspace.com/auth/api/v2.0/auth-client-devguide/content/Overview-d1e65.html).

##Configuration and Patch Management

You can always use a configuration management platform like Puppet to make sure your packages are up to date. This is a sample Puppet manifest to make sure MySQL is always updated:

```ruby
package { "mysql-server":
	ensure => latest
}
```

You can also use Opscode's Chef to accomplish the same thing. Here is a sample recipe:

```ruby
package "apache2" do
  action :upgrade
end
```

If you haven't moved to a fully automated infrastructure yet, we offer Rackspace [Managed Cloud](http://www.rackspace.com/cloud/managed_cloud/). With a Managed Service Level, we provide patching services and make sure your servers are always up to date, automagically. New vulnerabilities are being discovered all the time, so it is extremely important to make sure the servers you have online are up to date.

##Endpoint and Network Protection

Did you know you can have isolated servers with [Cloud Networks](http://devops.rackspace.com/protect-your-infrastructure-servers-with-bastion-hosts-and-isolated-cloud-networks.html)? You can also manage IPTables on individual instances with configuration management. Here is an example using Puppet's [Firewall Module](http://forge.puppetlabs.com/puppetlabs/firewall):

```ruby
class my_fw::post {
  firewall { '999 drop all':
    proto   => 'all',
    action  => 'drop',
    before  => undef,
  }
}
```

Rackspace also manages network security for our customers' environments with a physical RackConnect Firewall. We of course also have security measures in place at the hypervisor, routing, and data center level.

##Vulnerability and Asset Management

Any public website is scanned by bots that are attempting to get access. Brute force attacks are commonplace.

Any public website is scanned by bots that are attempting to get access. Brute force attacks are commonplace. With [Cenzic or Trustwave](https://www.trustwave.com/Company/Cenzic-is-now-Trustwave) you can protect your web application against malicious attacks. You can also offload some of your traffic to a CDN service like [CloudFlare](https://www.cloudflare.com) that has built in security features.

##Data Protection

Did you know you can encrypt data with [Cloud Block Storage](https://support.rackspace.com/how-to/cloud-block-storage-overview/)? It's also important to use SSL when transmitting across the network. Again, you can also use an isolated network with Cloud Networks to further protect your sensitive data. You can even [link Cloud Networks and RackConnect togather](http://www.rackspace.com/knowledge_center/article/rackconnect-with-cloud-networks-faq) to take advantage of bare metal servers for certain applications.

##In Conclusion

Security is a huge issue on any platform. Combining Rackspace products with third-party cloud management products gives you the peace of mind when architecting an application on the cloud.
