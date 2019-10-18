---
layout: post
title: Operating your OpenStack Cloud using Ansible
date: '2015-07-21 09:00'
comments: true
author: Walter Bentley
published: true
categories:
  - Private Cloud
  - OSAD
  - OpenStack
  - Ansible
---

So you have spent months convincing your leadership to go with OpenStack.  Finally the keys of the cloud are turned over to you as the Cloud Operator, and you then look over at your co-workers and say “now what”.  The next set of phrases normally are something like: Now how do we best administer this cloud?  Cloud is suppose to be easier, right?

<!-- more -->

Well do not worry! Cloud can be easier and better depending on how you approach it.  As OpenStack has begun to be considered more of a mainstream cloud platform, the challenge of operating it after it is built has become prevalent.  While all cloud tasks can be executed via the API or CLI tool on a one by one basis, this would not be the best way to handle larger cloud deployments.  The need for a more automated approach to administering OpenStack is now clear.  The many IaaS capabilities OpenStack has to offer coupled with Ansible, an ease-of-use configuration management tool, provide a more complete cloud implementation.

Ansible has become a market leader in the Open Source orchestration and configuration management space.  Some of the reasons why Ansible is a good fit to automate OpenStack tasks are listed below:

* Only SSH and Python required on the target device, no clients/agents; can manage an environment of any size or type
* Existing Ansible modules for overall Linux management and OpenStack; working with OpenStack is like working with a complicated Linux kernel
* Ansible playbooks can be written against the OpenStack API’s or Python CLI’s
* Designing roles with unique variable values within playbooks/roles is as easy as writing a email
* Pre-built structure to create dynamic inventory scripts within Ansible

Below is a quick visual of how the flow of using Ansible to handle various administrative tasks within your OpenStack cloud.  In this flow starting from the top, you as the Cloud Operator would consume Ansible playbooks that were written by the DevOps team (typically this would be the administrators working with the developers, making up that DevOps dynamic).  From there, the playbooks can be executed against the OpenStack API’s directly or by using the services CLI’s.  Personally, I prefer to use the OpenStack CLI’s at this point as the Ansible OpenStack modules are not as mature as I prefer at this current time.  This issue is being actively addressed.  In fact, a half day session was dedicated to this topic at the last OpenStack Summit hosted in Vancouver.  Finally, at this point, the Cloud Consumer, depicted on the right in the flow, can utilize the resources created by, or capabilities add with, the administration playbooks.

![Ansible to OpenStack Flow](https://www.hitchnyc.com/content/images/2015/07/ansible-os-flow.png)

With the above approach in mind, you can go off and begin creating serious of playbooks/roles to handle typical daily Cloud Operator type tasks.  During the [webinar I presented last week](https://www.brighttalk.com/webcast/11427/163987), we walked thru some possible scenarios and how they could be easily/swiftly solved for using Ansible.  Instead of stepping thru them again, I felt it would be best to just provide the location on GitHub where you could review them and give them a try on your own.  Those working examples can be found at:  [https://github.com/wbentley15/ansiblefest-demo](https://github.com/wbentley15/ansiblefest-demo).  These examples are the very same demos shown during [AnsibleFest](https://www.ansible.com/blog/ansiblefest-nyc-speakers) held in New York this year.

In conclusion, I have found much success in helping customers with their OpenStack clouds by leveraging Ansible.  The Rackspace approach of deploying OpenStack, within our datacenter or within a customers' datacenters, is to use [OSAD (OpenStack Ansible Deployment)](https://github.com/stackforge/os-ansible-deployment), so taking it to the next level to handle operator tasks seemed very obvious.  As I call it, it's a two for one capability.  If you are interested in learning more about using Ansible to operate your OpenStack cloud, please be on the look out for my book entitled “OpenStack Administration with Ansible” set to hit online/in-stores end of this year.  Promise it will be a good read and reference when creating your OpenStack playbooks.
