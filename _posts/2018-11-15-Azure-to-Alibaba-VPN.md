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

Starting off on the Azure side, we need to create a vnet with a non-overlapping address range to what our other cloud provider network will be using.
![VNET]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/createvnet.png %})

Once the vnet has been created, create a new **Gateway Subnet**. Now that a Gateway Subnet has been defined, create a **Virtual Network Gateway** in Azure. 
Make sure to select **route-based** as the **VPN type**
![GatewaySubnet]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/gatewaysubnet.png %})

While the Azure VPN Gateway is provisioning, log into the Alibaba Cloud dashboard. At this point, we want to mimic the steps from Azure, but within Alibaba Cloud. Create a **VPC** and a **Vswitch** and do not overlap the IP address range used in Azure. 
![VPC]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/ab-vpc-vswitch.png %})

Next, create a **VPN Gateway** and select the VPC you previously created.
![VPNGateway]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/abvpngw.png %})

Within the Azure portal, create a Local Network Gateway. Take the public ip address from the Alibaba VPN Gateway and type it into the **IP address** text box in Azure. Specify the Alibaba VPC CIDR address space in the **Address space** text box. Select create to provision the resource
![LocalGateway]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/alngw.png %})

Within the Alibaba portal, create a **Customer Gateway**. This is similar to a Local Network Gateway in Azure. Type in the public ip address from Azure's VPN Gateway into the **IP Address** text box
![CustomerGateway]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/abcustomergateway.png %})

The next step is to configure the connections to both gateways. In Alibaba, select **Create an IPSec Connection** and choose the VPC and VPN Gateway. Type in the IP CIDR of your Alibaba local network in **Local Network** then type in the IP CIDR of your Azure Network in **Remote Network**. Slect **Yes** for Effective Immediately. 
![config1]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/abip1.png %})
Enable the Advanced Configuration option to list the Ike configurations. Generate a 16bit pre-shared key and type it into the **Pre-Shared Key** text box. Select **Ikev2** for **Version**, **aes256** for **Encryption Algorithm**, **28800** for **SA Life Cycle (Seconds)**.Under the **IPsec Connections** label, select **aes256** and **28800** for **SA Life Cycle (seconds)** 
![config2]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/abip2.png %})
![config3]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/abip3.png %})

In the Azure Portal, navigate to your **Local Network gateway** connection object. Select **Connections** from the blade then select **Add**. Give your connection a **name**, select your **VPN Gateway** and type in your pre-shared key that was used in Alibaba IKE Configuration.
![localConnection]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/azconnection.png %})

The final step is to add a route entry into your Alibaba VPC Route Table. Within your VPC, edit the route table and add a new entry. Type in the remote network cidr block, set the **Next Hop Type** to **VPN Gateway** and select your VPN Gateway.
![route]({% asset_path 2018-11-15-Azure-to-Alibaba-VPN/abroute.png %})

At this point, we have a route based Site-to-Site vpn configured between Azure and Alibaba Cloud. I stood up a SQL Server and frontend Sitecore content delivery node and configured a remote publishing target. Benchmarking from US to China for a remote publish was not favorable due to random timeouts. Looking at the Sitecore publishing service, I deployed an Azure webapp and configured publishing that route. Publishing was instantly faster and did not have anymore timeouts.





