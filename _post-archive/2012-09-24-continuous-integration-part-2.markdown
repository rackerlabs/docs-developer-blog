---
comments: true
date: 2012-09-24T09:47:33.000Z
layout: post
title: 'Continuous Integration and Rackspace, part 2'
author: Hart Hoover
categories:
  - Cloud Servers
  - Jenkins
---

_This is part 2 of a series of using continuous integration with the Rackspace Cloud, specifically with Git and Jenkins. This is not the way Rackspace does continuous integration, but you can use this to get started. Stay tuned for future posts on using Jenkins for continuous integration._

In my last post, I described the [principles of continuous integration and how to install Jenkins on a Rackspace Cloud Server](https://devops.rackspace.com/continuous-integration-part-1.html). In this post, we will walk through securing your Jenkins installation as well as setting up a git repository with Jenkins.

<!-- more -->

### Securing Jenkins


Now that Jenkins is up and running, it's time to secure it. Click "Manage Jenkins" -> "Configure System." Make sure your options match the options below:

{% img center 2012-09-24-continuous-integration-part-2/jenkins_security.jpg %}

Don't forget to add a user with full permissions here. We are going to create the user in a moment. Go ahead and click "Save". You will be kicked out and have the ability to create your user. Once you log back in, uncheck "Allow users to sign up" - you will only log in with your user from now on.

### Github and Jenkins

Now that you have a Jenkins environment set up and secured, it's time to set up your Github repository. Follow the steps below to install git and set up a SSH key:
    
    apt-get -y install git
    su - jenkins
    
    git config --global user.name "Jenkins"
    git config --global user.email "youremail@yourbusiness.com"
    
    ssh-keygen -t rsa # You can use the default options here. Don't set a password.
    cat .ssh/id_rsa.pub # Add this key to your Github account
    
    ssh git@github.com # Add Github to your know_hosts file

Next you need to set Jenkins to use Github, and for that we need the Github [plugin](https://wiki.jenkins-ci.org/display/JENKINS/Github+Plugin). Log into Jenkins and click the following:

* Manage Jenkins
* Manage Plugins
* Click the "Available" tab
* Check "Github plugin"
* Click the "Download now and install after restart" button
* Check the box that restarts Jenkins once the install is complete

### Your first Jenkins project

Jenkins is set up to access your Github account. Now it's time to create your first project that will get the latest copy of your code, test it, and deploy it. A Jenkins project is made up of several components:

* Your git repository
* Triggers that tell Jenkins to perform a build
* A build script that actually performs tasks (ant, maven, shell script, or batch file)
* Any information you wish to collect from the build
* Notifications of a build's result

To create a project, log back into Jenkins and click "New Job", then give your project a name and select "Build a free-style software project." Click through to the next screen where the real fun happens. Type up a quick description of what your project is doing, then scroll down to the "Source Code Management" section. You want to add your git repository here (in this example I'm using [django](https://www.djangoproject.com/)):

{% img center 2012-09-24-continuous-integration-part-2/git-jenkins.jpg %}

Next, scroll down to the "Build Triggers" section. You can use [crontab](https://www.thegeekstuff.com/2009/06/15-practical-crontab-examples/)-like scheduling to poll your repository for changes, but since you're using Github I recommend you select "Build when a change is pushed to GitHub":

{% img center 2012-09-24-continuous-integration-part-2/jenkins-build.jpg %}

The next section is called "Build." Click the "Add build step" button and then click "Execute shell." These are the commands that you want to use to test and deploy your project.

You can then set a post-build action, such as emailing you the results. Click "Save."

### For more information

Jenkins has [plugins](https://wiki.jenkins-ci.org/display/JENKINS/Plugins) for almost everything you need to start using Continuous Integration with your applications. The OpenStack project also uses continuous integration for application builds, which you can read about [here](https://ci.openstack.org/).
