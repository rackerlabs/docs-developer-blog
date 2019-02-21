---
layout: post
title: OpenStack Swift use cases in Rackspace Private Cloud
date: '2015-06-09 14:19'
comments: true
author: James Thorne
published: true
categories:
  - openstack
---

OpenStack Swift is the object storage project within OpenStack. From the [OpenStack Swift documentation](http://docs.openstack.org/developer/swift/), "Swift is a highly available, distributed, eventually consistent object/blob store. Organizations can use Swift to store lots of data efficiently, safely, and cheaply."

[Rackspace Private Cloud 10](http://www.rackspace.com/cloud/private/openstack) introduced functionality into our [Ansible tooling](https://github.com/stackforge/os-ansible-deployment) to deploy, manage, and scale Swift. No longer is Swift a second class citizen in our tooling.

Now that Swift can be easily deployed and used, what are some of the use cases for it in Rackspace Private Cloud?

<!-- more -->

### Glance storage backend

Glance is the image service project within OpenStack and is where all of your OpenStack images and Instance Snapshots are stored. To store all of those things, Glance needs a storage backend.

Rackspace Private Cloud 10 offers several options for Glance storage backends. One of those options is OpenStack Swift.

When you use Swift as a Glance storage backend, not only will your OpenStack images replicate across the Swift infrastructure, so will any OpenStack Instance Snapshots you take. This offers a true backup solution for your OpenStack Instances, because those OpenStack Instance Snapshots are stored on physically different servers than your running OpenStack Instances.

For further backup and disaster recovery purposes, you can setup Swift's container sync functionality to sync the container storing your OpenStack Instance Snapshots to Rackspace Cloud Files running in a different region.

### Cinder volume snapshot backups

Cinder is the block storage project within OpenStack, and it allows you to create Cinder Volumes and present them as block devices to OpenStack Instances. Data stored in a Cinder Volume persists even if the OpenStack Instance it is attached to is destroyed. At that point, the Cinder Volume can be attached to another OpenStack Instance and its data accessed.

Similar to OpenStack Instance Snapshots, Cinder allows you to snapshot your Cinder Volumes. Dissimilar to OpenStack Instance Snapshots, those Cinder Volume Snapshots are stored on the particular Cinder node where the Cinder Volume resides. Because the Cinder Volume Snapshot is stored on the same node the original data is on, it cannot be considered a backup; instead, it is a point-in-time copy. As mentioned earlier, to be a true backup, the Cinder Volume Snapshot must be stored on physically different servers.

Cinder has a service called __cinder-backup__ to upload Cinder Volume Snapshots to OpenStack Swift. I encourage you to read more about it in my previous post: [Backing Up Cinder Volumes to Swift](https://developer.rackspace.com/blog/backing-up-cinder-volumes-to-swift/).

### General data backup

Because data uploaded to OpenStack Swift is replicated across the Swift infrastructure, Swift is the perfect place to store your data backups.

Backups are typically stored for a certain period of time. Swift provides functionality to expire objects which removes the burden of you having to manage your data backup lifecycle.

In addition, it is trivial to create your own backup agent using your preferred programing language that leverages the Swift command line tools or the Swift APIs. This opens up a whole realm of possibilities and flexibility that can be applied to your backups that may otherwise be impossible with other backup agents.

### General data storage

OpenStack Swift is a great platform to upload and forget your data until a later date. Because of the way Swift replicates data, you can rest easy knowing your data will be there when you go back for it.

As long as you have the necessary credentials and permissions to access Swift, you can upload your files to Swift using the Swift command line tools or, if you need a graphical user interface, using the Horizon Dashboard.

In addition, there are third party tools such as [Cyberduck](https://cyberduck.io) that allow you to upload data to Swift or Rackspace Cloud Files via a drag-and-drop interface.

### Application data storage

You use object storage everyday by using services such as Dropbox, iCloud, or Spotify.

Many popular and new services use object storage because it is easy to work with, highly scalable, and very redundant.

OpenStack Swift and most other object storage services have an API in front of them for you to use within your applications.

### Conclusion

OpenStack Swift does one thing, and it does it well: storing your data. Couple that with an API and you have a platform that is extremely extensible and easy to use in many different ways.

As more and more features are added, such as Storage Policies and Erasure Coding, use cases of Swift continue to increase and make Swift even more valuable to you and your organization.
