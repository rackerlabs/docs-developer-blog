---
layout: post
title: Introducing boot.rackspace.com
date: '2014-01-23 16:00'
comments: true
author: Antony Messerli
published: true
categories:
  - Cloud Servers
  - OpenStack
---

We have had a number of customers request the need to be able to create their own Cloud Servers images rather than taking snapshots from our base installs.  To fulfill this need, we are announcing a new tool as a preview today called [boot.rackspace.com](https://boot.rackspace.com).  The tool enables you to utilize the various Linux distributions installers to install directly to the disk of your Cloud Server. <!-- more -->

# How It Works
When you create a Rackspace Cloud Server from the boot.rackspace.com image, it will boot the Cloud Server with a small 1 MB [iPXE](https://www.ipxe.org) based ISO.  This in turn will set up the server's assigned networking within the virtual BIOS and netboot into a menu of operating system options hosted over HTTP on [boot.rackspace.com](https://boot.rackspace.com).

You will need to connect to the console of the Cloud Server in order to view the menu after booting the server.  By default, the menu will boot from local disk after five minutes, so if you connect to the console too late, just issue a reboot of the server and then reconnect to the console.

Each option will either kick off the install kernels from the various operating systems or automatically load up the ISO to the Cloud Server.  From there you can customize your Cloud Server to your hearts content and install directly to the OS disk.  Once completed, you can install the Rackspace Cloud Agent, take a snapshot, and then redeploy the image as your golden master.  We have also initially included a few useful tools like [Clonezilla](https://clonezilla.org/) for moving data around.

{% img center 2014-01-23-introducing-boot-dot-rackspace-dot-com/brc-linux-menu.png %}

# Contributing
We've put all the source for the iPXE scripts on [Github](https://github.com/rackerlabs/boot.rackspace.com/) and welcome contributions.  We've also written up some [how-to's](https://github.com/rackerlabs/boot.rackspace.com/wiki) on Rackspace Cloud Servers image creation which will enable you to create images just like our base images.

As contributions are accepted, they will be deployed to the site automatically.  Because of the flexibility iPXE provides, you can also create your own custom menus, host them on your own site, and chain load them from the iPXE command line.

The tool currently ****only works on the newer Performance Flavors**** *(not Standard)* so please keep that in mind when using the tool.

# Using Outside of Rackspace Cloud
The [README](https://github.com/rackerlabs/boot.rackspace.com/blob/master/README.md) also contains instructions for using the tool outside of Rackspace Cloud Servers.  Using the iPXE ISO is great for working on your own servers (DRAC, iLO, etc) in the Datacenter because it's very lightweight and provides a lot of options at your fingertips as you can stream all of the needed packages over the network instead of using a large DVD/ISO.  

# iPXE Community
The [iPXE](https://ipxe.org) community is great and very helpful.  If you'd like to learn more about how network booting works, make sure to check out [networkboot.org](https://networkboot.org/).

# How to Get Started
So in summary, to get started, you can boot a server using the API with the image id:

****9aa0d346-c06f-4652-bbb1-4342a7d2d017**** 

and then connect to the console of the server.  Current and future image id's will be tracked [here](https://github.com/rackerlabs/boot.rackspace.com/wiki/boot.rackspace.com-Image-UUIDs).  If you have any questions or feedback, please don't hesitate to open up a github issue or contact us at <bootrax@rackspace.com>.

# About the Author
Antony Messerli is a Principal Engineer at Rackspace working on the Cloud Servers Engineering team. You can follow him on twitter [@ajmesserli](https://twitter.com/ajmesserli) and on Github as [amesserl](https://github.com/amesserl).
