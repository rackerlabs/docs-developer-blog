---
layout: post
title: VMSS With AutoScale And IIS
date: '2015-12-04 10:45'
comments: false
author: Jimmy Rudley
published: true
authorAvatar: 'https://en.gravatar.com/userimage/151177997/5bed7e07ee47533cbd34b951d463bcb7.jpg'
bio: “Jimmy Rudley is an Azure Architect at Rackspace and an active member of the Azure community. He focuses on solving large and complex architecture and automation problems within Azure."
categories:
    - Azure
---

Virtual Machine Scale Sets, which was recently released in preview from Microsoft, lets you manage a set of virtual machines as one.

<!-- more -->

The idea is that you set your instance count to how many machines you want, and it will provision an identical set. You also have the option to add the Microsoft.Insights/autoscaleSettings type, which lets you dynamically scale up and down based on CPU load over an aggregation type you can [set]. Some benefits of using VMSS are:

  - Supports Azure Resource Manager
  - Can make use of custom script extensions
  - Can deploy Linux and Windows images

I wanted to test out a simple scenerio: provision 1 web server vm, then scale based on CPU load. I have published a [Visual Studio project] to my github repo that has an ARM JSON template already configured for VMSS along with a simple ASP.NET webpage that will let you simulate cpu load over a period of time. Let's go over some key points and gotchas

  - You are still bound to the processor count in your subscription.
  - This is still in preview. I have seen some funkyness during initial provisioning.
  - Make use of the [Azure Resource Explorer] to discover properties you dont know exist.
  - Microsoft.Compute/virtualMachineScaleSets capacity is how many virtual machines should be initialized in the scale set
  - Microsoft.Compute/virtualMachineScaleSets upgradePolicy has 2 options. Manual: Only new VMs are affected when a template is redeployed. Automatic: Specifies that all machines in the scale set are updated and restarted.
  - Preview is limited to 100 VMs.

I do my ARM development in Visual Studio, so I am using that for my deployment. If you are using Azure Powershell 1.0, I have already updated the Deploy-AzureResourceGroup.ps1 in the project. If you are using an older version of Azure Powershell, I left the original version Deploy-AzureResourceGroupOld.ps1 in the project for you to rename and use, if you like. The other option is to deploy with the Azure CLI or Azure Powershell cmdlet's.

Once deployed, you will have a single A1 VM behind a load balancer, with 2 load balancer rules and a dynamic nat pool. The load balancer has 2 rules, port 80 and port 443. I am not making use of port 443, but wanted to leave it in as a reference sample on how to add multiple rules. You will have nat rules created automatically for each vm. Please start at port 50000 when rdp'ing in and increment for each vm.

If you browse to your public ip provisioned, you will have a simple ASP.NET webpage asking how long to generate cpu load for.  Assuming you have a 1 core VM, my JSON template specifies

```
							{
								"metricTrigger": {
									"metricName": "\\Processor(_Total)\\% Processor Time",
									"metricNamespace": "",
									"metricResourceUri": "[concat('/subscriptions/',subscription().subscriptionId, '/resourceGroups/',  resourceGroup().name, '/providers/Microsoft.Compute/virtualMachineScaleSets/', parameters('vmSSName'))]",
									"timeGrain": "PT1M",
									"statistic": "Average",
									"timeWindow": "PT5M",
									"timeAggregation": "Average",
									"operator": "GreaterThan",
									"threshold": 50.0
								},
								"scaleAction": {
									"direction": "Increase",
									"type": "ChangeCount",
									"value": "1",
									"cooldown": "PT5M"
								}
```
  - If my cpu usage is greater than 50% for 5 minutes while sampling every 1 minute, increase my vm count by 1. Once we have scaled out, the cool down period is 5 minutes

```
							{
								"metricTrigger": {
									"metricName": "\\Processor(_Total)\\% Processor Time",
									"metricNamespace": "",
									"metricResourceUri": "[concat('/subscriptions/',subscription().subscriptionId, '/resourceGroups/',  resourceGroup().name, '/providers/Microsoft.Compute/virtualMachineScaleSets/', parameters('vmSSName'))]",
									"timeGrain": "PT1M",
									"statistic": "Average",
									"timeWindow": "PT5M",
									"timeAggregation": "Average",
									"operator": "LessThan",
									"threshold": 40.0
								},
								"scaleAction": {
									"direction": "Decrease",
									"type": "ChangeCount",
									"value": "1",
									"cooldown": "PT5M"
								}
							}
```
  - If my cpu usage is less than 40% for 5 minutes while sampling every 1 minute, decrease my vm count by 1.

You can verify if a scaleup or scaledown operation happened by looking at either your audit logs for the scaleset in the Azure portal or the capacity count in the portal.

I hope this gives you a good intro to virtual machine scale sets. My next post will cover deploying Sitecore content delivery nodes using VMSS. If you have any questions, feel free to reach out to me at jimmy.rudley at rackspace.com

   [set]:<https://msdn.microsoft.com/en-us/library/azure/dn931944.aspx#bk_metric>
   [visual studio project]: <https://github.com/jrudley/vmssLBNatIIS>
   [Azure Resource Explorer]: <https://resources.azure.com>

