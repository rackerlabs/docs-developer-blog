---
layout: post
title: “Cloud Servers: Am I charged when my server is shut down?”
date: 2019-11-13 00:00
comments: true
author: Shaun Crumpler
published: true
authorisRacker: true
catagories: Cloud Servers
metaTitle: “Cloud Servers: Am I charged when my server is shut down?”
metaDescription: ".”
ogTitle: “Cloud Servers: Am I charged when my server is shut down?”
ogDescription: "."
---

Sometimes the easiest, and cheapest, solution is to let the public cloud server go.

<!-- more -->

Customers frequently ask Support when a Cloud Server incurs charges.  It is a common misconception that a shutdown server is not being billed because the server is not using resources.  However, cloud server pricing is based on the hours that the server is using resources on the host machine.  For instance, even though the CPU and RAM of the cloud server is not being actively used, they are reserved for the server on the host machine.  Because of this, merely shutting down a server is not enough to stop billing&mdash;the server must be deleted to stop charges.  

Keep in mind that you need to understand if the server is being actively used before deleting the server.

### Shut down a server

Shutting down the server itself is a good way to determine if it is being actively used.

#### To shut down a Linux server

1. [Log into the server](https://support.rackspace.com/how-to/connect-to-a-cloud-server/).
2. At the command prompt and run the following command:
            
       shutdown -h now

#### To shut down a Windows server

1. [Log into the server](https://support.rackspace.com/how-to/connect-to-a-cloud-server/)
2. Open up a command prompt and run the following command:

       shutdown
       
#### Reboot the server

After the `shutdown` command completes, it can take a few minutes for the [Cloud Control Panel](https://mycloud.rackspace.com) to show the instances as offline, but any connection attempts to the server are immediately rejected.  At this point, you can determine whether the server is needed by investigating if the server is actively being used.

If you determine the server needed, you can move forward with rebooting the server by clicking the gear icon in the Control Panel and selecting **Reboot**.

#### Save data

If you plan to delete a standard or general purpose flavor server and want to retain data for possible future needs, create a [Cloud Server Image](https://support.rackspace.com/how-to/creating-an-image-backup-cloning/).

For boot-from-volume servers and servers where only certain files need to be saved, use [Cloud Backup] (https://support.rackspace.com/how-to/rackspace-cloud-backup-create-a-backup/) to save what you need.

Both Cloud Backups and server Images are stored in Cloud Files so storage costs are incurred, but for individuals who want to minimize their costs, these two options can be considerably cheaper than a running server.  Fin pricing details [here](https://www.rackspace.com/en-us/cloud/files).

### Delete the server

**Note:** Proceeding with a server deletion also deletes all of the data on the server, which cannot be reversed.  Thus, it is important to take the time to complete the previously described backup options above first.

Use the following steps to delete your server:

1. Log in to your [Cloud Control Panel](https://mycloud.rackspace.com).
2. Click **Select a Product** from the top menu.
3. Click **Rackspace Cloud** from the drop down list.
4. Find the server that you want to delete from your Cloud Servers list.
5. Click on the gear icon to the left of the server name, and then click **Delete Server**.
6. Confirm that you wish to proceed with the deletion.
