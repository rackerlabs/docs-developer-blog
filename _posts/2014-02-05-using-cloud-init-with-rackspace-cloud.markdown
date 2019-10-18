---
layout: post
title: Using Cloud-init with Rackspace cloud
date: '2014-02-11 10:30'
comments: true
author: Trey Hoehne
published: true
categories:
  - Configuration Management
---
It goes without saying that booting and configuring a server manually
every time you need one gets old fast. Thankfully there are a number of tools to help
with orchestration and automation available to you. 

To list a few you can:

-   create a 'golden image' of a server's desired state.
-   learn and setup Chef/Puppet/Salt Stack to manage your infrastructure.
-   use Rackspace's Cloud Deployments to spin up an environment.

<!-- more -->

All of these are great tools, but as with anything they have their pros
and cons. Chef or Salt Stack gives you a good deal of customization but
you'll need to learn the format and then you'll probably need to run
some additional infrastructure to support the orchestration. Rackspace Deployments provides a variety of deployable
stacks, but might lack the advanced customization you need. Using a “golden
image” requires you to deploy a new server to customize and capture
any changes you make. 

What if you want something simple that's easy to use but is powerful enough to compliment your existing configuration management?

Enter cloud-init, a project by Canonical that is designed to work
across cloud providers and public/private clouds. It's easy to
use, and can be a great alternative or complement to your
existing configuration management. 

<!-- more -->

# Using cloud-init

The first piece we'll need to create to use cloud-init is the
cloud-config configuration file. This is a YAML formatted file that must
begin with '#cloud-config' and uses a cloud-init specific syntax. It's
a powerful tool with many options and modules, so here is some further reading:

[Example configuration file.](https://bazaar.launchpad.net/~cloud-init-dev/cloud-init/trunk/view/head:/doc/examples/cloud-config.txt)

[Specific examples using cloud-init. ](https://bazaar.launchpad.net/~cloud-init-dev/cloud-init/trunk/files/891/doc/examples)


# Wordpress and LAMP installation via cloud-init

Lets use cloud-init to set up a basic LAMP stack and then download the
latest version of Wordpress. While this isn’t the most comprehensive example of a Wordpress install, it will give you a good
idea of how easy a basic deployment with cloud-init can be. 

Here is the full cloud config that we'll be using.


	#cloud-config

	packages:

	 - apache2
     - php5
	 - php5-mysql
     - mysql-server

	runcmd:

     - wget https://wordpress.org/latest.tar.gz -P /tmp/
     - tar -zxf /tmp/latest.tar.gz -C /var/www/
     - mysql -e "create database wordpress; create user 'wpuser'@'localhost' identified by 'changemetoo'; grant all privileges on wordpress . \* to 'wpuser'@'localhost'; flush privileges;"
     - mysql -e "drop database test; drop user 'test'@'localhost'; flush privileges;"
     - mysqladmin -u root password 'changeme'

The cloud-config file is broken into sections by cloud-init module, with
the appropriate parameters for each following. All of the default
modules are included on the Rackspace enabled cloud-init base
images. 

* CentOS 6.x +
* Debian 7 +
* Fedora
* RHEL 6.x +
* Scientific Linux 6.x +
* Ubuntu 12.04 +
* Arch and Gentoo coming soon

# Examining the cloud-config script

The first module in the configuration file is `packages`. As the name
implies, any distribution specific packages listed here will be
installed by cloud-init. While cloud-init syntax is universal on
supported distributions, the packages that you specify to install are
typically distribution specific so you'll need to make sure all of your
packages are correct. For example, on RHEL based distributions the
Apache module would be referred to as 'httpd'. This module will also update our repositories for us before
trying to install anything.

Next up is the `runcmd` and this allows you to run arbitrary commands
like you would via your Linux shell , with each command on a separate
line. This is where cloud-init will pull down Wordpress and setup MySQL for the installation. All pretty standard stuff.

# Building a server with config-drive

Before we can use our configuration file we'll need to actually get it
into the server, and we'll accomplish that by using a feature called
config-drive. Additional information about config-drive can be read
about in the [API docs](https://docs.rackspace.com/servers/api/v2/cs-devguide/content/config_drive_ext.html), but just know for the purpose
of this blog that it's a read only drive that is attached to your server
on build and used by cloud-init as a data source for user supplied files.

Now that we have our configuration file setup we'll inject it into our server with the nova (or in
this example the [supernova](https://github.com/major/supernova) client:

    $ supernova iad boot --config-drive=true --flavor performance1-1 --image Ubuntu --user-data cloud-config Servername

 This attaches the config-drive to our server at boot by specifying
`--configuration-drive=true`, then `--user-data cloud-config` is letting
nova know that we're going to pass it the following user-data file which
will need to go inside of config-drive.

If everything worked we should be able to list our server and ping the
public IP assigned to the newly created server.

`$ supernova iad list`

Navigate to the IP appended with '/wordpress' (for example
'https://1.2.3.4/wordpress') and we should see the default Wordpress
installation page. It would be simple to extend the sample
cloud-config to take care of this step for you but I leave that
as an exercise for you. 

If upon navigating to your server's IP you don't get see the default
Apache placeholder page, or cannot see your Wordpress installation, give
it a few seconds as cloud-init could still be unpacking the files or
running through your cloud config. 

# Troubleshooting

This is a good segue into what happens if something goes wrong and you
need to figure out what exploded.

Log files can typically be found in `/var/log/cloud-init.log`.

The copy of your cloud-config is stored here:
`/var/lib/cloud/instance/cloud-config.txt`.

The `/var/lib/cloud` directory also has other useful information, such as
files that let cloud-init know it's already run once so you can rest
easy cloud-init isn't going to setup Apache again if you reboot your
server.

# Partioning disks at boot using cloud-init

Lets work through one more example using cloud-init. 

With the launch of Performance servers we introduced the concept of a
'system' disk for the operating system, and generally 1 or more
additional “data disks” to use for your data storage. By default, The
extra data disks are presented as  separate virtual disk(s) with a
single partition spanning each. You have the flexibility to decide how
to format and mount them; many customers want to automate this at boot
time so lets make cloud-init do that for us.

For this example I'm going to take some examples from the Rackspace
Knowledge Center on [formatting](https://www.rackspace.com/knowledge_center/article/preparing-data-disks-on-linux-performance-cloud-servers) your extra data disks, and the cloud-init
documentation for the [‘fs_setup’](https://bazaar.launchpad.net//~cloud-init-dev/cloud-init/trunk/view/891/doc/examples/cloud-config-disk-setup.txt) and [‘mounts’](https://bazaar.launchpad.net//~cloud-init-dev/cloud-init/trunk/view/891/doc/examples/cloud-config-mount-points.txt) modules. This Performance2-120GB flavor has 4x300GB disks ; if using a
different flavor, refer this [article](https://www.rackspace.com/knowledge_center/article/what-is-new-with-performance-cloud-servers) to learn more about how many disks are
assigned to each flavor in the Performance class.


Here's the full configuration file we'll be using, on an
Ubuntu image.

	#cloud-config
	#values are for performance2-120 flavor with 4 additional data disks
	#remove label blocks as appropriate for other flavors

	fs_setup:

	 - label: None
	   filesystem: 'ext3'
	   device: '/dev/xvde1'
	   partition: 'auto'

	 - label:  None
	   filesystem: 'ext3'
	   device: '/dev/xvdf1'
	   partition: 'auto'

	 - label: None
	   filesystem: 'ext3'
	   device: '/dev/xvdg1'
	   partition: 'auto'

	 - label:  None
	   filesystem: 'ext3'
	   device: '/dev/xvdh1'
	   partition: 'auto'

	#change mount point to desired path and remove devices as appropriate

	mounts:

	 - [ /dev/xvde1, /data1, "ext3", "defaults,noatime"]
	 - [ /dev/xvdf1, /data2 ]
	 - [ /dev/xvdg1, /data3 ]
	 - [ /dev/xvdh1, /data4 ]

	# mount_default_fields
	# These values are used to fill in any entries in 'mounts' that are not
	# complete.  This must be an array, and must have 7 fields.

	mount_default_fields: [ None, None, "ext3", "defaults,noatime", "0","2" ]

(For the four data disk scenario, device labeling starts with 'xvde'
label and ends alphabetically with 'xvdh'.)

We use `fs_setup` to determine how we setup the file system on our
server. In this example we have four sections, each representing a different data disk and partition.
We're not using a label on the disks so we can set this to 'None’. Next
is the file system we want to use on each disk; in this case we'll
specify 'ext3'. This needs to be a file system that's available to your
distribution by default, so if you want to use something exotic you'll
need to add it either via cloud-init or by using a golden image that
already has the filesystem installed. The 'device' is the partition that we
want to format, and 'partition' set to 'auto' will cause it skip that
device if the file system we specified is already there.

After we've setup the file system that we want it's time to mount it.
This follows the same pattern of one section per
device, which follows the mount options and syntax that
you'd find in 'etc/fstab'. The `mount_default_fields` lets us
specify default values for each device. In this example we specifiy
additional entries for the first device 'xvde1'. Rather than add the
specification for each device, this information can be set in the
`mount_defaults` section to save time and space. Feel free to read the `fs_setup` and `mounts`
documentation for a full list of features.

Note that cloud-init will format your data disks one at a time, so disk size and number of are a factor. With
disks as large as 300GB  this can take some time to format; however your
server will be go to 'Active' status and you can ssh, ping, and so forth
while cloud-init is finishes performing all of its actions.

We’ve just scratched the surface of what cloud-init can do, and we look
forward to what our users are doing with it, so let us know in the
comments what tips, tricks and solutions you’re coming up with!
