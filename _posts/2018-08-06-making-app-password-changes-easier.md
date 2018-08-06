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

 A common technical challenge for developers, operations, and IT security is the management of service account credentials used by applications.  Service accounts are needed to authorize different components for communication and sharing data.  This is true whether the application runs in the cloud or on-premise.  The problem is that these credentials have the following issues:
 
* They are setup one time.
* They never expire.
* They are hard-coded into configuration files.

I want to share some design thoughts on how to make changing credentials easier.

<!-- more -->

### Current common scenario

Let's say we have a web application called **AcmeWebApp**.  It doesn't matter where we are running the app.  Jus know that we have deployed it onto a server on which we manage the files.

**AcmeWebApp** has a configuration file called **awa.conf** that contains things like:

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

### Credential usage

A good practice is to have a file, **ACL**, that protects **awa.conf** from everyone.  This configuration file has the required credentials to connect to two other services and contains the initial login password to be used.

The challenge with the preceding practice is this: When we need to change the password (due to a hacker compromise, former employee departure, policy directs yearly change, and so on), the following actions are required:

1. Shutdown all running instances (entire cluster).
1. Change password on remote service.
1. Update the conf file on each application in the cluster.
1. Restart the application.
1. Manually repeat the preceding steps every time password changes are needed.

This procedure mandates scheduling application downtime for a password rotation.  This can be difficult to prioritize until an urgent event (system compromise, audit deadline) occurs, which makes the work more difficult and prone to human error.

### Ideal scenario

In a perfect world, the following statememts are true:

1. Password credentials rotate automatically and frequently.
1. No application downtime is required.

But how do we get there?

There are commercial solutions (which can be expensive) that help with password credential management (such as vaults or storage) and rotation.  You, as a software developer, can even use libraries provided by these vendors to have your own code call their solutions to retrieve credentials.  One downside, however, is that your application becomes locked into that vendor's product.

### What can a software developer do?

I want to outline some technical designs, tricks, or methods that software developers can use that would make it easier for your operations or IT security personnel to change the credentials on which your application is dependent without incurring downtime.

#### 1. Separate out each credential from your configuration file

In the preceding **awa.conf** example, we had all credentials in the same **awa.conf** file.  So your code has to read in only the one file to have all the credentials it needs in one variable.

While handy for you from an operations or IT security tool standpoint, this is cumbersome.  If I (as security operations) want an automated script to change the passwords, the script must be able to do the following tasks:

1. Parse your configuration file (not too difficult).
1. Rewrite the entire configuration file atomically with the following requirements:
  * Change only one credential at a time.
  * Avoid writing an old credential when rewriting the configuration file to disk.

If the script can't handle the preceding requirements, situations like the following one could happen:
    
  1. **awa.conf** has its DS_PASSWORD updated to a new password by **scriptRunA**.
  1. At the same time, a different script or tool, **scriptrunZ**, also changes the API_PASSWORD.
  1. Unfortunately, **scriptRunA** overwrites the updated credential with an previous password for API_PASSWORD
    
##### Solution

Place each credential in a secure dedicated file (for example, file **ACL**), as shown in the following example:

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

Notice that there are no SOME_NAME= portions of code.  This simplifies parsing by tools that are external to the application.

Doing this enables operations tools to work with each credential individually and without having to do special logic handling on automatic modification of a single **awa.conf** file.

Your development code does have to contain logic to know how to find these files of course, but implementing this layout is is good step towards allowing changes to the application without downtime or restarts.

#### 2. Always reread the credentials from your configuration

Another common development habit is to only read the application configuration once upon startup.  If a configuration setting needs to be changed, it typically requires an application restart.

For credentials, you can avoid the restart (and thus the downtime) by simply re-reading the credentials anytime they are needed.  Write your code so that it doesn't use an in-memory configuration hash but instead goes back to the file on the disk.

You may also find it useful to catch any service connection errors and perform a retry after re-reading the credentials on the disk.  The following example may help:

1. **AcmeWebApp** is already running and servicing users.
1. An operations member changes the datastore password on the remote datastore service for the service account user ``admin``.
1. The operations member then updates **/etc/awa/conf.d/awa-datastore.cred** with the new password.
1. **AcmeWebApp** was never stopped or restarted.
1. **AcmeWebApp** needs a new connection to the datastore at ``203.0.113.254``.
1. **AcmeWebApp** reads the **/etc/awa/conf.d/awa-datastore.cred** from the disk for the latest credentials.
1. **AcmeWebApp** uses the new credentials to connect and serve users, all without a restart.

**warning**:
  But wait!  What if between the time the datastore password was changed and before **awa-datastore.cred** was updated **AcmeWebApp** tries to connect!  Won't that result in the old invalid credentials being used and a failure?


Yes, it can.  You could do this in your code:

1. Sleep and wait a few seconds (say 30).
1. Reread from disk the credential file.
1. Reattempt the connection with the newly read credentials.
1. Repeat until credential becomes valid.

Downsides or cons to this include the following:

1. Service account could get locked out due to execessive login failure attempts.
1. Your application response time might go up while waiting for a valid credential in the configuration file.

I propose a better way in the next section.

#### 3. Support rotating set of credentials (Fernet)

The OpenStack project has a neat concept known as [fernet tokens](https://docs.openstack.org/keystone/pike/admin/identity-fernet-token-faq.html).

Instead of only one valid credential to a service, you have multiple that you rotate through.

Adapting this for our purpose, we would have multiple credentials for the remote service.  Take the **AcmeWebApp** software as an example:

We have a remote REST service that our application makes calls for with the ``API_ENDPOINT=https://198.51.100.4/api/3/rest.cgi``.

We originally asked the owner of that service to give us a service account, such as ``awa_rest_api``.

In order to support our fernet credential rotation, we ask for a second account that has access to the same data or permissions, such as ``awa_rest_api_2``.

We now add another credential configuration file for our application:

```
ls /etc/awa/conf.d/
awa.conf
awa-datastore.cred
awa-datastore.cred2
awa-remotewidget.cred
awa-remotewidget.cred2
```

Notice the **.cred2** addition toteh code.

The **.cred** user may have a username of ``awa_rest_api`` with a password of ``secretNumber1``.

The **.cred2** user may have a username of ``awa_rest_api2`` with a password of ``totalDifferentThanOtherOne_not_just_increment2``.

_The usernames could be anything really._

In your application, you now want some psuedocode like this:

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
   }
} catch NotAuthError {
    // Add your own retry logic for unknown problems (blame it on the network)
}

// You might also implement the above as a for loop over an array of credentials instead of nested try catch.
// Just remember to re-read the credentials from their disk configuration files each time
```

The idea is that if the first credential is invalid (was changed recently), the second credential (brand new) is used instead.  This allows operations to change or deactivate a compromised account quickly and then update the application configurations shortly thereafter.  All without incurring downtime.

In a normal operation state, both credential files have valid logins.  At the time, when it becomes necessary to change one of them (or both), operations doesn't need to shutdown the application.  They just change the credentials on the remote service.

The application automatically detects a failed login attempt and simply moves on to the next credential, which is still valid.

Operations can repeat the same process after all the application instances have moved to the new credential and the first credential has been updated on disk.

### Summary

We've discussed the following three things that can help you simplify credential changes in your application code:

1. Separate out each credential from your configuration file.
1. Always reread the credentials from your configuration.
1. Support rotating set of credentials (Fernet).

Software development and security operations do have many ways of helping each other be successful.  Automation of processes and robust software development are making technology better and hopefully these design ideas help you solve your secure code challenges too.
