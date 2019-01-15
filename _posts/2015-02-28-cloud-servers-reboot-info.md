---
layout: post
title: 'cs-reboot-info: A tool to assist with upcoming maintenance'
date: '2015-02-28 13:00'
comments: true
author: Developer Experience Team
published: true
categories: []
---
**Important Update: Oct 17, 2015**

In addition to the dates listed below, this tool will also work for general
scheduled reboots and for specific maintenance periods.

**Original Post**

In the wake of
[recently announced vulnerabilities](http://xenbits.xen.org/xsa/) to the
Xen hypervisor that our Cloud Servers platform is built on top of, a reboot
will be necessary in some instances on both our First Generation and Next
Generation Cloud Servers. The details of our announcement are available in
[https://status.rackspace.com/](https://status.rackspace.com/).

In order to complete the patching of our systems, we have scheduled
reboot windows on a per-region basis beginning Monday March 2 and running
through Monday March 9. To discover the time ranges during which your
affected servers will be rebooted, your
[Cloud Control Panel](https://mycloud.rackspace.com/) will contain the
information for whichever region is currently visible (Note: you can change
this via the region selector on the left side of the control panel).
Alternatively, you can run our
[`cs-reboot-info`](https://github.com/rackerlabs/cs-reboot-info)
tool to discover the reboot windows of servers across all regions at once.
Binary downloads for many platforms are available
[here](https://github.com/rackerlabs/cs-reboot-info/#installation---binaries).

<!-- more -->

When given a username and API key, which can be found in the *Account Settngs*
section of our [control panel](https://mycloud.rackspace.com/), the utility
will list the reboot windows of affected servers in all regions across both
First Generation and Next Generation Cloud Servers.

    $ ./cs-reboot-info <username> <api key>
    Regions with a Cloud Servers endpoint: ORD, DFW, SYD, IAD, HKG
    Found both First and Next Generation endpoints.

    There are 2 Cloud Servers with an automated reboot scheduled.
    | Type           | Server ID | Server Name   | Reboot Window (UTC)         | Reboot Window (Local)       |
    | -------------- | --------- | --------------| --------------------------- | --------------------------- |
    | Next Gen (IAD) | 4fe9909b  | My IAD Server | 03 Mar 12:00 - 03 Mar 14:00 | 03 Mar 06:00 - 03 Mar 08:00 |
    | Next Gen (ORD) | 0f8482b6  | My ORD Server | 03 Mar 16:00 - 03 Mar 18:00 | 03 Mar 10:00 - 03 Mar 12:00 |

Additionally, a CSV file containing the details can be generated with
the `--csv` option.

    $ ./cs-reboot-info --csv <username> <api key>
    Regions with a Cloud Servers endpoint: ORD, DFW, SYD, IAD, HKG
    Found both First and Next Generation endpoints.

    Writing output to cs-reboot-info-output.csv

For more information, see
[https://github.com/rackerlabs/cs-reboot-info](https://github.com/rackerlabs/cs-reboot-info).
