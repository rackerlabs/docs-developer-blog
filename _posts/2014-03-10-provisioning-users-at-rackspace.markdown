---
layout: post
title: Provisioning users at Rackspace
date: '2014-03-10 10:30'
comments: true
author: Topher Marie
published: true
categories:
  - Devops
---

**This is a guest post from Topher Marie, VP of Engineering at JumpCloud.**

I’ve got a new Unix server up at RackSpace and I need to get my users some
accounts on it. How do I go about doing that? I could copy and paste each of
their passwords… well, I guess really I should have them come type their
passwords, shouldn’t I? Actually, I know that public key authentication is
more secure and robust than [password-based][passwd_vs_pubkey]. I’m going to
go with that. Let’s make the assumption that each of the users that I want to
give access to this machine have public/private key pairs already setup.
[Here][setup_keys] are some basic notes for that procedure to get you started.

<!-- more -->

### Create and log in to the new server

After creating the new server in RackSpace’s user interface they give me the
Root Admin Password. Copy this password down, we’re going to need it for a
little bit until we get our users set up.

### Create the user

We can create the users without actually logging into the machine using the
following ssh command. Note that I’m specifically NOT creating a real password
for these guys. I’m insisting that they use public key authentication, so I’m
not going to bother with retrievable passwords. I’ll set them to something
nonsensical. Alternately I could get them to give me hashed passwords, but
that’s not necessary unless I decide to provision them as sudo.

```sh
ssh root@162.209.88.33 "adduser beta --password somerand0mjunkitypedwithcr@zy$tuff"
```
(note that I can get away with this because that’s not the password… it’s
the hash of some even worse password. Use the manpage for adduser for more
information.)

It will prompt you for the root password from above, of course.

### Set the user's public key

Again, assume that I’ve got public keys for each user I want to add.
Creating the private/public key pair should ideally be done by the end user,
otherwise I’ve had access to their private key which is a plausible security
hole.

This command will take their public key (I'm assuming it's in a file called
beta.pub) and put it in the correct location in the user's directory.

```sh
cat beta.pub | ssh root@162.209.88.33 "cat >> ~beta/.ssh/authorized_keys"
```
Change some ownership and permissions of these newly created elements

```sh
ssh root@162.209.88.33 "chown -R beta ~beta/.ssh; chmod -R go-rwx ~beta/.ssh"
```

All right, now we have the user all prepared for public key authentication.
I’ll want to do this for each user that belongs on that machine of course.

### Configure the system to use public key authentication

Let’s login directly to the machine as root (using the initial password above).

```sh
ssh root@162.209.88.33
```

From here we’re going to get our hands dirty in some ssh config. You should
probably leave this shell open until you're sure you can get in with another
user... and you should make sure that you have a root or sudo user account
that can login as well. Otherwise you'll be locked out with no way to fix
things.

Good? Ok, edit the file

```sh
/etc/ssh/sshd_config
```

You can turn off password-based authentication by changing
```sh
PasswordAuthentication yes
```
to
```sh
PasswordAuthentication no
```
Save the file and close

The last step we have to take is to tell the service to restart
```sh
service sshd restart
```

That’s it. Now I’ve provisioned my users to a single machine.

### More user management

There are some sticky parts here. It’s a little more labor than I really
like. I need to get public keys from each of my users, of course. I have to
do this for each machine. Every time I spin one up. Even managing the set of
current users, their keys, etc… is kind of a pain. And I didn’t even try to
get their passwords managed. Multi-factor authentication? Forget about it.
Need to reset a single account? I have to be logged in as root in order to
make these changes. In any largish company… this is a ton of work.

Did I mention how we’re going to go and remove all of these users? Did you
keep track of which users went on which machines? If not, that means you’ll
likely need to perform an audit of your servers next time someone leaves the
company to make sure they don’t have any lingering accounts out there. Not a
pleasant prospect, eh?

That’s where JumpCloud comes in. They make it simple to do all your
provisioning of users from one simple interface. Users are onboarded through a
simple interface. They’re directly prompted for a password and public key,
and all of the provisioning is done for you.

When you want to add a user to a machine, it’s as simple as a few clicks in
our interface. Want to remove them? Takes seconds. Did they forget their
password? You don’t even need to be involved. We authenticate their identity
via email and reset their password across the entire system. Entirely
self-service.

It’s not that you can’t do all of these things, you certainly can. It’s just
that it’s a lot of work and not where you want to spending your valuable time.

Check us out at [JumpCloud][jumpcloud] for this and many of your other DevOps needs.


[passwd_vs_pubkey]:http://security.stackexchange.com/questions/3887/is-using-a-public-key-for-logging-in-to-ssh-any-better-than-saving-a-password
[setup_keys]:https://help.github.com/articles/generating-ssh-keys
[jumpcloud]:http://www.jumpcloud.com