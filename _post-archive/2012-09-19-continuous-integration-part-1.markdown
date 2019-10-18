---
comments: true
date: 2012-09-19T08:00:00.000Z
layout: post
title: 'Continuous integration and Rackspace, part 1'
author: Hart Hoover
categories:
  - Cloud Servers
  - Jenkins
---

_This is part 1 of a series of using continuous integration with the Rackspace Cloud, specifically with Git and Jenkins. This is not the way Rackspace does continuous integration, but you can use this to get started. Stay tuned for future posts on using Jenkins for _continuous integration_.
_

Continuous integration when used in software development is the practice of frequently integrating one's new or changed code with the existing code repository. Historically, developers would check out a code base and make changes. When submitting those changes back to the repository, the developer would have to integrate their work with code other developers had already changed. The longer the developer's personal repository had been checked out, the more difficult the integration process became. With the fast pace of web development, developers need to be able to commit and integrate changes quickly and automatically. Continuous integration helps with that.

<!-- more -->

A major proponent of continuous integration is [Martin Fowler](https://en.wikipedia.org/wiki/Martin_Fowler), who came up with 10 key principles:

	
  * Maintain a code repository

	
  * Automate the build

	
  * Make the build self-testing

	
  * Everyone commits frequently

	
  * Every commit (to baseline) should be built

	
  * Keep the build fast

	
  * Test in an environment that is identical to production

	
  * Make it easy to get the latest version

	
  * Everyone can see the results of the latest build

	
  * Automate deployment


There are [several applications](https://en.wikipedia.org/wiki/Comparison_of_continuous_integration_software) out there that follow these principles and make continuous integration easy. The application I will focus on is [Jenkins](https://jenkins-ci.org/). From its website, Jenkins is an application that monitors executions of repeated jobs, such as building software or jobs run by cron. Basically, Jenkins does two things:

	
  * Building/testing software projects continuously

	
  * Monitoring execution of external jobs


Using a [Rackspace Cloud Server](https://www.rackspace.com/cloud/public/servers/) running Jenkins and a git repository I can test builds of my software to make sure I didn't overlook anything when committing code.


### Create a server and install Jenkins


First, I'll create a server using the nova command:

    
    $ nova boot --image 5cebb13a-f783-4f8c-8058-c4182c724ccd --flavor 3 --file /root/.ssh/authorized_keys=sshkey.pub jenkins.harthoover.com


Once it boots up with my SSH key, I log in, update everything and reboot (this step isn't all that necessary, but I find it's just good practice):

    
    $ apt-get update && apt-get -y upgrade && reboot


Now we have an up-to-date Ubuntu 12.04 server. Time to install Jenkins. Ubuntu has a package available in its repository, but I want the latest and greatest. To get the latest available version you need to configure your server to use the Jenkins repository:

    
    $ wget -q -O - https://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | sudo apt-key add -
    $ echo deb https://pkg.jenkins-ci.org/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list
    $ apt-get update
    $ apt-get -y install jenkins


Jenkins is now running on port 8080. Stay tuned for part two of this series, which will showcase the process of securing Jenkins and configuring it with a git repository. If you want more information on companies using Jenkins for continuous integration, Intuit describes their process [here](https://www.drdobbs.com/tools/building-quickbooks-how-intuit-manages-1/240003694?pgno=1).
