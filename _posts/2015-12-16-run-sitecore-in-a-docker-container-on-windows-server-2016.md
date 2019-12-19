---
layout: post
title: Run Sitecore in a Docker container on Windows Server 2016
date: '2015-12-16 10:45'
comments: false
author: Jimmy Rudley
published: true
authorAvatar: 'https://en.gravatar.com/userimage/151177997/5bed7e07ee47533cbd34b951d463bcb7.jpg'
bio: “Jimmy Rudley is an Azure Architect at Rackspace and an active member of the Azure community. He focuses on solving large and complex architecture and automation problems within Azure."
categories:
  - Docker
---

At SUGCON 2015, Rackspace and Hedgehog presented about how using Docker will shape the way we work with Sitecore, an ASP.Net web content management system. With the release of Windows Server 2016 Technical Preview 4, we are now able to run Sitecore in a Docker container. 

<!-- more -->
Why run Sitecore in a Docker container? Here are a few challenges that are now solved:
  - Consistent enviornments for production, staging, dev, qa
  - Portability of Docker images
  - Can add additional containers in seconds to scale out
  - Can roll back to older images in seconds if code does not work as expected

To start running Docker containers, we will need a Docker host. Microsoft wrote a PowerShell script that can configure the VM host for you if you are running Windows 10 or Windows Server 2016 TP2+. You can grab the detailed instructions [here](https://msdn.microsoft.com/virtualization/windowscontainers/quick_start/container_setup)

My main objective is to take an existing Sitecore 8.0 installation on my laptop and move it into a container image. I used the Sitecore web application installer to do a quick local installation. I am using SQL Azure for my sql server, but as long as you can hit your sql server from your container, however you choose to host the databases will work just fine.

Once you setup your Docker host, using the Microsoft PowerShell script, you need to create an IIS image. Use the following command to see a list of available images on your Docker host:

```sh
docker images
```

You will see a list of available images on your Docker host.

```sh
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
windowsservercore   10.0.10586.0        6801d964fda5        6 weeks ago         0 B
windowsservercore   latest              6801d964fda5        6 weeks ago         0 B
```

To search the Microsoft repo for what images are available, use the following command:

```sh
docker search microsoft
```

You will see a list of images available to pull down.

```sh
NAME                 DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
microsoft/aspnet     ASP.NET 5 framework installed in a Windows...   1         [OK]       [OK]
microsoft/django     Django installed in a Windows Server Core ...   1                    [OK]
microsoft/dotnet35   .NET 3.5 Runtime installed in a Windows Se...   1         [OK]       [OK]
microsoft/golang     Go Programming Language installed in a Win...   1                    [OK]
microsoft/httpd      Apache httpd installed in a Windows Server...   1                    [OK]
microsoft/iis        Internet Information Services (IIS) instal...   1         [OK]       [OK]
microsoft/mongodb    MongoDB installed in a Windows Server Core...   1                    [OK]
microsoft/mysql      MySQL installed in a Windows Server Core b...   1                    [OK]
microsoft/nginx      Nginx installed in a Windows Server Core b...   1                    [OK]
microsoft/node       Node installed in a Windows Server Core ba...   1                    [OK]
microsoft/php        PHP running on Internet Information Servic...   1                    [OK]
microsoft/python     Python installed in a Windows Server Core ...   1                    [OK]
microsoft/rails      Ruby on Rails installed in a Windows Serve...   1                    [OK]
microsoft/redis      Redis installed in a Windows Server Core b...   1                    [OK]
microsoft/ruby       Ruby installed in a Windows Server Core ba...   1                    [OK]
microsoft/sqlite     SQLite installed in a Windows Server Core ...   1                    [OK]
```

There is a good spread of images from Ruby, Redis, ASP.Net 5, IIS, etc. We could build our own image by launching a new container and installing IIS and ASP.Net, but let's pull an existing image instead.

On your Docker host, create a new directory called **c:\iisdemo**. We will use this directory to hold our dockerfile we will create. A dockerfile is just a set of instructions to build a Docker image. 

To create a dockerfile, launch **notepad.exe** and type in the following instructions:

```sh
FROM microsoft/iis
#The FROM keyword sets the base image for subsequent instructions. We are telling docker to use the microsoft/iis image. We do not have this locally, but Docker is smart enough to pull it down locally for us.

RUN dism /online /enable-feature /all /featurename:IIS-ASPNET45 /NoRestart
#The RUN keyword will execute any commands in a new layer on top of the current image and commit the results. I am telling it to run dism to install the asp.net 4.5 features for IIS
```

Alternatively, we could use PowerShell to install asp.net 4.5. That dockerfile would look like

```sh
FROM microsoft/iis
RUN powershell -executionpolicy bypass -command "add-windowsfeature Web-Asp-Net45"
```

Please save your dockerfile to c:\iisdemo and call it "dockerfile". 

Let's build the image, you'll need to execute the dockerfile by running

```sh
docker build -t iisdemo c:\iisdemo\
```

The ` -t ` flag tags the new image as iisdemo and ` c:\iisdemo\ ` tells Docker where to look for the dockerfile. Following is an excerpt of the build process:

```sh
c:\>docker build -t iisdemo c:\iisdemo\
Sending build context to Docker daemon 2.048 kB
Step 1 : FROM microsoft/iis
latest: Pulling from microsoft/iis
6a182c7eba7e: Pull complete
39b8f98ccaf1: Pull complete
Digest: sha256:a067c38b623c411e2cdcb8425860c894730cb27c021dd1f1cb479cd21a031cd7
Status: Downloaded newer image for microsoft/iis:latest
 ---> 39b8f98ccaf1
Step 2 : RUN dism /online /enable-feature /all /featurename:IIS-ASPNET45 /NoRestart
 ---> Running in c9f7059858d3
 ```

If you now type

```sh
docker images
```

You will see your new image in our local repo called iisdemo.
Let's start our IIS web server container up and test to make sure we can connect. Before you start the container, you'll need the IP address of the container host, and you need to allow port 80 through the firewall.

On the Docker host, open a PowerShell prompt and type:

```sh
c:\>powershell
Windows PowerShell
Copyright (C) 2015 Microsoft Corporation. All rights reserved.

PS C:\> New-NetFirewallRule -Name "TCP80" -DisplayName "HTTP on TCP/80" -Protocol tcp -LocalPort 80 -Action Allow -Enabled True
```

Exit out of your PowerShell prompt. Now you can build the iisdemo container by running

```
docker run --rm -it -p 80:80 iisdemo cmd
```

This will launch a container, listening on port 80, with an interactive cmd prompt and remove the container once we exit out of it. 
If I now browse from my laptop to the Docker VM host ip address, I am presented with the IIS10 splash page. Success! Now, let's create another dockerfile to deploy Sitecore.

I have a file called **raxcont.zip** which contains my Sitecore installation. There are a few ways to get the zip file into our container image, but I am going to copy it to my container host, and then use the ADD keyword in my dockerfile to copy it into my new container image. We can run a simple net use to grab our files and copy them to our Docker host

```sh
mkdir c:\sitecore
net use * \\ip\share
copy z:\raxcont.zip c:\sitecore\
```

Launch **notepad.exe** to create a new dockerfile and paste the following into it

```sh
FROM iisdemo
RUN mkdir c:\sitecoreDocker
WORKDIR /sitecoreDocker
ADD raxcont.zip /sitecoreDocker/raxcont.zip
RUN powershell -executionpolicy bypass -Command "expand-archive -Path 'c:\sitecoreDocker\raxcont.zip' -DestinationPath 'c:\inetpub\wwwroot\'"
RUN /windows/system32/inetsrv/appcmd.exe set vdir "Default Web Site/" -physicalPath:"c:\inetpub\wwwroot\raxcont\website"
```

When we build from this dockerfile, it will use our iisdemo image, make a directory called c:\sitecoreDocker, add the file **raxcont.zip** to c:\sitecoreDocker\, unzip the file to c:\inetpub\wwwroot and finally set the default web site physical path to our unzipped location.

Let's build our image by typing

```sh
docker build -t sc c:\sitecore
```

We can now launch a container with our Sitecore deployment.

```sh
docker run --rm -it -p 80:80 sc cmd
```

Browse to your docker host IP and the default sitecore page shows up.


I hope this gives you a good intro to Docker on Windows Server 2016 with Sitecore. Windows Server 2016 is still in technical preview and there still are a lot of limitations and bugs, but seeing Sitecore run out of a container is a good step in the right direction. I did run into issues with the ASP.NET MVC framework not being able to load in the container. This will break content editing, among other things, but as Microsoft matures the container offering, we will be ready to use Docker with Sitecore. In my next post, I will show us how to install a fresh Sitecore instance using a dockerfile.




