---
layout: post
title: Speeding up SSH session creation
date: '2013-04-03 08:00'
comments: true
author: Greg Brockman
published: true
categories:
  - Cloud Servers
---

Establishing a new SSH connection usually takes only a few seconds, but if you're connecting to a server multiple times in succession the overhead starts to add up. If you do a lot of Git pushing and pulling or frequently need to SSH to a dev server, you've probably felt the pain of waiting for SSH to connect so you can get back to doing work.

One of SSH's lesser known features is the ability to reuse an already-established connection when creating a new SSH session. This means you only have to pay the connection overhead once, making future sessions incredibly quick to start.

<!-- more -->

One way to enable this feature is to add the following to your `~/.ssh/config`:

```
Host *
ControlMaster auto
ControlPath ~/.ssh/sockets/%r@%h-%p
ControlPersist 600
```

Here's a line-by-line breakdown of what this does:

```
Host *
```

This line instructs `ssh` to apply the following rules to every host you SSH to. If you'd like these rules to apply only to a subset of the hosts you connect to, you can instead specify something like `Host *.example.com`.

```
ControlMaster auto
```

The `ControlMaster` option is one of SSH's best kept secrets. It instructs SSH to reuse an existing connection to the server if it already exists. This means that, if you run `ssh example.com`, open another terminal, and run `ssh example.com` there, the two sessions will be transported over the same underlying connection. The second session starts much more quickly because the SSH handshake has already been completed.

There are a few gotchas to be aware of with connection sharing. SSH uses lexical comparison to decide whether to reuse a connection, so if the DNS record for `example.com` changes to point at a new server, you'll still end up using an existing socket to an old one. If you're in an environment where hosts are often rebuilt, this behavior can be pretty confusing.

Since you're tunneling all of your traffic over the same TCP stream, a second gotcha is that a bandwidth-constrained operation such as a file transfer can block lighter-weight operations such as text editing.

```
ControlPath ~/.ssh/sockets/%r@%h-%p
```

`ControlPath` is a specification of where to create the control socket on your filesystem. If you use the value provided here, make sure to manually `mkdir ~/.ssh/sockets`. At any time, you can manually remove the control socket (using plain-old `rm`), and the next `ssh` invocation will establish a new connection. This is especially useful if you've recently reopened your laptop and your SSH connections haven't yet figured out that the server terminated them (especially prevalent if you're connecting through a VPN).

```
ControlPersist 600
```

Without `ControlPersist`, once the first SSH session you open is closed, all other sessions on that connection are closed as well. This can lead to a variety of surprising behavior: if you exit the initial SSH shell while other sessions are sharing the connection, the process will just hang. If you send it a Ctrl-C, all of those other sessions will be abruptly terminated.

In contrast, with `ControlPersist` set, the master connection will remain open for the specified number of seconds after your last SSH session on that connection has exited. This is especially useful for tasks such as pushing to Github, which occur frequently but where any one session is short-lived.

If you're interested in more details, you can view the full documentation on configuring the SSH client by running `man ssh_config` or view the [web-based man page](http://linux.die.net/man/5/ssh_config).

_This is a guest post written by Greg Brockman, an engineer at [Stripe](https://stripe.com/). Stripe makes it easy to start accepting credit cards on the web today._
