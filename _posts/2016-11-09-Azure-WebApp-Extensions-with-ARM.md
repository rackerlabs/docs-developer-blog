---
layout: post
title: Azure Web App extensions With ARM templates
date: 2016-11-09 10:22
comments: false
author: Jimmy Rudley
published: true
authorAvatar: 'https://en.gravatar.com/userimage/151177997/5bed7e07ee47533cbd34b951d463bcb7.jpg'
bio: “Jimmy Rudley is an Azure Architect at Rackspace and an active member of the Azure community. He focuses on solving large and complex architecture and automation problems within Azure."
categories:
    - DevOps
    - Azure
---

You may have found the extensions tab when browsing in an Azure Web App. Selecting extensions to add to an application is as easy as just pointing and clicking. Moving outside of the portal to an ARM template, things get a little bit tricky because documentation is lacking.

<!-- more -->

When developing an ARM template, normally I build something in the portal and browse to [https://resources.azure.com/](https://resources.azure.com/) to see what properties are set and available. When doing this with a site extension, nothing was shown. After some digging around, I found out the type is called **siteextensions**. The extensions available to be installed can be found at a website called [siteextensions.net](http://www.siteextensions.net/). I was expecting an Azure PowerShell cmdlet that would list all the available extensions, similar to listing VM extensions, but nothing exists.  What I noticed is that the URL name for a site extension is the package name. Browsing to the New Relic package, the URL is https://www.siteextensions.net/packages/NewRelic.Azure.WebSites/ which says NewRelic.Azure.WebSites is the package name we need to pass into our ARM template name property. Knowing the type and name, we can deploy site extensions using an ARM template. Here is a snippet of the resources section:

```
    {
      "apiVersion": "[variables('extensionApi')]",
      "name": "[parameters('siteName')]",
      "type": "Microsoft.Web/sites",
      "location": "[resourceGroup().location]",
      "dependsOn": [

      ], /* Adding app settings here will overwrite any existing app settings. Be careful */
      "properties": {
        "name": "[parameters('siteName')]",
        "serverFarmId": "[parameters('appServicePlanName')]"
      },
      "resources": [
        {
          "apiVersion": "[variables('extensionApi')]",
          "name": "[parameters('extensionName')]",
          "type": "siteextensions",
          "dependsOn": [
            "[resourceId('Microsoft.Web/Sites', parameters('siteName'))]"
          ],
          "properties": {
          }
        }
      ]
    }
```
I put a comment noting that adding any application settings in an ARM template removes all existing application settings for your web app in Azure. Some extensions require application settings, so double check that you are not removing any existing application settings by inserting the extensions application settings in your template. This generic snippet will let you add any extension from [siteextensions.net](http://www.siteextensions.net/) to an existing web site. Just pass in the Site name, Service plan name, and extension name.
