---
layout: post
title: "Azure to Alibaba S2S VPN"
date: 2018-11-15 00:00
comments: true
author: Jimmy Rudley
published: true
authorIsRacker: true
categories:
    - Azure
---

Businesses today are becoming more multi-cloud than ever. When it comes to Sitecore deployments, being able to have fast page response times in China are becoming more critical. My goal is to create a secure site to site vpn tunnel between Azure and Alibaba. Once the tunnel is setup, I can then test out remote publishing target deployments.

<!-- more -->

Starting off on the Azure side, we need to create a vnet with a non-overlapping address range to what our other cloud provider network will be using. Once the vnet has been created, create a new **Gateway Subnet**. Now that a Gateway Subnet has been defined, create a **Virtual Network Gateway** in Azure. 
Make sure to select **route-based** as the **VPN type**

While the Azure VPN Gateway is provisioning, log into the Alibaba Cloud dashboard. At this point, we want to mimic the steps from Azure, but within Alibaba Cloud. Create a VPC and a Vswitch







