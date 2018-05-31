---
layout: post
title: "Introduction to Oracle Agent Gold Images"
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

Oracle&reg; Management Agent (Management Agent) is an integral software
component that manages hosts and their targets. It's a part of Oracle
Enterprise Manager (OEM) that's deployed on every monitored host. In this post
we'll introduce a relatively new feature: the Agent Gold Image. New with OEM
13c, Agent Gold Image has some impressive functionality that you can use to
improve efficiency.

### Agent Gold Image and its advantages

Before getting into the details of this new feature let’s start with what
Agent Gold Image is and some of its advantages.

You can use Agent Gold Images to mass deploy and upgrade the management agents
in your environment. Prior to Agent Gold Image, upgrade and patching agents
were time-consuming, which meant that organizations preferred not to patch
agents. With the introduction of Gold Images in OEM 13c, upgrades and patching
are now much easier. For example, you can apply multiple patches to multiple
agents in a single downtime. Gold Images enables you to manage a large number
of Management Agents that have identical Management Agent software, plug-ins,
and patches.

The following screen capture illustrates the agent lifecycle with Agent Gold
Image:

![The agent lifecycle with Agent Gold Image]({% asset_path 2018-05-31-intro-to-agent-gold/picture1.png %})

In the screen capture above, the Source Agent version is 13.1 with all software
components, plug-ins, and the latest patches already installed. Agent Gold
Image R1 was created from the source. It can be deployed to Batch 1, which is a
group of agents. That means that you can perform all of the tasks required to
upgrade all of the server’s agents in a single downtime, drastically reducing
maintenance windows.

The screen capture also shows that you can create another Agent Gold Image,
R2, with additional patches, then test it on a source agent and use it to
update Batch 1. You can also deploy new agents using Agent Gold Image R2 on
Batch 2.

The screen capture shows that the next step is to create another Gold Image
named R3 with agent bits 13.1, as well as updated plug-ins, patches, and
configuration properties, and then update Batches 1 and 2 with R3. You can
also deploy new agents using Gold Image R3 on Batch 3. In summary, we can
upgrade and patch a  large number of management agents simultaneously with
Agent Gold Image.

### Practice with Agent Gold Image

Let's do a hands-on activity with Agent Gold Image.

To access this feature, log in to the Oracle Enterprise Manager Cloud Control
13C console and go to **Setup > Manage Cloud Control > Agent Gold Image >
Manage All Images**.

The first thing we’ll do is create an Agent Gold Image by using the following
steps:

1. Select **Create**.
2. Enter the image name, a description, and the platform name.
3. Click **Submit**.

![Creating an Agent Gold Image]({% asset_path 2018-05-31-intro-to-agent-gold/picture2.png %})

 The **Manage All Images** screen shows the Agent Gold Image you just created.

![The Manage All Images screen showing the Agent Gold Image]({% asset_path 2018-05-31-intro-to-agent-gold/picture3.png %})

Next we'll create a version for the Agent Gold Image:

1. From the **Manage Images** screen, select **Version** and **Drafts**.
2. Choose **Create**.

The Agent Gold Image version is created as a draft, as shown in the following
screen capture:

![The Agent Gold Image draft]({% asset_path 2018-05-31-intro-to-agent-gold/picture4.png %})

Next we need to to change the **Status** of the image from **Draft** to
**Current** by clicking the **Set Current version** button:

![Setting the Agent Gold Image to the current version]({% asset_path 2018-05-31-intro-to-agent-gold/set-current.png %})

You can see an overview of your Agent Gold images through the Agent Gold
dashboard:

![The Agent Gold dashboard]({% asset_path 2018-05-31-intro-to-agent-gold/picture5.png %})

Next we’ll install an agent by using the Agent Gold image. From the **Agent
Gold Image screen**, select **Add Hosts**:

![The **Add Hosts** button]({% asset_path 2018-05-31-intro-to-agent-gold/picture6.png %})

Enter the host name and platform name and select **With Gold
Image**:

![The parameters for installing the agent]({% asset_path 2018-05-31-intro-to-agent-gold/picture7.png %})

After the installation finishes, the system displays information indicating
that the new agent is correctly subscribed to the Gold Image.

![The screen shows that the new agent is correctly subscribed to the Gold
image]({% asset_path 2018-05-31-intro-to-agent-gold/picture8.png %})

### Conclusion

This new feature makes it much easier to manage agents on Enterprise Manager.
Using Agent Gold Image enables you to deploy or update the same agent at the
most recent patch level on multiple host levels. Even the rollback process is
simple. If an Agent Gold update fails one of your older, non-Agent Gold
management agents automatically kicks in and picks up the slack.

In addition to improving functionality, Agent Gold is also much more
convenient. With Agent Gold, you no longer need to upgrade management agents
using the Agent Upgrade Console, apply patches with patch plans, or manage
plug-ins with the plug-in lifecycle application, saving you time and money.

Reference:
https://docs.oracle.com/cd/E63000_01/EMADV/agent_gold_image.htm#EMADV14552
