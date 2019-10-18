---
layout: post
title: Backing Up Cinder Volumes to Swift
date: '2015-05-05 09:52'
comments: true
author: James Thorne
published: true
categories:
  - openstack
  - architecture
---

Architecting applications for a cloud environment usually means treating each cloud server as ephemeral. If you destroy the cloud server, the data is destroyed with it. But, you still need a way to persist data. Cloud block storage has typically been that solution. Attach cloud block storage to a cloud server, save your data within that cloud block device, and when/if the cloud server is destroyed, your data persists and can be re-attached to another cloud server.

<!-- more -->

The underlying storage and architecture of cloud block storage environments varies across companies and cloud platforms. Within OpenStack, the Cinder project is responsible for managing, attaching, and detaching cloud block storage volumes. Here are two of the many common ways Cinder can be architected:

1) Simply have one-to-many independent physical servers, with each containing a bunch of RAID'd local storage managed by LVM with the Cinder services sitting on top. While this setup works and is very simple, it introduces single points of failure. If a Cinder Node fails where you have already created, and are using, Cinder Volumes, those Cinder Volumes will no longer be accessible.

2) Or use many physical servers in a cluster (managed by something like Ceph) to create a distributed storage platform that the Cinder services sit on top of. This architecture is more complicated but eliminates the single points of failure. If a Cinder Node fails where you have already created, and are using, Cinder Volumes, those Cinder Volumes are still accessible, because they are distributed across the Ceph cluster and will be served by a healthy Cinder Node.

Regardless of whether you architect your Cinder environment with option 1 or option 2, you need some way to backup your Cinder Volumes. Those backups should sit on physically different servers in your OpenStack environment to be considered a true backup.

So, how and where can you easily backup your Cinder Volumes?

Swift is OpenStack's object storage service and is a fantastic platform for backing up data. Swift is meant to run on top of commodity servers using commodity disks; you shouldn't be using any fancy storage solutions here. Because of this, it can be very easy and inexpensive to create a highly available and redundant Swift environment to store your backups.

cinder-backup
-------------

Cinder is comprised of many services including __cinder-backup__. It was specifically designed to easily backup your Cinder Volumes to another storage platform using backup drivers. One of those backup drivers is for Swift. Other backup drivers available in Cinder can be found [here](https://docs.openstack.org/juno/config-reference/content/section_backup-drivers.html).

Instructions on how to setup an OpenStack environment with Cinder and Swift are out of the scope of this post. This post assumes you already have a functioning OpenStack Juno environment with Cinder and Swift.

Assuming Cinder and Swift are working without issue, configuring Cinder to backup to Swift is surprisingly simple.

You simply need to add the following configuration line to every __cinder.conf__ in your OpenStack environment and restart the Cinder services:

    backup_driver = cinder.backup.drivers.swift

Swift should already be available as a Keystone Endpoint in your OpenStack environment, which you can verify by running `keystone endpoint-list`, so Cinder will query that endpoint figure out how to communicate with it.

Once those steps are completed, you can backup your Cinder Volumes using the `cinder backup-create` command. With a backup in place, you have the ability to restore from that backup using the `cinder backup-restore` command. Additional details for the `cinder backup-create` and `cinder backup-restore` commands can be found [here](https://docs.openstack.org/admin-guide-cloud/content/volume-backup-restore.html).

Be aware, you can only restore a backup to the same Cinder environment it was backed up from. If you are backing up a Cinder Volume to then restore into a completely different OpenStack environment, you will need to export the Cinder Volume's metadata too. Additional details and how to do this can be found [here](https://docs.openstack.org/admin-guide-cloud/content/volume-backup-restore-export-import.html).

In addition, if you have another Swift environment, you can leverage Swift's container sync functionality. This allows you to replicate the Swift container storing the Cinder Volume backups to a geographically separated site for disaster recovery purposes.