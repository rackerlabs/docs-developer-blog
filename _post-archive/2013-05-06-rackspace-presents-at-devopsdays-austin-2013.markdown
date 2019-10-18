---
layout: post
title: Rackspace presents at DevopsDays Austin 2013
date: '2013-05-06 15:00'
comments: true
author: Nicholas Mistry
published: true
categories:
  - Events
---
Last week, Austin hosted [DevOpsDays](https://devopsdays.org/), an DevOps-focused event featuring innovative talks and great networking, with some great music and food thrown in the mix. The two-day event focused on sharing ideas to strengthen the DevOps movement by building a culture around highly agile and productive teams with integrated development and operations.<!-- more -->

Our Rackspace team presented some of its insights into DevOps during their talks. Rackspace Linux Engineer Nick Silkey emphasized the need to make infrastructure “[programmable, testable, [and] deployable](https://speakerdeck.com/filler/level-up-from-ops-to-engineers).” He discussed ways to structure foundations and applications to create a more fault-tolerant service, which can result in a turnkey software platform for developers.  

Jesse Gonzalez, a senior engineer on the Cloud Integration team, brought up [the difficulties associated with NIH Syndrome (Not Invented Here)](https://speakerdeck.com/sifusam/nih-syndome-pitfall-or-paradise). Oftentimes, it feels as though it would be best to craft software solutions specifically for each problem; but frequently, other developers have already been down that road. Instead of rebuilding and starting over from the beginning, it is better to focus on adding increased functionality and better metrics. 

Working in parallel is better than working serially. Paul Voccio, Director of Infrastructure Engineering, gave an extremely meaty Ignite talk about how [Cloud Servers deploys code to tens of thousands of nodes](https://speakerdeck.com/pvoccio/deploying-10-000-nodes-simultaneously) using tools like BitTorrent, puppet and virtualenv. He discussed the beneficial switch from deploying with packages to pushing code in virtualenv, which reduced the deploy time by orders of magnitude. 

Everett Toews, Developer Advocate and co-author of [OpenStack Operations Guide](https://docs.openstack.org/ops/), presented “[Cloud Provisioning: The SDKs Under the Hood](https://www.slideshare.net/phymata/cloud-provisioning-the-sdks-under-the-hood)” (check out video from his talk [here](https://www.youtube.com/watch?v=pY-3JXjmu58)). He gave an introduction to the various language bindings that interface with Rackspace’s open cloud, as well as usage benefits.  Extensive documentation and examples are available online, but if you prefer to talk, support was only a call away. 

In addition to the Rackspace talks, there were some fantastic talks from others in the industry. Riverbed’s Peco Karayanev gave a great talk, “Why does monitoring suck? Because it is rooted in detecting failure, and not preventing it,” which had an important takeaway: If it’s not broken, it may be breaking. By tracking close calls, you can gain insight into potential failures with the hopes of preventing them.  It’s not good enough to just set an arbitrary threshold and wait for the system to respond. He recommends that managers “allow time for your team to do more analysis work, equip them with good data, and reward them for tracking close calls and preventing problems.”

Another great lesson was “Be mean to your code” and have security testing be part of your continuous integration cycle. James Wickett, core contributor to the [Gauntlt project](https://gauntlt.org/), talked about the effectiveness of utilizing it as a development tool. For those that are not familiar with Gauntlt, its introduction video describes it as a way to “facilitate security testing that can be hooked into your continuous integration systems.”   Gauntlt makes it extremely easy to get started with a starter kit that runs on top of virtualbox / vagrant. 

The organizers rounded out the event with some great fun. [Lord Buffalo](https://lordbuffalo.tumblr.com/) rocked the house, and the [Austin Film Society](https://www.austinfilm.org/) showed a screening of [Office Space](https://www.imdb.com/title/tt0151804/).

The attendees brought their own expertise to the open round tables and there were some great candid discussions about the future of DevOps. I look forward to continuing the dialogue with them online.

See you next year!