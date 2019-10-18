---
layout: post
title: Using Rackspace Private Cloud to Support Your Software Development Lifecycle
date: '2014-08-29 16:00'
comments: true
author: James Thorne
published: true
categories:
  - openstack
  - private-cloud
bio: >
  James Thorne is a Sales Engineer at Rackspace focused on working with
  OpenStack. He is a Texas State University alumnus and former Platform
  Consultant at Red Hat. James has been working with Linux professionally for
  the past four years and in his free time even longer. James blogs at
  thornelabs.net and can be followed on Twitter @jameswthorne.
---

Last week, I presented a live webinar on [using Rackspace Private Cloud to support your software development lifecycle](https://youtu.be/s9GNgYUpXyU).

The following post, the fourth of several in the [RPC Insights series](https://www.rackspace.com/blog/welcome-to-rpc-insights/), will be a summary of that live webinar. I will be discussing a general overview of the software development lifecycle, why Rackspace Private Cloud is a good fit for this use case, and demonstrating how to integrate Jenkins with GitHub.

<!-- more -->

This is the second of three use case webinar/blog posts in the RPC Insights series. The first use case webinar/blog post talked about using Rackspace Private Cloud to host your web tier applications. If you happened to miss the last webinar and are interested in watching it, please go [here](https://developer.rackspace.com/blog/using-rpc-host-web-tier-apps/). There you will find a link to the recorded webinar as well as a blog post discussing why Rackspace Private Cloud is a great fit for your cloud ready web applications, why you may need to migrate your web application from a public cloud to a private cloud, discuss and provide a concept architecture of a cloudy web tier application, and discuss an overview of bursting into the Rackspace Public Cloud from your Rackspace Private Cloud.

Book Recommendation
-------------------

Before we begin, I would like to pass on a book recommendation from a colleague.

If you have been tasked with implementing a software development lifecycle, perhaps continuous integration, continuous delivery – otherwise known as CICD - in your work place, I have been told that the book __Continuous Delivery: Reliable Software Releases through Build, Test, and Deployment Automation by Jez Humble and David Farley__ is the bible of continuous delivery.

You can easily find the book on Amazon where you can read through the first half of Chapter 1. It immediately dives into what you need to know to begin implementing continuous integration and continuous delivery.

What is a Software Development Lifecycle?
-----------------------------------------

Unlike many other definitions in the information technology field, when you hear the term __software development lifecycle__ it actually makes sense; it is the process your software goes through to build, deploy, test and ultimately release it.

There are many different ways that a software development lifecycle can be setup and it will vary greatly from company to company and project to project.

As you may expect, there are a handful of different software development lifecycle models.

SDLC Models
-----------

If you go to [Wikipedia](https://en.wikipedia.org/wiki/Software_development_process), search for __Software development process__, and go to the __Software development models__ section, you will see a handful of various models such as waterfall, spiral, iterative and incremental, agile, rapid application deployment, and code and fix.

Of those models, I am going to touch on the Waterfall and Agile models.

Waterfall Model
---------------

{% img matte full 2014-08-29-using-rpc-software-dev-lifecycle/waterfall-model.png waterfall-model %}

First, the Waterfall model.

[Wikipedia](https://en.wikipedia.org/wiki/Waterfall_model) provides a good definition of the Waterfall model:

> The waterfall model is a sequential design process, used in software development processes, in which progress is seen as flowing steadily downwards (like a waterfall) through the phases of Conception, Initiation, Analysis, Design, Construction, Testing, Production/Implementation, and Maintenance.

As stated by [Herbert Benington](https://en.wikipedia.org/wiki/Waterfall_model#cite_note-1):

> The waterfall development model originates in the manufacturing and construction industries; highly structured physical environments in which after-the-fact changes are prohibitively costly, if not impossible. Since no formal software development methodologies existed at the time, this hardware-oriented model was simply adapted for software development.

Because a "hardware-oriented model was simply adapted for software development" you can imagine there are bound to be problems. A physical thing is very difficult to change after-the-fact, but software is much less difficult to change after-the-fact and there are always after-the-fact changes in software development.

This is where the advocates of the Agile model criticize the Waterfall model. 

Also from [Wikipedia](https://en.wikipedia.org/wiki/Waterfall_model):

> [those critics] argue the waterfall model is a bad idea in practice—believing it impossible for any non-trivial project to finish a phase of a software product's lifecycle perfectly before moving to the next phases and learning from them

So, what does the Agile model bring to the table?

Agile Model
-----------

{% img matte full 2014-08-29-using-rpc-software-dev-lifecycle/agile-model.png waterfall-model %}

Second, the Agile model.

As you may expect, the Agile model brings a more flexible approach to the software development process.

Instead of finishing one phase and going to the next, like you do in the Waterfall model, you break apart the entire cycle into smaller groups of works, or as the diagram above shows, sprints.

Continuous integration comes into play here. [It was created for the Agile model](https://www.ibm.com/developerworks/rational/library/continuous-integration-agile-development/). Part of the idea is to not solve everything up front, but to focus on what you know and go through the Discover, Design, Develop, and Test phases for that particular feature and then implement it. Once that is complete, the same process is done for the next set of requirements or features.

Martin Fowler of ThoughtWorks provides a very good definition of continuous integration: 

> Continuous integration is a software development practice that requires team members to integrate their work frequently. Every person integrates at least daily, which leads to multiple integrations each day. Integrations are verified by an automated build that runs regression tests to detect integration errors as quickly as possible. Teams find that this approach leads to significantly fewer integration problems and enables development of cohesive software more rapidly.

With the multiple integrations each day, the feedback loop on whether or not the code worked is shortened. This allows the developer to quickly fix a potential bug and move onto the next task.

Why
---

So, with that brief overview of the Waterfall and Agile models, why is Rackspace Private Cloud a suitable platform for your software development lifecycle? You could just as easily use a public cloud for your software development lifecycle.

In the last webinar, I built a narrative around using Rackspace Private Cloud to host your web tier applications. I talked about how a company had been running their web application on the Rackspace Public Cloud for some time without any issues, but as it had grown it was beginning to make more sense to migrate the web application to a Rackspace Private Cloud based on several factors.

So, lets build a similar narrative for a software development lifecycle. Similar to the last webinar, there are some key factors as to why you may want to use a private cloud instead of a public cloud.

The Narrative
-------------

Your new start-up is working on its first product. You need a common environment where you can develop, test, and deploy your software. You will use tools such as git, GitHub/GitHub Enterprise, Gerrit, and Jenkins to version control, store, review, and test your software.

What are the factors influencing your decision to run your environment within a private cloud instead of a public cloud?

### More control

First, more control.

As mentioned, you could easily use a public cloud for your software development lifecycle, but your software is crucial to your business and is not something you want to store and test on hardware you do not control.

In addition, every piece of software is different and is going to require very particular test cases. You need to be able to customize as much of your environment as possible to fit your test cases. You can only customize so much in a public cloud.

Running your entire development environment in a private cloud gives you the control needed to tweak things exactly to your needs.

### Privacy and Security

Second, Privacy and Security.

Your software is the cornerstone of your start-up. It needs to be developed, reviewed, tested, and deployed in an environment you control and only you are using.

Rackspace Private Cloud can be hosted and managed from a Rackspace data center or, if you have extra security requirements or simply a preference, your own data center.

Either way, the gear OpenStack and your software runs on is entirely yours.

In addition, OpenStack provides mechanisms that allow you to wall off individuals or departments so they do not interfere or impact each other.

### Common infrastructure

Third, common infrastructure.

A common problem when developing software is testing it on infrastructure that is similar to the production environment.

You could have multiple Rackspace Private Cloud environments. In one environment you develop, test, and deploy your code, and in the second, identical, environment you deploy to production.

Or you could have one, large Rackspace Private Cloud environment where you isolate Tenants and computes nodes to ensure your development environment does not interfere with your production environment.

In the end, the flexibility is up to you.

### Isolated environments

Fourth, isolated environments.

Rackspace Private Cloud is powered by OpenStack. OpenStack natively gives you the ability to have isolated environments. Through the use of Tenants, also known as Projects, you can isolate entire user environments from each other. 

You can use Availability Zones and Host Aggregates to spin up OpenStack Instances on particular compute nodes. This is important because you could be running Dev, Test, and Production on the same OpenStack environment and through the use of Availability Zones and Host Aggregates you can ensure your development OpenStack Instances are created on different compute nodes than your production OpenStack Instances.

And you can use create Neutron Tenant Networks to quickly create software defined networks that are isolated from any other network. These networks can be connected together through the use of Neutron Routers.

Demo
---

So, with those four factors, and there are always more, you have decided to deploy your development and test environments into a Rackspace Private Cloud.

But, what are some of the tools used within the development and test environment?

In the following demo I am going to demonstrate integrating GitHub and Jenkins.

I am going to show you how to setup your first Jenkins Project, how to automate builds when pushing changes to a GitHub repository, and how to automate builds when GitHub Pull Request are made against your GitHub repository.

Even though I will be using GitHub, for the sake of the narrative, pretend I am demonstrating GitHub Enterprise and Jenkins. [GitHub Enterprise](https://enterprise.github.com) is a paid-for product from GitHub that allows you to essentially run GitHub within your own firewalls. No one but you has access to it. It makes sense to run it on top of Rackspace Private Cloud which is also behind your own firewalls. Jenkins can of course be run behind your own firewalls as well.

The following sections will be a text based install of what was mentioned above. If you'd prefer to watch the process instead, please watch the webinar at timestamp 15:13 [here](https://www.youtube.com/watch?v=s9GNgYUpXyU#t=913).

### Install Jenkins

First, you need to install Jenkins.

The following steps will assume you are running Ubuntu Server 12.04 LTS.

The following steps have been copied from the [Jenkins Wiki](https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu). If you prefer to not use Ubuntu, you can find steps to install on RHEL/CentOS [here](https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Red+Hat+distributions).

Log into the server you want to install Jenkins on.

Update apt with the latest packages: 

    sudo apt-get update

Install Java and git:

    sudo apt-get install openjdk-7-jdk git

Download and import the Jenkins package apt public key:

    wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -

Add the Jenkins repository to apt:

    sudo sh -c 'echo deb https://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'

Update apt with the latest packages:

    sudo apt-get update

Install Jenkins:

    sudo apt-get install jenkins

If you are running a host-based firewall, be sure to open port 8080.

In addition, if you want to access Jenkins over port 80, you can use iptables to redirect the traffic like so:

    sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
    sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443

Verify the Jenkins service is running:

    service jenkins status

If for some reason the Jenkins service is not running, start it with the following command:

    service jenkins start

### Configure Jenkins Authentication and Users

A fresh Jenkins install has no authentication setup. Jenkins has a lot of different authentication options. For the purpose of this post, you will be simply configuring an __admin__ user.

Open a web browser and navigate to the IP address or hostname Jenkins is listening on.

Go to __Manage Jenkins__.

Go to __Configure Global Security__ and check __Enable security__.

Under __Access Control__ and __Security Realm__, check the __Jenkin's own user database__ checkbox, uncheck the __Allow users to sign up__ checkbox, and click __Save__.

Now, go back to __Manage Jenkins__ and click __Manage Users__.

Click __Create User__ and create an __admin__ user.

Go back to __Manage Jenkins__ and click __Configure Global Security__ again.

Under __Access Control__ and __Authorization__, select the __Logged-in users can do anything__ radio button, and click __Save__.

You will now be prompted to login with the __admin__ user you just created.

If for some reason you lock yourself out, you can simply uninstall and reinstall Jenkins with __apt__.

Now when ever someone goes to the Jenkins web interface, and does not login, they can see the projects and there build status, but they can't modify anything. They must have a user account to modify anything.

### Install Jenkins GitHub Plugins

A fresh Jenkins install does not have any plugins to interface with GitHub. You will be installing three plugins so you can interface with GitHub.

Log into the Jenkins web interface, go to __Manage Jenkins__, go to __Manage Plugins__, and click the __Available__ tab.

Find the following three plugins and check their checkbox:

* GitHub Plugin
* GitHub pull request builder plugin
* Github OAuth Plugin

Once those three plugins have been checked, click __Download now and install after restart__.

Finally, check the __Restart Jenkins when installation is complete and no jobs are running__ checkbox.

Jenkins will restart and the new GitHub plugins will be available to configure.

Installation should be quick. If the page does not refresh for you, simply navigate to the IP address or hostname Jenkins is listening on again.

### Create a GitHub Repository

You are going to need a GitHub repository to tie your Jenkins job to. This can be any GitHub repository.

For this post, I am going to be referencing a GitHub repository called __hello-world__. You can make the same GitHub repository in your GitHub account to follow along or use a different one.

### Create Your First Jenkins Project

You are now ready to create your first Jenkins project.

Open a web browser and navigate to the IP address or hostname Jenkins is listening on.

Login to the Jenkins web interface with the __admin__ user you created earlier.

Click __New Item__.

Give the item a name, I will input __hello-world__. I recommend not using spaces in your __Item name__ because it could cause build problems.

Select the __Build a free-style software project__ radio button and click __OK__.

Go to the __Source Code Management__ section and select __Git__.

Under __Repositories__ and __Repository URL__ input the https URL of the GitHub repository you created. For example:

    https://github.com/user/hello-world.git

The __Credentials__ drop-down menu should have __none__ selected.

The __Branches to build__ text box can be left as __*/master__. For the sake of simplicity, you are going to just build the master branch throughout this post. A better way to do this is to build a dev branch and then merge it into master branch assuming the build succeeds and all tests pass.

Now, scroll down to the __Build__ section, click __Add build step__, select __Execute shell__, and input the following in the text box:

    $WORKSPACE/hello-world.py

Click __Save__.

Finally, click __Build Now__.

Jenkins will clone the GitHub repository to its working directory and execute the __hello-world.py__ command above. Based on the output of this, the build will either succeed or fail.

So, this setup isn't very useful. Jenkins is doing exactly what you would do if you cloned the GitHub repository to your workstation and then executed the code. There is nothing automated here. Let's fix that by configuring Jenkins to build the GitHub repository every time a change is pushed to it.

### Build a Jenkins Project Every Time a Change is Pushed

_Be aware that for this to work Jenkins needs to be running on a publicly accessible IP address so GitHub can communicate with it._

First, you will need to create an SSH private/public key for the jenkins user.

Log into the server running Jenkins and run the following command:

    sudo -u jenkins ssh-keygen

This will create an SSH private/public key for the __jenkins__ user in __/var/lib/jenkins/.ssh__.

Go back to the Jenkins web interface, go to __Credentials__, click __Global credentials__, and click __Add Credentials__.

In the __Kind__ drop down menu select __SSH Username with private key__.

The only change needed is to select the __From the Jenkins master ~/.ssh__ radio button and then click __OK__.

Log back into the server running Jenkins and run the following command:

    cat /var/lib/jenkins/.ssh/id_rsa.pub

Copy the output to your clipboard.

Go to your GitHub repository page and click __Settings__ (it will be on the right hand side of the page under __Pulse__ and __Graphs__).

Go to __Deploy keys__ and click __Add deploy key__.

Give the SSH public key a __Title__, paste in your clipboard contents into __Key__, and click __Add key__.

Go back to the Jenkins web interface, go to __Manage Jenkins__, click __Configure System__ and scroll down to the __GitHub Web Hook__ section (it will be at the bottom of the page).

Click the __Let Jenkins auto-manage hook URLs__ radio button.

Fill out the __API URL__ with __https://api.github.com__.

Leave the __Username__ text box blank.

You will need to generate a GitHub OAuth token for Jenkins to use.

Go back to the GitHub repository you are integrating Jenkins with, go to  __Settings__ (it will be a gear icon in the upper right) and go to __Applications__.

In the __Personal access tokens__ section, click __Generate new token__.

Give the token a __Token description__, __jenkins__ will work fine, and check the __write:repo_hook__ checkbox in addition to whatever is already there.

Finally, click __Generate token__.

On the refreshed page the token will be displayed. Be sure to copy it because it will only be shown once. If you don't copy it now you will need to generate a new token.

Go back to the Jenkins web interface and add the token you copied to the __OAuth token__ text field.

Click __Test Credential__. Make sure it says __Verified__. Once it does, click __Save__.

Next, go back to the main Jenkins page and go to the __hello-world__ Jenkins project and select __Configure__.

In order for Jenkins to setup the web hooks properly in your GitHub repository, you need to change the __Repository URL__ to the SSH URL of the GitHub repository in the __Source Code Management__ section. For example:

    git@github.com:user/hello-world.git

Once that change has been made, click the __Credentials__ drop down menu and select __jenkins__ from the drop down menu. This is telling Jenkins to log in with the SSH public key you created earlier and clone the GitHub repository using the SSH protocol.

Scroll down to the __Build Triggers__ section and check the __Build when a change is pushed to GitHub__ checkbox.

Finally, click __Save__ at the bottom of the page.

Before trying a Jenkins build, go to the GitHub repository, click __Settings__ and go to __Webhooks & Services__. There should be a __Jenkins (GitHub plugin)__ entry under __Services__. With this in place, Jenkins has successfully setup web hooks in the GitHub repository.

Now clone the GitHub repository to your workstation, make a change, commit that change, and push the changes to the GitHub repository. If everything was setup properly, GitHub will initiate a web hook which will trigger Jenkins to clone the latest code and run a build. The moment you push the changes to the GitHub repository, go to the Jenkins web interface and watch the build process.

You have now automated your build process. Each time you push changes to the GitHub repository Jenkins will be notified and build the latest code. While this works well for a single developer project, it does not work very well for multiple developer projects. When multiple developers are part of a project they will be creating GitHub Pull Requests very often. The next, and last piece, to automate in this post is to have Jenkins automatically build any Pull Requests.

### Build a Jenkins Project Every Time a Pull Request Is Issued

_Be aware that for this to work Jenkins needs to be running on a publicly accessible IP address so GitHub can communicate with it._

Once again, go back to the Jenkins web interface, go to __Manage Jenkins__, go to __Configure System__, and scroll down to the __GitHub Pull Request Builder__ section.

The __GitHub server api URL__ is already filled in.

You can use the __OAuth token__ from the __GitHub Web Hook__ section in the __Access Token__ text box.

In the __Admin list__, add the GitHub user(s) that you want to allow to have their GitHub Pull Requests automatically built. Only GitHub users in this list will have automated Jenkins builds on each Pull Request.

Click __Save__.

Next you need to modify the __hello-world__ Jenkins project again.

Go back to the main Jenkins page and go to the __hello-world__ Jenkins project and select __Configure__.

Be sure to add in the GitHub repository URL to the __GitHub project__ text field at the top of the page. This part of the plugin relies on this. For example:

    https://github.com/user/hello-world/

Scroll down to the __Source Code Management__ section.

Click the __Advanced__ button on the right.

In the __Name__ text box input the following:
    
    origin

In the __Refspec__ text box input the following:

    +refs/pull/*:refs/remotes/origin/pr/*

Scroll down to the __Build Triggers__ section and check the __GitHub Pull Request Builder__ checkbox.

Check the __Use github hooks for build triggering__ checkbox.

Finally, click __Save__.

Now each time an authorized GitHub user issues a Pull Request against the __hello-world__ GitHub repository, GitHub will initiate a web hook which will trigger Jenkins to clone and build the code in the GitHub Pull Request. The status of the build will be displayed in the GitHub Pull Request comments.

You could take this further and have Jenkins merge the GitHub Pull Request on a successful build.

What you have configured so far is only a tiny fraction of what Jenkins is capable of. I encourage you to search throughout the internet to figure out ways to make your build process even more automated and streamlined.

What's Next
-----------

I have discussed a general overview of the software development lifecycle, discussed why Rackspace Private Cloud is a good fit for this use case, and demonstrated how to integrate Jenkins with GitHub.

This concludes the fourth of several posts in the [RPC Insights series](https://www.rackspace.com/blog/welcome-to-rpc-insights/).

Join us on September 10, 2014 at 10:00 AM CDT for a live webinar on [A Big Data Solution Running On Top of Rackspace Private Cloud](https://go.rackspace.com/big-data-solution-on-rpc.html).
