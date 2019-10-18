---
comments: true
sharing: true
date: 2012-09-07T08:00:27.000Z
layout: post
title: Using libcloud and Puppet to bootstrap Cloud Servers
author: Hart Hoover
categories:
  - Cloud Servers
  - Python
---

In my [last post](https://devops.rackspace.com/using-puppet-with-cloud-servers.html), I discussed a manual install of Puppet between a puppetmaster and client. Here, I will take that a step further and use Apache [libcloud](https://libcloud.apache.org/) to bootstap a Puppet client node.

<!-- more -->

#### First steps


First, follow the steps in my last article to set up your puppetmaster. The Puppet client portions are not required as we will bootstrap our client servers. Now, let's install the libcloud library:

<del>git clone git://github.com/apache/libcloud.git
cd libcloud
sudo python setup.py install</del>
UPDATE: Since libcloud has been updated since this post, you need to use pip with a specific version:

	pip install apache-libcloud==0.11.3

You may need to install other Python libraries like [paramiko](https://www.lag.net/paramiko/) for deployments.


#### Create a shell script for installing Puppet


You need to create a short shell script that will be executed on your new Puppet clients. This script should install Puppet and configure the client to talk to your puppetmaster. All of the files I create here are in a local directory called "puppet-deploy."

~/puppet-deploy/deploy-puppet.sh:
{% codeblock lang:bash %}
#!/bin/bash
# upgrade all packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade

# install PuppetLabs repo
wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb

# Install puppet
apt-get -y install puppet
service puppet stop

# Remove SSL directory (will be regenerated when restarted)
rm -rf /var/lib/puppet/ssl

# Configure Puppet to talk to our puppetmaster
cat >> /etc/puppet/puppet.conf <<-EOF
[agent]
server = puppet.cloudsrvr.info
EOF

# Start the puppet service
cat > /etc/default/puppet <<-EOF
# Defaults for puppet - sourced by /etc/init.d/puppet
# Start puppet on boot?
START=yes
# Startup options
DAEMON_OPTS=""
EOF
service puppet start

# Clean up
export DEBIAN_FRONTEND=dialog{% endcodeblock %}

#### Create a JSON file for your credentials


For security purposes, you can create a separate file with your Rackspace Cloud API credentials. Just replace the username and apikey values with those from your Rackspace Cloud account:

~/puppet-deploy/creds.json
```    
    {
    "user": "username",
    "key": "apikey"
    }
```



#### Use libcloud to deploy a Puppet client


Next we use libcloud to create a server with our SSH key and Puppet that is ready to get instructions from our puppetmaster.

Since I didn't have the client SSL certificates installed, I'm electing to not verify the SSL certificate from Rackspace. This can open you up to man-in-the-middle attacks, so it's best to install those. **This is for testing only.**

~/puppet-deploy/deploy.py:

{% codeblock lang:python %}#!/usr/bin/env python
import json
import libcloud.security
import libcloud.compute.providers
import libcloud.compute.types
from libcloud.compute.deployment import MultiStepDeployment, ScriptDeployment, SSHKeyDeployment
import os.path

# Import username and API key from a separate JSON file
creds = json.loads(open('creds.json').read())

# Don't verify the SSL cert. USE AT YOUR OWN RISK
libcloud.security.VERIFY_SSL_CERT = False

# Create a connection to the Chicago Rackspace endpoint
RackspaceProvider = libcloud.compute.providers.get_driver(libcloud.compute.types.Provider.RACKSPACE_NOVA_ORD)
driver = RackspaceProvider(creds['user'], creds['key'],
    ex_force_auth_url='https://identity.api.rackspacecloud.com/v2.0/',
    ex_force_auth_version='2.0')

images = driver.list_images() # Get a list of images
sizes = driver.list_sizes() # Get a list of server sizes
size = [s for s in sizes if s.ram == 1024][0] # We want a 1GB server
image = [i for i in images if i.name == 'Ubuntu 12.04 LTS (Precise Pangolin)'][0] # We want Ubuntu 12.04

# Push our SSH key to /root/.ssh/authorized_keys
install_key = SSHKeyDeployment(open(os.path.expanduser("~/.ssh/id_rsa.pub")).read())

# Run the puppet install script
install_puppet = ScriptDeployment(open(os.path.expanduser("deploy-puppet.sh")).read())

# Multiple-step deployment that installs our SSH key and Puppet
multideploy = MultiStepDeployment([install_key, install_puppet])

# Creates our new server, runs deployment steps.
node = driver.deploy_node(name='puppet02', image=image, size=size, deploy=multideploy){% endcodeblock %}

This script is basically authenticating with Rackspace using our API credentials, then creating a 1GB Ubuntu 12.04 server in Chicago with our SSH key. Our Puppet install script is then run to upgrade packages and configure puppet. As soon as the server is online, Puppet will connect to the puppetmaster for instructions. The only thing left to do is sign the certificate on the puppetmaster:

    
    puppet cert --list
      "puppet02" (5A:A0:BB:FA:DF:2A:E6:24:70:24:63:85:67:2F:DC:08)
    puppet cert --sign puppet02
    notice: Signed certificate request for puppet02
    notice: Removing file Puppet::SSL::CertificateRequest puppet02 at '/var/lib/puppet/ssl/ca/requests/puppet02.pem'


Your Puppet client will start getting manifests and modules from the puppetmaster and installing your application.


#### Want to know more?


For more information on Puppet, PuppetLabs has great [documentation](https://docs.puppetlabs.com/). Click [here](https://libcloud.apache.org/docs/) for more information on libcloud, or [here](https://twitter.com/libcloud) to follow libcloud on Twitter.
