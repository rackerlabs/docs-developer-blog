---
layout: post
title: RPC and NetApp hearts Block Storage
date: '2015-09-21 13:00'
comments: true
author: Walter Bentley
published: true
categories:
  - Private Cloud
---

Rackspace Private Cloud (RPC) powered by OpenStack has done a great job incorporating and enabling many of the great capabilities natively found within Cinder. With RPC, you gain the ability to leverage either Cinder nodes (commodity hardware using ephemeral storage exposing that storage as Block storage to your cloud) or to connect your OpenStack cloud directly to a shared storage solution via Cinder integration drivers.  This is where our friends at NetApp come into play. Rackspace and NetApp have formed a unique relationship to improve the Cinder shared storage capability within OpenStack. These two teams worked together to create a repeatable, approved, and tested process to integrate NetApp storage solutions into Rackspace Private Cloud footprints within a Rackspace datacenter or at the customer's datacenter.

<!-- more -->

I jumped at the opportunity to write a blog on this specific topic mainly because I love OpenStack and because Cinder (the Block Storage service) happens to be one of my favorite services. Why Cinder out of all the services? Well if you take a moment to explore the Block Storage service part of the OpenStack ecosystem, you will notice how powerful and flexible this particular service is. Cinder is one of the few services that allows for almost an endless amount of third-party integrations. Cinder is all about letting you provide persistent storage to your instances in the form of a volume, totally neutralizing the concern as to what/where the storage is. This then leaves the Cloud Operator with many backend storage options for their cloud.  No more are the days of being forced to buy shelf after shelf of all the same type of storage. As you may or may not know, OpenStack is all about the mix and match.

Anyone who has experimented with integrating shared storage devices into Cinder understands why the work done by Rackspace and NetApp is important. Here is a common understanding among individuals that are new to OpenStack: they believe that, just because the feature and/or third-party driver exists, it works out of the box. The last statement is not meant to be discouraging but, rather, to bring more awareness to living within the open source world.

>**Best advice I can provide is: do not declare victory until you test it for yourself :D.**

The reality is some of the new services, features, and drivers created for OpenStack are not bug free yet - particularly the drivers created by the third-party vendors. The services/features take time to mature and, as I have seen thus far, normally do mature within 6-12 months of being added to the main OpenStack trunk. This is why you should rely on OpenStack experts like Rackspace and NetApp to create a design or approach that guarantees success.

One of the core issues around creating integrating drivers to OpenStack is there is no one blue print to build an OpenStack cloud. There can be hundreds of ways to design your OpenStack cloud, and there is no way any vendor can build use cases to solve for them all. Also, outside of that, the vendor's product itself independently improves. Then, so does OpenStack itself. This can create a vicious cycle of continuously adjusting drivers to ensure proper functionality. I say all this to demonstrate how important it is to choose providers and vendors that are committed to making sure to keep up with OpenStack.

So let’s take a moment to review in detail the design work done by Rackspace and NetApp to extend Cinder's shared storage capabilities. More details can be downloaded [here](http://solutionconnection.netapp.com/Core/DownloadDoc.aspx?documentID=125690&contentID=236630). RPC offers the ability to connect your Cinder service, centralized within the OpenStack control plane, directly to a backend NetApp storage device. As of now, the reference architecture is designed to leverage the NetApp FAS devices. It is my understanding that additional device models are under development. Currently certified are the NetApp FAS 2240/2252/2254 and newer. The storage disk options include Flash, SSD, Self-Encrypting, and traditional SAS/SATA solutions.

Below are some of the design details:

* Cinder Driver: NetApp Unified Driver for Clustered Data ONTAP with NFS
* FAS controller configuration: active/passive
* FAS required software:  Flexclone (used for Cinder)
* FAS storage protocol:  NFS

A working configuration example of Cinder and NetApp FAS integration can be found below:

	 volume_driver = cinder.volume.drivers.netapp.common.NetAppDriver
	 volume_backend_name = <custom backend name>
	 netapp_storage_family = ontap_7mode
	 netapp_storage_protocol = nfs
	 netapp_server_hostname = <CONTROLLER_A_HOSTNAME CONTROLLER_B_HOSTNAME CONTROLLER_C_HOSTNAME>
	 netapp_server_port = 80
	 netapp_login = <NetApp user>
	 netapp_password = <NetApp user password>
	 nfs_shares_config = /etc/cinder/nfs_shares

Additional optional Cinder/NetApp FAS configurations:

    httpd.admin.access = host=<CINDER CONTROLLER_A_IP>,<CINDER CONTROLLER_B_IP>,<CINDER CONTROLLER_C_IP>
	 httpd.admin.ssl.enable = on

The first key area that I would like to highlight about the design is that, as described above, the storage is being exposed over NFS. Using NFS verses other Fiber Channel options allows you to use traditional 1 or 10 Gigabit networking to interconnect your cloud and shared storage solution. This removes the additional overhead cost and reliance on fiber optics. Another key feature that I call to your attention is that, in order to connect the FAS device to Cinder, you will be required to purchase the NetApp Flexclone software license. The last area, in reference to Cinder/NetApp integration, is the FAS device must be ONTAP 7-Mode enabled. Feel free to read more about the OpenStack Cinder and NetApp solution design [here](http://community.netapp.com/fukiw75442/attachments/fukiw75442/virtualization-and-cloud-articles-and-resources/459/1/TR-4323-DESIGN-0814_Highly_Available_OpenStack_Deployment_with_NetApp_Storage.pdf#page=41&zoom=auto,84,373).

All and all, if you want to learn more about the RPC and NetApp integration for OpenStack, please contact Rackspace via phone/email/live-chat or inquire directly with your account representative.