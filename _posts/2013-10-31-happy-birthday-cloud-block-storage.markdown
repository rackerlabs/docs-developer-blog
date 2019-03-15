---
layout: post
title: 'Happy birthday, Cloud Block Storage!'
date: '2013-10-31 10:27'
comments: true
author: Jerry Schwartz
published: true
categories:
  - General
---

We launched [Cloud Block Storage](http://www.rackspace.com/cloud/block-storage/)
into unlimited availability a year ago and we
now have thousands of customers using the product. The team that designed
Cloud Block Storage wanted to create a different kind of block storage in the
cloud. When we spoke with our customers about what they wanted in a cloud
block storage solution, the feedback focused on three areas:

* Reliable and more consistent performance
* Simpler experience and pricing
* Choice between standard volumes for more disk space or SSD volumes for higher disk I/O performance

<!-- more -->

A year later, we believe we’ve been successful in meeting our customers’
expectations and also in delivering on our goal to create a different kind of
block storage solution. Within months of launching Cloud Block Storage, we
quickly exceeded 1PB of storage for SATA volumes and the majority of our top
customers are now running high-I/O workloads like MongoDB and Cassandra on SSD
volumes.

### Design decisions

Let’s take a quick look at the some of the key product design decisions that
helped us accomplish these goals:

#### Engineered for reliable and more consistent performance:

* Cloud Block Storage provides persistent storage to augment Cloud Servers’ local persistent storage.
* Raid10 backed storage nodes with hot spares provide extreme protection against volume failures.
* A minimum volume size (100 GB) limits the number of customers competing for resources (IOPS) on each storage node.
* Data plane segmentation means that should a Cloud Block Storage node failure occur, it happens at the volume level, not at the region.
* A smart scheduling algorithm spreads individual customers across multiple storage nodes. Customers have the option to configure a software RAID mirror to protect their volume data even further.
* Built from scratch using commodity hardware, open source and OpenStack software technologies that were designed for cloud architectures.

#### Cloud Block Storage was designed from the ground up with simplicity in mind:

* Simple pricing. One price for SATA, one price for SSD, no charge for IOPS.
* No need to track ongoing IOPS usage or pre-calculate the IOPS you will need. If you need hundreds of IOPS, use SATA. If you need thousands, use SSD.
* Simple and intuitive Control Panel experience. Create up to 1 TB of new storage in as little as three clicks from the time you log into the Control Panel.

#### Designed to give customers choice of standard volumes or SSD volumes for higher performance:

* Access to hundreds or tens of thousands of IOPS.
* No need to RAID multiple volumes for high performance – choose SSD instead.
* Use SATA, SSD, or both to customize your storage to fit your application needs.

### Lower Cloud Block Storage Prices

To celebrate Cloud Block Storage being one year old and to further our goal of
more reliable, simple and flexible block storage in the cloud, we are lowering
Cloud Block Storage pricing for both standard and SSD volumes! If you are a
current Cloud Block Storage customer, you will automatically receive the new
pricing on the applicable effective date.

Cloud Block Storage Standard Volumes

{% img http://ddf912383141a8d7bbe4-e053e711fc85de3290f121ef0f0e3a1f.r87.cf1.rackcdn.com/Images1/cbs-updates.1.png 781 134 'CBS Standard' 'CBS Standard' %}

Cloud Block Storage SSD Volumes

{% img http://ddf912383141a8d7bbe4-e053e711fc85de3290f121ef0f0e3a1f.r87.cf1.rackcdn.com/Images1/cbs-updates.2.png 781 134 'CBS SSD' 'CBS SSD' %}

For additional pricing information, check out our Cloud Block Storage
pricing pages here: [Dallas, Chicago, and Northern Virginia](http://www.rackspace.com/cloud/block-storage/pricing/),
[London](http://www.rackspace.co.uk/cloud/block-storage/pricing) and
[Sydney](http://www.rackspace.com.au/cloud/block-storage/pricing).
Note: the US and UK website pricing pages will be updated on Friday,
November 1.

We have learned a lot from our customers this past year and will be making a
number of exciting announcements over the next several months. We’re thrilled
about our Cloud Block Storage offering and how it is benefiting our customers,
and we look forward to celebrating many more birthdays in the future.
