---
layout: post
title: 'Introducing PoshStack, the PowerShell client for OpenStack'
date: '2015-02-12 12:15'
comments: true
author: Don Schenck
published: true
categories:
  - OpenStack
  - DevOps
  - Automation
bio: 'Don Schenck is a Developer Advocate with the Developer Experience team at Rackspace, with a main focus on .NET technologies. Follow @DonSchenck on Twitter.'
---

### Here's PoshStack

OpenStack SDKs exist for several programming languages, including Python, Go,
Ruby, and many more. For those who don't wish to write code, users in the *nix
world can use Curl at the command line to perform operations.

What about Microsoft Windows administrators? Are they required to learn linux
and bash and curl? What if they could use the skills they already have, or learn
new skills that are native to the Windows environment, for OpenStack administration?
Is there a command line or scripting tool that suits the Windows DevOps world?

<!-- more -->

PoshStack answers those questions with a resounding: "Yes. Windows admins can use
PowerShell and PoshStack".

### Ooooh ... tell me more...

Sitting atop the robust OpenStack .NET SDK, PoshStack allows Windows administrators
to engineer OpenStack solutions from the command line or the PowerShell Integrated
Scripting Environment (ISE), without needing to write code in C# (or any other
low-level .NET language). PoshStack allows users to leverage PowerShell's
object-oriented approach to scripting to rock the OpenStack world.

And because PoshStack follows the
[guidelines for PowerShell naming](https://msdn.microsoft.com/en-us/library/ms714428\(v=vs.85\).aspx),
developers and administrators can quickly get up to speed. Retrieving a list of
servers is as simple as:

```
Get-ComputeServers -Account MyAccount
```

### But does it...

Support Identity (Keystone)? Yes.

Handle cloud compute (Nova)? Yup.

Cloud object storage (Swift)? No problem.

Cloud block storage (Cinder)? You betcha.

What about the things that aren't (yet) covered? Well, here's the good news: PoshStack is open source, meaning anyone -- including you -- can add functions, fix defects, build examples, create awesome documentation ... all the bits and pieces that make up a successful software product. There are some guidelines, to be sure, but you'll find any help to be appreciated, guidance gladly given, and feedback to be positive.

### Talk is cheap; show me something

Okay. You want to create a Virtual Machine (VM) using PoshStack?

```
New-ComputeServer -Account MyAccount -ServerName MyNewServer -ImageId 03ce0d51-7d3f-489b-845d-9edff88b40f9 -FlavorId performance1-2
```
That's it; that's all it takes to create a server from PowerShell. No API calls,
no urls to type, no headers or verbs or RESTful interface details. One line, in
PowerShell, keeping with the typical PowerShell experience.

### What's the catch?

The catch is: There is no catch. You can install PoshStack using two lines of
PowerShell (one if you use a semi-colon) and get started today.

### Okay, I'm in. How do I start?

Simply go to the [PoshStack Github repository](https://github.com/DonSchenck/PoshStack)
and follow the installation instructions.


### Questions?

No problem. [Head on over to the Github repository](https://github.com/DonSchenck/PoshStack),
and you'll be up and running in no time.

If you're a Windows administrator or developer, and you're ready to hone your
PowerShell skills and tackle "the cloud" at the same time, get PoshStack and get
going right now. Who knows where it might lead?
