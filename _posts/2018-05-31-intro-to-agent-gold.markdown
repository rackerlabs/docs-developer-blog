---
layout: post
title: "Introduction to Oracle Agent Gold Images"
date: 2018-05-30 00:00
comments: true
author: Kuasik Das
published: true
authorIsRacker: true
categories:
    - Oracle
---

Originally published by Tricore: May 25, 2017

Agent Gold Image is a recent feature of Oracle&reg; Enterprise Manager
(OEM) that simplifies how you manage hosts and targets. This blog post
provides an overview of Agent Gold Images and walks you through the process of
using one to install an agent.

<!-- more -->

### Introduction

Oracle Management Agent (Management Agent) is a software component that
manages hosts and their targets. It's a part of OEM that's
deployed on every monitored host. In this blog post, we introduce the Agent
Gold Image. Introduced with OEM 13c, Agent Gold Image offers
impressive functionality that you can use to improve efficiency.

### What are Agent Gold Images?

Before diving into the details, let’s start with what Agent Gold Images are and
what they can do for you.

You can use Agent Gold Images to mass deploy and upgrade the management agents
in your environment. Prior to Agent Gold Images, upgrading and patching agents
were time-consuming, which meant that organizations preferred not to patch
agents. Thanks to the introduction of Agent Gold Images in OEM 13c, upgrades
and patching are now much easier. For example, you can apply multiple patches
to multiple agents in a single downtime. Agent Gold Images enables you to
manage a large number of Management Agents that have identical Management Agent
software, plug-ins, and patches.

The following screen capture illustrates the agent life cycle with Agent Gold
Images:

![The agent life cycle with Agent Gold Image]({% asset_path 2018-05-31-intro-to-agent-gold/picture1.png %})

In the screen capture, the Source Agent version is 13.1. All software
components, plug-ins, and the latest patches are already installed. Agent Gold
Image R1 is created from the source. It can be deployed to Batch 1, which is a
group of agents. That means that you can perform all the tasks required to
upgrade all of a server’s agents in a single downtime.

The screen capture also shows that you can create another Agent Gold Image,
R2, with additional patches, then test it on a source agent and use it to
update Batch 1. You can then deploy new agents using Agent Gold Image R2 on
Batch 2.

The screen capture shows that the next step is to create another Agent Gold
Image named R3 with agent bits 13.1, as well as updated plug-ins, patches, and
configuration properties, and then use R3 to update Batches 1 and 2. You can
also deploy new agents using Agent Gold Image R3 on Batch 3.

In summary, you can upgrade and patch a large number of management agents
simultaneously with Agent Gold Images.

### Install an agent with Agent Gold Image

Let's do a hands-on activity with Agent Gold Image.

To access this feature, log in to the Oracle Enterprise Manager Cloud Control
13C console and go to **Setup > Manage Cloud Control > Agent Gold Image >
Manage All Images**.

First, create an Agent Gold Image by using the following
steps:

1. Select **Create**.
2. Enter the image name, a description, and the platform name.
3. Click **Submit**.

![Creating an Agent Gold Image]({% asset_path 2018-05-31-intro-to-agent-gold/picture2.png %})

The **Manage All Images** screen shows the Agent Gold Image that you just
created.

![The Manage All Images screen showing the Agent Gold Image]({% asset_path 2018-05-31-intro-to-agent-gold/picture3.png %})

Next, create a version for the Agent Gold Image:

1. From the **Manage Images** screen, select **Version** and **Drafts**.
2. Choose **Create**.

The Agent Gold Image version is created as a draft, as shown in the following
screen capture:

![The Agent Gold Image draft]({% asset_path 2018-05-31-intro-to-agent-gold/picture4.png %})

Now we need to change the **Status** of the image from **Draft** to
**Current** by clicking the **Set Current version** button:

![Setting the Agent Gold Image to the current version]({% asset_path 2018-05-31-intro-to-agent-gold/set-current.png %})

You can see an overview of your Agent Gold Images through the Agent Gold
Dashboard:

![The Agent Gold dashboard]({% asset_path 2018-05-31-intro-to-agent-gold/picture5.png %})

Next, install an agent by using the Agent Gold Image. On the **Agent
Gold Image** screen, click the **Add Hosts** button:

![The **Add Hosts** button]({% asset_path 2018-05-31-intro-to-agent-gold/picture6.png %})

Enter the host name and platform name and select **With Gold Image**:

![The parameters for installing the agent]({% asset_path 2018-05-31-intro-to-agent-gold/picture7.png %})

After the installation finishes, the system displays information indicating
that the new agent is correctly subscribed to the Agent Gold Image.

![The screen shows that the new agent is correctly subscribed to the Gold
image]({% asset_path 2018-05-31-intro-to-agent-gold/picture8.png %})

### Conclusion

This feature makes it much easier to manage agents on OEM.
Using Agent Gold Image enables you to deploy or update the same agent at the
most recent patch level on multiple host levels. Even the rollback process is
simple. If an Agent Gold Image update fails, one of your older, non-Agent Gold
Image management agents automatically kicks in and picks up the slack.

In addition to improving functionality, Agent Gold Image is also much more
convenient. With Agent Gold Image, you no longer need to upgrade management
agents using the Agent Upgrade Console, apply patches with patch plans, or
manage plug-ins with the plug-in life cycle application, saving you time and
money.

Reference:
[Managing the Lifecycle of Agent Gold Images](https://docs.oracle.com/cd/E63000_01/EMADV/agent_gold_image.htm)
