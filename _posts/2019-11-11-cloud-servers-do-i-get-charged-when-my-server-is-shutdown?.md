---
layout: post
title: “Cloud Servers: Do I Get Charged When My Server is Shutdown?”
date: ‘2019-11-10'
comments: true
author: Shaun Crumpler
published: true
authorisRacker: true
catagories: Cloud Servers
---

Sometimes the easiest, and cheapest, solution is to let the public cloud server go.

A very common question in support is when a Cloud Server’s is incurring charges.  It is a common misconception that a shutdown server is not being billed as the server is not utilizing resources.  Cloud server pricing is based on the hours that the server is utilizing resources on the host machine.  For instance, even though the CPU and RAM of the server is not being actively utilized, it is reserved for the server.  Because of this, merely shutting down a server is not enough to cease billing.  The server must be deleted to stop charges.  

It is important to understand if the server is being actively used before deleting the server.

Shutting down the server itself is a good way to determine if it is being actively used.

### To shut down a Linux server
1. [Log into the server]9https://support.rackspace.com/how-to/connect-to-a-cloud-server/)
2. At the command prompt run `shutdown -h now`

### To shut down a Windows server
1. [Log into the server]9https://support.rackspace.com/how-to/connect-to-a-cloud-server/)
2. Open up a command prompt and run the command `shutdown`

Once these commands are ran, it can take a few minutes for the [Cloud Control Panel](https://mycloud.rackspace.com) to show the instances are offline, but any connection attempts to the server will immediately not be accepted.  At this point you are able to determine if the server is needed by investigating if the server is actively being used.

After the investigation completes, you are able to move forward with rebooting the server utilizing the gear icon in the control panel, then selecting **reboot**.

If you plan to delete the server and want to retain data for possible future needs, a [Cloud Server Image](https://support.rackspace.com/how-to/creating-an-image-backup-cloning/) can be created for standard and general purpose server flavors.

Additionally, for boot from volume servers and servers where only certain files need to be saved, [Cloud Backup] (https://support.rackspace.com/how-to/rackspace-cloud-backup-create-a-backup/) can be used.

Both Cloud Backups and Server Images are stored in Cloud Files and storage costs will be associated as such, but for individuals that want to minimize their costs, these two can be considerably cheaper than a running server.  Pricing can be found [here](https://www.rackspace.com/en-us/cloud/files).

### Deleting the server
**Please note that proceeding with a server deletion will also delete all of the data on the server, which cannot be reversed.  This is why it is important to take the time to complete the above back up options above first.**

1. Log into your [Cloud Control Panel](https://mycloud.rackspace.com)
2. Click **Select a Product** from the top menu
3. Click **Rackspace Cloud** from the drop down list
4. Find the server that you want to delete from your Cloud Servers list
5. Click on the gear icon to the left of the server name, then click **Delete Server**
6. Confirm that you wish to proceed with the deletion.
