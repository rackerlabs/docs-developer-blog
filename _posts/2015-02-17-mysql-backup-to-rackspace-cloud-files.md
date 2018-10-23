---
layout: post
title: MySQL backup to Rackspace Cloud Files
date: '2015-02-17 23:59'
comments: true
author: Walter Bentley
published: true
categories:
  - Ansible
  - database
---

While this blog post may seem trivial on the surface, it does pack some very interesting information on how very flexible the Rackspace Cloud Files product can be.  While executing another customer project, the age old question of: “Where are we going to put the database backups?” was raised.  Back in the day this question only really had one solution.  In the current age of the cloud, you have a few options.  Since I like to live life on the edge…I raised my hand and said Cloud Files.

For those of you not familiar with Cloud Files, the easiest way to describe it is shared Object Storage.  In OpenStack lingo, you could also call it shared Swift.  Cloud Files is an API enabled Object storage capability found on the Rackspace Public cloud platform.  In this post, we will walk you thru how easy it is to store something as simple as database backups in Cloud Files using simple automation, fronted by Ansible of course (my orchestration drug of choice).  I promise this post will be short and sweet.

<!-- more -->

The module we will be using for this exercise is the following:

	rax_files_objects - Upload, download, and delete objects in Rackspace Cloud Files

Disclaimer:  this example assumes you have already created a Cloud Files container but, if not refer to step #2b.

Let’s get started!

---
#####Step #1: Clone Repo

Clone the repo below to pull down the roles you will need.  Consider this a working example that you can later alter for your specific needs.

	$ git clone --recursive https://github.com/wbentley15/rax-ansible-cf.git

#####Step #2: Examine roles and populate variables

Take a look at the roles and familiarize yourself with the steps. Find below all the variables for which you will need to supply values. The variables are located in the group_vars directory within the localhost file:

	dbuser: database user with admin privileges
	dbpass: database user password
	raxcontainer:  Rackspace Cloud Files container name
	raxkey:  Rackspace API key
	raxuser:  Rackspace Username
	raxregion:  Rackspace region
	fileloc:  location of files to upload to Rackspace Cloud Files

#####Step #2b: Create Cloud Files container

You will find two additional roles that you can use to create a Cloud Files container and add files in an ad-hoc manner.

The roles are named below, and they are very self explanatory.

	rax-cf-create
	rax-cf-add

#####Step #3: Give it a try

Now it is time to give it a try.  Do not forget to edit the `/rax-ansible-cf/group_vars/localhost` file and add hosts to the `hosts` file located in the root directory of the playbook.

Assuming you already have Ansible installed, you can execute the playbook:

	$ cd ~/rax-ansible-cf/
	$ ansible-playbook -i hosts base-db-backup.yml

Once completed, you will be able to log into the Cloud Control Panel and, under the Cloud Files tab, find your backups within the container designated.

You can find detailed reference material on the Rackspace Cloud Files under the Storage & Content Delivery Services heading here:  http://docs.rackspace.com/
