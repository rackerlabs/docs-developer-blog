---
layout: post
title: 'New features in Cloud Servers: Key pairs and manual disk partitioning'
date: '2013-09-05 08:00'
comments: true
author: Trey Hoehne
published: true
categories:
  - Cloud Servers
---
Most people would agree that more automation is a good thing, especially
if your day to day involves any type of server administration. Saving
yourself time on a repetitive task is almost always a good thing. To
that end we would like to save you some time with a couple of new features
available for building Cloud Servers, Server Key Pairs and the Disk
Partition option. <!-- more -->

### Server key pairs

Previously, managing server access for new builds was accomplished one
of two ways: key injection at boot via the API with [Server Personality][1]
or use of the password supplied in the API’s response for the build. Key
pair authentication is widely accepted as the more secure option for
managing access to your servers plus it’s easier to scale.  Here’s how
to accomplish a few key related tasks using Rackspace’s novaclient:

Before you can boot a server and use the key pair feature it is
necessary to either create a new key or upload an existing key.

Creating a new key:

`$ nova keypair-add mykey > mykey.pem`

This action creates a new key named ‘mykey’ that you can associate with
your instances on boot. You’ll notice that you now have a file with the
.pem extension, which is your private RSA key packaged and encoded for
you.

The .pem file is created with permissions higher than needed so a quick
chmod is required before proceeding.

`$ chmod 600 mykey.pem`

Uploading an existing public key:

`$ nova keypair-add --pub-key mykey.pub mykey`

This action will upload an existing public key named `mykey.pub` and
associate it with the name `mykey`. Note: this only supports RSA encoded
key pairs and not DSA encoded key pairs.

Now that we’ve associated a key pair with a name via the API we can boot
a server with the --key-name option.

`$ nova boot --image fedora --flavor 2 --key-name mykey testserver`

As soon as our ‘testserver’ boots we can login using our newly injected
keys with SSH.

`$ ssh -i mykey.pem root@1.2.3.4`

You can set ssh to use your key by default or specify it each time with
the `-i` option. The last step is to disable password authentication on
your server and only use key pair authentication.

To list the current keys stored:

`$ nova keypair-list`

To delete a key:

`$ nova keypair-delete mykey`

If you would like to obtain the public key that is associated with the
private key in your .pem you can do so with ssh-keygen.

`$ ssh-keygen -y -f mykey.pem > mykey.pub`

If you’re not using the novaclient or you’re interacting with the API
via one of the SDKS, here is the full [documentation][2] on available actions
for Server Key Pairs in the API.

### Server disk partition

This feature has been available via the API for some time but was
recently added to the Customer Control Panel as the Disk Partition
option. In a nutshell, this feature determines how your server’s disk is
partitioned on build.

A Linux image is built with a default 20GB root partition; this root
partition is then expanded to encompass the extra disk that comes with
the available server flavors.

The larger the disk, the more time it takes to format and expand the
root partition to utilize that extra space. This is great if you know
that your server is going to utilize more than 20GB of disk but if
you’re building a larger flavor for the additional RAM or CPU that might
not be something that interests you.

If this is the case you can pass the `--disk-config` option on boot
via the API or the nova client:

`$ nova boot --image fedora --flavor 5 --disk-config manual`

Not having to wait for a server to format and expand its root partition
can shave several minutes off the time it takes for a server to be
available. The time saved increases exponentially with flavors that have
a larger disk. It’s up to you to choose whether or not you’d like to
create an additional partition to utilize the un-allocated disk space on
your server or only use the 20GB root partition. It’s important to note
that resizing down is restricted so the faster build times and higher
degree of control comes with that limitation.

Here at Rackspace we're always happy to bring you new and useful features to make your experience in the cloud easier. If you have features or ideas that you would like to see feel free to suggest them to your Account Manager.

[1]: http://docs.rackspace.com/servers/api/v2/cs-devguide/content/Server_Personality-d1e2543.html
[2]: http://docs.rackspace.com/servers/api/v2/cs-devguide/content/ServersKeyPairs-d1e2545.html
[3]: http://docs.rackspace.com/servers/api/v2/cs-devguide/content/ch_extensions.html#diskconfig_attribute
