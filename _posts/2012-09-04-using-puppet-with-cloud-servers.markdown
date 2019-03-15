---
comments: true
sharing: true
date: 2012-09-04T08:47:56.000Z
layout: post
title: Using Puppet with Cloud Servers
author: Hart Hoover
categories:
  - Cloud Servers
  - jclouds
  - cloud files
  - java
---

Many of our customers use configuration management packages to manage their cloud infrastructure. These packages include Opscode's [Chef](http://www.opscode.com/chef/), [CFEngine](http://cfengine.com/), Red Hat's [Spacewalk](http://spacewalk.redhat.com/), and Puppet Labs' [Puppet](http://puppetlabs.com/puppet/what-is-puppet/). Here, I'll dive into Puppet to show you how easy it is to manage Cloud Servers using a configuration management solution. We're going to create two servers: a puppetmaster and a client server running puppet.

<!-- more -->

#### Create a puppetmaster and client


First, we need to create the Cloud Servers that will serve as our puppetmaster and client. I'm using the [novaclient](http://devops.rackspace.com/getting-started-using-python-novaclient-to-manage-cloud-servers.html) to create Ubuntu 12.04 servers for this purpose:


    nova boot --image 5cebb13a-f783-4f8c-8058-c4182c724ccd --flavor 3 --file /root/.ssh/authorized_keys=/Users/hart.hoover/.ssh/id_rsa.pub master
    nova boot --image 5cebb13a-f783-4f8c-8058-c4182c724ccd --flavor 3 --file /root/.ssh/authorized_keys=/Users/hart.hoover/.ssh/id_rsa.pub client


Once the servers are built, log in and update all your packages:

```bash
apt-get update && apt-get -y upgrade && reboot
```

Now we are ready to configure puppet.


#### Install puppetmaster on "master"


You have several options for installing puppetmaster. You can use the package available in Ubuntu's repository or you can use Puppet Lab's apt repository. For this example, I will use the version from Puppet Lab's repository:

```bash
wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
apt-get -y install puppetmaster
service puppetmaster stop
```

At this point, we need to configure the puppetmaster for use with our environment. One way to do this is by editing /etc/hosts, but that is tedious and goes against what we want to accomplish with configuration management. I will use a configuration option called [dns_alt_names](http://docs.puppetlabs.com/references/latest/configuration.html#dnsaltnames) to use my own domain.

```bash
rm -rf /var/lib/puppet/ssl
vim /etc/puppet/puppet.conf
```

Under the "[master]" header, add the following and restart the service:


    dns_alt_names = puppet, master.local, puppet.cloudsrvr.info
    service puppetmaster start


Make sure you set your puppetmaster DNS record to the server's [ServiceNet](http://www.rackspace.com/knowledge_center/frequently-asked-question/what-is-servicenet) address to avoid bandwidth charges.

#### Setting up a client


SSH to the puppet client server and install the Puppet Labs repository and puppet:

```bash
wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
apt-get -y install puppet
service puppet stop
```

Once puppet is installed, we need to configure the client to know how to connect to the puppetmaster. We do this by editing the /etc/puppet/puppet.conf file. Under the "[agent]" header add the following:


    server = puppet.cloudsrvr.info


Then, you need to allow the client to start. Edit /etc/default/puppet and set START = yes.

At this point take a server image of your client. You can use this image to scale later.

Start puppet:


    service puppet start




#### Signing certificates


On the puppetmaster, you now should see your client server connections. We have to tell the puppetmaster to accept the certificate from the client.


    puppet cert --list
    "client" (1E:D3:74:DD:9B:22:D0:6C:35:21:2F:90:F0:EF:DC:3C)
    puppet cert --sign client
    notice: Signed certificate request for client
    notice: Removing file Puppet::SSL::CertificateRequest client at '/var/lib/puppet/ssl/ca/requests/client.pem'




#### Manifests and modules


Now that our puppetmaster is talking to our client, we need to tell the client to do things. While Chef does this with recipes, Puppet does this with manifests. A group of manifests is called a module. There are modules to configure packages like Apache, Nginx, and MySQL. You can also use manifests and modules to alter file permissions, users and groups, and more. Just to make sure this is configured properly we're going to use a module to install MySQL on our client. Perform these steps on your puppetmaster:

```bash
apt-get -y install git
git clone https://github.com/puppetlabs/puppetlabs-mysql mysql
vim /etc/puppet/manifests/site.pp
```

site.pp:

{% codeblock lang:ruby %}node client {
class { 'mysql': }
class { 'mysql::server':
   config_hash => { 'root_password' => 'password' }
}
}{% endcodeblock %}

Next, let's test to make sure our client server can get the changes. On the client server run the following:


    puppetd --test --noop
    info: Caching catalog for client
    info: /Service[mysqld]: Provider upstart does not support features enableable; not managing attribute enable
    info: Applying configuration version '1346434288'
    notice: /Stage[main]/Mysql::Server/Package[mysql-server]/ensure: current_value purged, should be present (noop)
    err: /Service[mysqld]: Could not evaluate: Execution of '/sbin/status mysql' returned 1: status: Unknown job: mysql
    notice: /Stage[main]/Mysql/Package[mysql_client]/ensure: current_value purged, should be present (noop)
    notice: Class[Mysql]: Would have triggered 'refresh' from 1 events
    notice: Class[Mysql::Server]: Would have triggered 'refresh' from 1 events
    notice: /Stage[main]/Mysql::Config/File[/etc/mysql]: Dependency Service[mysqld] has failures: true
    warning: /Stage[main]/Mysql::Config/File[/etc/mysql]: Skipping because of failed dependencies
    notice: /Stage[main]/Mysql::Config/File[/etc/mysql/my.cnf]: Dependency Service[mysqld] has failures: true
    warning: /Stage[main]/Mysql::Config/File[/etc/mysql/my.cnf]: Skipping because of failed dependencies
    notice: /Stage[main]/Mysql::Config/File[/etc/mysql/conf.d]: Dependency Service[mysqld] has failures: true
    warning: /Stage[main]/Mysql::Config/File[/etc/mysql/conf.d]: Skipping because of failed dependencies
    notice: /Stage[main]/Mysql::Config/Exec[set_mysql_rootpw]: Dependency Service[mysqld] has failures: true
    warning: /Stage[main]/Mysql::Config/Exec[set_mysql_rootpw]: Skipping because of failed dependencies
    notice: /Stage[main]/Mysql::Config/File[/root/.my.cnf]: Dependency Service[mysqld] has failures: true
    warning: /Stage[main]/Mysql::Config/File[/root/.my.cnf]: Skipping because of failed dependencies
    notice: /Stage[main]/Mysql::Config/Exec[mysqld-restart]: Dependency Service[mysqld] has failures: true
    warning: /Stage[main]/Mysql::Config/Exec[mysqld-restart]: Skipping because of failed dependencies
    notice: Stage[main]: Would have triggered 'refresh' from 2 events
    notice: Finished catalog run in 0.39 seconds


This command basically performs a dry-run of Puppet - in this case installing MySQL. The error displayed is from MySQL attempting to start. Since this is a dry run MySQL isn't actually installed. Let's run it and install MySQL!


    puppet agent --test


Puppet will read the site.pp from the puppetmaster and install MySQL. Success!


#### Want to know more?


For more information on Puppet, Puppet Labs has fantastic [documentation](http://docs.puppetlabs.com/). Manifests and modules are available on [Github](https://github.com/puppetlabs). <del>Stay tuned</del> [Click here](http://devops.rackspace.com/using-libcloud-and-puppet-to-bootstrap-cloud-servers.html) for a post on how to use Puppet to bootstrap new Cloud Servers.
