---
comments: true
sharing: true
date: 2012-08-23T08:47:54.000Z
layout: post
title: 'Getting started using rackspace-novaclient to manage Cloud Servers'
author: Hart Hoover
categories:
  - Cloud Servers
  - nodejs
  - mailgun
---

Using the
[Rackspace Cloud Control Panel](http://www.rackspace.com/knowledge_center/article/introducing-the-next-generation-cloud-control-panel)
to manage your servers is awesome, but sometimes you just need to get a simple
thing done quickly via the command line. Enter the OpenStack
[rackspace-novaclient](http://pypi.python.org/pypi/rackspace-novaclient/1.0),
a CLI tool to manage your Cloud Servers.

<!-- more -->

#### Installing rackspace-novaclient


First, install the nova client using the following `pip` command:

	 sudo pip install rackspace-novaclient

#### Configuring rackspace-novaclient

After the installation completes, you need to make a **~/.novarc** file for your
credentials. The following file is an example. Just replace the variables with
your information. Your `$ACCOUNT_NUMBER` is located in the upper right of the
Cloud Control Panel.


    OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
    OS_VERSION=2.0
    OS_AUTH_SYSTEM=rackspace
    OS_REGION_NAME=DFW
    OS_SERVICE_NAME=cloudserversOpenStack
    OS_TENANT_NAME=$ACCOUNT_NUMBER
    OS_USERNAME=$USERNAME
    OS_PASSWORD=$APIKEY
    OS_NO_CACHE=1
    export OS_AUTH_URL OS_VERSION OS_AUTH_SYSTEM OS_REGION_NAME OS_SERVICE_NAME OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_NO_CACHE


#### Using the client


Once your **.novarc** file is created and sourced, you can use the `nova` command
to manage your Cloud Servers from the command line. Here are a few examples:

**List all flavors:**

	 nova flavor-list

**List all images:**

	 nova image-list

**Create an Ubuntu 12.04 server in Chicago with 15GB of RAM called "server01":**

	 nova boot --os_region_name ORD boot --image 5cebb13a-f783-4f8c-8058-c4182c724ccd --flavor 7 server01

**Reboot your server:**

	 nova reboot --hard server01


#### Next Steps:


These are just a few of the many commands you can use with rackspace-novaclient's
CLI tool for quick and easy server management. The great thing about
rackspace-novaclient is that it works with both the Rackspace Public Cloud and
[OpenStack Private Clouds](http://www.rackspace.com/cloud/private/). If you are
using multiple OpenStack Compute environments, you can use a tool called [
Supernova](http://rackerhacker.github.com/supernova/), written by
[Major Hayden](http://rackerhacker.com). With Supernova, you are basically
creating multiple **.novarc** files for use with different Compute environments
and using a different CLI tool to manage those environments. Supernova also has
other features like keyring support.
