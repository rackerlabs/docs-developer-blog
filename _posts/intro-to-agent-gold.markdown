---
layout: post
title: "Introduction to Oracle Agent Gold Image Feature"
date: 2018-05-30 00:00
comments: true
author: Kuasik Das
published: true
authorIsRacker: true
categories:
    - General
---

SUMMARY PARAGRAPH HERE

<!-- more -->

### Introduction

Oracle Management Agent (Management Agent) which is an integral software component that is deployed on every monitored host and responsible for managing hosts and its targets. In this blog I would like to introduce a relatively new feature-the Agent Gold Image of Oracle Enterprise Manager 13c. Agent Gold Image has some impressive functionalities that can be utilized for better efficiency.

### Agent Gold Image & Its Advantages

Before getting into the details of this new feature let’s start with what Agent Gold Image is and some of its advantages.

You can use Agent Gold Images for mass deployment and upgrade management agents in your respective environment. Prior to Agent Gold Image, upgrade and patching agents would take a long time and as a result of that organization preferred not to patch agents. When it comes to upgrades or patches, the vast number of agents prior to Agent Gold Image, it was time consuming. With the introduction of Golden images in OEM 13c, upgrade/patching is now much easier. Multiple patches can be applied to multiple agents in a single downtime. With the help of gold agent images we can facilitate a large number of Management Agents all of which are in the same versions of management Agent software, plug-ins and patches.

Let’s simplify Agent lifecycle – Agent Gold Image with the below illustration:

*****INSERT IMAGE*****

Image Source:http://www.sloug.org/resources/Documents/SLOUG%20EM13c%20and%20OMC%20Overview.pdf

In the picture above:
*** DO PROPER LETTERS HERE***
a)	Our Source agent version is 13.1 with all software components, plug-ins and latest patches already installed in it. We created an Agent Gold Image R1 from our source which can be deployed to Batch1 (A group of agents). Thus in a single downtime, we can perform the whole activity for upgrading all the server’s agents thus reducing downtime drastically on maintenance window. We don’t need separate downtime for accomplishing our tasks.
b)	Similarly, we can create another Agent Gold Image R2 with additional patches, test it on a source agent; and now update Batch1 with Agent Gold Image R2. Deploy new agents using Agent Gold Image R2 on Batch2.

c)	 From there, the next step is to create another gold image R3 with agent bits 13.1 and updated plug-ins patches and config properties. Update batch1 and batch2 with Agent Gold Image R3. Deploy new agents using gold image R3 on batch3. So we can upgrade/patch large number of management agents altogether with the help of Agent Gold Image.
d)
So it’s time to play with Agent Gold Image…

we can access this feature via our cloud control console from THE setup menu > Manage Cloud Control > Agent Gold Image > Manage All Images. The very first thing we’ll do is create a Gold Agent Image.

*****INSERT IMAGE*****

Now we need to select **Create** and enter the image name, A description, and the platform name, then **Submit**, and our Gold image is created.

*****INSERT IMAGE*****

The next step is to create a version for the Gold Agent Image. In the Manage Images screen, we select Version and Drafts and we choose Create:
The gold agent image version is created as a draft:

*****INSERT IMAGE*****

Next we need to select Set Current version, the status is now Current:

*****INSERT IMAGE*****

Next we can see our Gold Agent Dashboard:

*****INSERT IMAGE*****

Next, we’ll install agent using the gold agent image, from the Agent Gold Image screen, we select Add Hosts:

*****INSERT IMAGE*****

We’ll enter the hostname, the platform name and choose to install with Agent Gold Image:

*****INSERT IMAGE*****

Then the classical agent installation is running fine. At the end we can display that our new agent is correctly subscribed to the gold image.

*****INSERT IMAGE*****

### Conclusion

This new feature has eased the agent management on the Enterprise manager, using Agent Gold Image will allow you to deploy or update the same agent at the most recent patch level on multiple host level. Even rollback process is very simple. If Gold Agent update fails then our old agent will come up automatically.

This new feature also provides both convenience and improved functionality where users need not upgrade management agents using the Agent Upgrade Console, apply patches using Patch plans, manage plug-ins using the plug-in lifecycle application, and so on.

Reference:
https://docs.oracle.com/cd/E63000_01/EMADV/agent_gold_image.htm#EMADV14552
