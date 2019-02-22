---
layout: post
title: "Install Jenkins on a Rackspace server"
date: 2016-11-02 10:22
comments: false
author: Chris Hultin
published: true
categories:
    - DevOps
    - Jenkins
    - Orchestration
---

You can use the Cloud Control Panel and the Orchestration service to create a
new Rackspace server and install Jenkins in one step.

<!-- more -->

The following steps show you how to choose the correct Orchestration template to
design and build a new server with Jenkins pre-installed.

1. Log in to login.rackspace.com and choose **Select a Product -> Rackspace Cloud**.
2. In the Quick Build panel on the home page, click on the **From Template** option.
3. Choose **Jenkins** from the selection list of available templates.
4. Click **Actions** and then choose **Create Stack from Template**.
5. Make sure **Production** is selected in the Flavor box, and click **Create Stack**.
6. Modify the default **Stack Name** and **Region**, as needed.
7. Expand the **Advanced Options** section, and make any changes to the Jenkins Admin E-mail, Worker(s) Flavor, Master Flavor, and Image.
8. Update the Number of Secondary Servers to the starting number of worker nodes that you need.
9. Click **Create Stack**. The stack creation process typically takes around 15 minutes to complete.

The following steps show how to update the number of worker nodes after server creation.

1. Install `python-openstackclient` or `python-heatclient`, as well as any dependencies.
2. Set the appropriate environment variables. For more information, see [Using the heat client](https://developer.rackspace.com/docs/cloud-orchestration/v1/getting-started/send-request-ovw/#using-the-heat-client).
3. Run the following command, substituting your Stack Name for *Jenkins-Stack* and the number of workers you want in the server_count parameter:

`openstack stack update --existing --parameter server_count=3 Jenkins-Stack`

Wait for the stack to finish updating. You can view the status of the stack by
using the Cloud Control Panel and listing your servers or by running the command: `openstack stack list`.
