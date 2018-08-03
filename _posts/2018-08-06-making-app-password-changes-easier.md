---
layout: post
title: "Making App Password Changes Easier"
date: 2018-08-06 23:59
comments: true
author: Rodney Beede
authorIsRacker: true
published: true
categories:
  - Security
  - Automation
---

 A common technical challenge for developers, operations, and IT security is the management of service account credentials used by applications.  Due to software architecture design the need for service accounts exist to authorize different components to communicate and share data.  This is true whether the application runs in the cloud or on-premise.  However, the problem is that these credentials are setup one time, never expire, and are hard-coded into configuration files.  I wanted to share some design thoughts on how to make changing credentials easier.

  <!-- more -->

# Current common scenario

Let's have a web application called AcmeWebApp.  It doesn't matter where we are running it other than we have deployed it onto a server we manage the files on.

AcmeWebApp has a configuration file called awa.conf that contains things like:
```
[section]
API_ENDPOINT=https://198.51.100.4/api/3/rest.cgi
API_USERNAME=awa_rest_api
API_PASSWORD=MinRequired2

[datastore]
URI=gopher:203.0.113.254:/data
DS_USERNAME=admin
DS_PASSWORD=AnotherPassword@2

[admin]
localadmin_password=defaultWeForgotToChange
```

## Credential usage

Good practice has a file ACL that does protect awa.conf from anyone.  This configuration file has the required credentials to connect to two other services as well as the initial login password used.

## Challenge or difficulty

When the need arises to change the password (hacker compromise, former employee left, policy directs yearly change, ...) however the following is required:
0. Shutdown all running instances (entire cluster)
0. Change password on remote service
0. Update conf file on each application in the cluster
0. Restart the application
0. Repeat again next time

This mandates having to schedule downtime for the application for a password rotation.  This can be difficult to prioritize as well until an urgent event (system compromise, audit deadline) occurs which makes the work more difficult.

# Ideal scenario

0. Password credentials rotate automatically and frequently
0. No application downtime is required

# How to reach the ideal

There are commercial solutions (which can be expensive) that help with password credential management (vault/storage) and rotation.  You as a software developer can even use libraries provided by these vendors to have your own code call their solutions to retrieve credentials.  One downside, however, is that your application becomes locked into that vendors product.

## What can a software developer do?

I want to outline some technical designs, tricks, or methods that software developers can use that would make it easier for your operations or IT security personnel to change credentials your application is dependent on without incurring downtime.
