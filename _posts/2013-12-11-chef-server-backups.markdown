---
layout: post
title: Chef server backups
date: '2013-12-11 10:00'
comments: true
author: Sriram Rajan
published: true
categories:
  - Chef
---

There are few ways to backup a Chef server. Opscode has some documenation on
their wiki [Backing up Chef Server](https://wiki.opscode.com/display/chef/Backing+Up+Chef+Server).
Some of this is outdated now because chef no longer uses Couch DB.

However there is this little gem (pun intended) called knife-backup.

<!-- more -->

To put this to test, install it first

    gem install knife-backup

More details are here [https://github.com/mdxp/knife-backup](https://github.com/mdxp/knife-backup)

An execution looks like this

    knife backup export -D ./backups
    Backing up clients
    Backing up clients chef-validator
    Backing up clients chef-webui
    Backing up clients test01.example.com
    Backing up clients web01.example.com
    Backing up nodes
    ...Output Truncated...


This nicely exports all your settings such as nodes, clients, roles,
environments and cookbooks into the backups directory. Typically your
cookbooks would be version controlled via Git or some other revision control
system and you can restore it from there as well. This method allows you to
completely mirror cookbooks from one chef server to another along with the
other stuff in couple of simple commands.

    ls backups
    clients      cookbooks    data_bags    environments nodes        roles


To test your backup spin up a new server and install chef per your OS
[https://www.opscode.com/chef/install/](https://www.opscode.com/chef/install/)

If you want to try this on a existing server, you can use the following

<p style="color:red;">**WARNING** : This will erase all your chef server data </p>

    sudo chef-server-ctl cleanse
    sudo chef-server-ctl reconfigure

Copy _/etc/chef-server/admin.pem_ from the new server to your local workstation.
You will use this user to perform the restore. Once you have restored you can
use other clients/users that you were using with the original server.

    knife backup restore -D ./backups -u admin -k <path to admin key> -s  <new server url>

This will restore to the new server with the exception of few things. This is
because knife restore does not overwrite existing clients.

 1. The _admin_ user and it's credentials.

 2. The _chef-webui_. This is used by the web-interface and so it makes sense to leave it.

 3. The _chef-validator_ client. Now this has some implications. chef-validator's key is used on a node when it runs the chef-client for the first time in order to get an API client identity. Since this is now different from your original server, and if you are using knife to bootstrap nodes,  you will need to re-copy this to your knife workstation setup.  Existing nodes don't need this as they are already registered.

All said this is a handy tool and with a little bit of scripting you can run
these backups hourly/daily and use time stamped directories.



