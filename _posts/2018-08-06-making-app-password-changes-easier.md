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
[remotewidget]
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

When the need arises to change the password (hacker compromise, former employee left, policy directs yearly change, etc.) however the following is required:

1. Shutdown all running instances (entire cluster)
1. Change password on remote service
1. Update conf file on each application in the cluster
1. Restart the application
1. Repeat again next time

This mandates having to schedule downtime for the application for a password rotation.  This can be difficult to prioritize as well until an urgent event (system compromise, audit deadline) occurs which makes the work more difficult.

# Ideal scenario

1. Password credentials rotate automatically and frequently
1. No application downtime is required

# How to reach the ideal

There are commercial solutions (which can be expensive) that help with password credential management (vault/storage) and rotation.  You as a software developer can even use libraries provided by these vendors to have your own code call their solutions to retrieve credentials.  One downside, however, is that your application becomes locked into that vendor's product.

## What can a software developer do?

I want to outline some technical designs, tricks, or methods that software developers can use that would make it easier for your operations or IT security personnel to change credentials your application is dependent on without incurring downtime.

### Separate out each credential from your configuration file

In the example above of awa.conf we had each credential all in the same awa.conf file.  So your code only has to read in the one file and has all the credentials it needs in one variable.

While handy for you from an operations or IT security tool standpoint this is cumbersome.  If I (security operations) want an automated script to change the passwords it must know:
1. How to parse your configuration file (not too difficult)
1. To rewrite the entire configuration file atomically
  * Meaning only change 1 credential at a time
  * Avoid writing an old credential when rewriting the configuration file to disk
  * Example:
    1. awa.conf was having its DS_PASSWORD updated with a new one by scriptRunA
    1. At the same time a script/tool was also changing the API_PASSWORD (scriptrunZ)
    1. Unfortunately scriptRunA overwrote the updated credential with an old one for API_PASSWORD
    
#### Solution

Place each credential in a secure (file ACL) dedicated file.  Example:

```
ls /etc/awa/conf.d/
awa.conf   <-- file no longer holds credentials
awa-datastore.cred
awa-remotewidget.cred
```

Example of awa-datastore.cred:
```
admin
AnotherPassword@2
```

Notice that there are no SOME_NAME= portions either.  This simplifies parsing by tools external to the application.

Doing this allows operations tools to work with each credential individually and without having to do special logic handling on atomic modification of a single awa.conf file.

Your development code does have to contain logic to know how to find these files of course, but having this layout is part of the way towards allowing changes to the application without downtime or restarts.


### Always reread the credentials from your configuration

Another common development habit is to only read the application configuration once upon startup.  If a configuration setting needs to be changed it typically requires an application restart.

For credentials you can avoid the restart and thus downtime by simply re-reading the credentials anytime they are needed.  You write your code so it doesn't use an in-memory configuration hash but instead goes back to the file on disk.

You may also find it useful to catch any service connection errors and perform a retry after re-reading the credentials on disk.  An example may help:

1. AcmeWebApp is already running and servicing users
1. An operations member changes the datastore password on the remote datastore service for the service account user "admin"
1. The operations member then updates /etc/awa/conf.d/awa-datastore.cred with the new password
1. AcmeWebApp was never stopped or restarted
1. AcmeWebApp needs a new connection to the datastore at 203.0.113.254
1. AcmeWebApp reads the /etc/awa/conf.d/awa-datastore.cred from disk for the latest credentials
1. AcmeWebApp uses the new credentials to connect and serve users, all without a restart

:warning:
  But wait!  What if between the time the datastore password was changed and before awa-datastore.cred was updated AcmeWebApp tries to connect!  Won't that result in the old invalid credentials being used and a failure?


Yes it can.  You could simply have your code do this:
1. Sleep and Wait a few seconds (say 30)
1. Reread from disk the credential file
1. Reattempt the connection with the newly read credentials
1. Repeat until credential becomes valid

The downside is that it is possible the service account could become locked out due to execessive login failure attempts.  I propose a better way in the next section.


### Support rotating set of credentials (Fernet)

The OpenStack project has a neat concept of a thing known as [fernet tokens](https://docs.openstack.org/keystone/pike/admin/identity-fernet-token-faq.html)

Instead of only one valid credential to a service you have multiple that you rotate through.

Adapting for our purpose we would have multiple credentials for the remote service.  Take the AcmeWebApp software as an example:

We have a remote REST service that our application makes calls for.  API_ENDPOINT=https://198.51.100.4/api/3/rest.cgi

We originally asked the owner of that service to give us a service account.  The username is awa_rest_api

In order to support our fernet credential rotation we ask for a second account that has access to the same data or permissions: awa_rest_api_2

We now add another credential configuration file for our application:

```
ls /etc/awa/conf.d/
awa.conf
awa-datastore.cred
awa-datastore.cred2
awa-remotewidget.cred
awa-remotewidget.cred2
```

Notice the .cred2 addition.

.cred may have a username of awa_rest_api
.creds2 may have a username of awa_rest_api2


In your application code you now want some psuedocode like this:

```
try {
  cred = getWidgetCredential(1)  // reads from disk everytime

  restRequest = call_api(config['remotewidget']['API_ENDPOINT'], cred)
} catch InvalidUserAuthError {
  // retry with other cred in rotation
  cred = getWidgetCredential(2)  // reads from disk everytime
  
  try {
     restRequest = call_api(config['remotewidget']['API_ENDPOINT'], cred)
  } catch InvalidUserAuthError {
     // Second credential failed too
     log.error("Tried all known credentials for service")
     return nil
} catch NotAuthError {
    // Add your own retry logic
}

// You might also implement the above as a for loop over an array of credentials instead of nested try catch.
// Just remember to re-read the credentials from their disk configuration files each time
```

The idea is that if the first credential is invalid (was changed recently) the second credential (brand new) will be used.  This allows for operations to change or deactivate a compromised account quickly and then update the application configurations shortly thereafter.  All without incurring downtime.

In a normal operation state both credential files have valid logins.  At the time when it becomes necessary to change one of them (or both) operations doesn't need to shutdown the application.  They just change it on the remote service.

The application will automatically detect a failed login attempt and simply move on to the next credential which is still valid.

Operations can repeat the same process after all the application instances have moved to the new credential and the first credential has been updated on disk.

# Summary

Software development and security operations do have many ways of helping each other be successful.  Automation of processes and robust software development are making technology better and hopefully these design ideas help you solve your secure code challenges too.
