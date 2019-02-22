---
layout: post
title: "OpenStack-Ansible inventory happenings"
date: 2017-02-28 23:59
comments: false
author: Nolan Brubaker
published: true
authorIsRacker: true
categories:
    - OpenStack
    - Ansible
---

The OpenStack-Ansible inventory system is the glue connecting the Ansible
playbooks that do the installation to the hosts they manage. It is vital
to deploying and maintaining an Ansible-based cluster.

This system has undergone several changes since the initial Icehouse
release. Learn what's happened since and what's in store for the future.

<!-- more -->

### Background

The OpenStack-Ansible project (also known as OSA) was first introduced with
the Icehouse release of OpenStack. It included an Ansible dynamic
inventory script, ``playbooks/inventory/dynamic_inventory.py``. This
script takes information from the OSA configuration files and produces host
information for generating LXC containers, which in turn host the
OpenStack services.

We also included some scripts to manage the generated inventory file, so
that maintenance tasks like removing a host could be done more easily.

### Recent developments

The function of the dynamic inventory has largely remained the same, but
a few key changes have happened over the life of the OSA project:

 - With the Kilo release, the script helped migrate configuration to a
 new, more flexible structure.
 - In Liberty, we began putting a more formal unit and integration test
 suite around the existing code.
 - With Newton, new logical groupings were generated to assist with
 targetting more specific hosts for work.
 - Beginning in Newton and continued in Ocata, the code has been
 refactored to be easier to understand.

### Future plans

In Pike, we hope to make the biggest change to the inventory system yet:
providing a plugin system for reading and writing to different backends.

This feature will help deployers use their existing systems for providing
configuration information, as well as a more robust method of storing
generated information.

To facilitate this change, we'll also be making the OSA inventory code
installable via pip, should others wish to take advantage of it.
