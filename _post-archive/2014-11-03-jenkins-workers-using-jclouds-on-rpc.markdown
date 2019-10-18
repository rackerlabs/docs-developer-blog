---
layout: post
title: Create Jenkins Workers Using jclouds on RPC
date: '2014-11-03 16:00'
comments: true
author: Everett Toews
published: true
categories:
  - openstack
  - private-cloud
  - jclouds
bio: >
  Everett is a Developer Advocate at Rackspace making OpenStack and the
  Rackspace Cloud easy to use for developers and operators. Sometimes developer,
  sometimes advocate, and sometimes operator. He's a committer and PMC on Apache
  jclouds, and co-author of the OpenStack Operations Guide from O'Reilly. He
  loves spending time with his family. If it's calm outside, they launch
  rockets. If it's windy, they fly kites.

  Follow him on Twitter @everett_toews.
---

This blog post will show you how to dynamically create Jenkins workers on demand using jclouds on Rackspace Private Cloud. You can use those workers to run your build jobs and increase the capacity of your continuous integration pipeline by parallelizing builds. All powered by OpenStack.

<!-- more -->

This is a follow up post to [Using Rackspace Private Cloud to Support Your Software Development Lifecycle](https://developer.rackspace.com/blog/using-rpc-software-dev-lifecycle/) by James Thorne in the [RPC Insights series](https://www.rackspace.com/blog/welcome-to-rpc-insights/). In the original post you learned how to create a Jenkins master server. We will now extend that post by showing you how to create worker servers for that master.

## Install the jclouds Plugin

You'll need the [jclouds Plugin](https://wiki.jenkins-ci.org/display/JENKINS/JClouds+Plugin) in order to create worker servers.

1. Manage Jenkins
1. Manage Plugins
1. Available tab
1. Search for "jclouds"
1. Check the box
1. Click __Download now and install after restart__
1. Finally, check the __Restart Jenkins when installation is complete and no jobs are running__ checkbox.

Jenkins will restart and the plugins will be available to configure.

Installation should be quick. If the page does not refresh for you, simply navigate to the IP address or hostname Jenkins is listening on again.

## Configure the jclouds Plugin

Once installed you need to tell jclouds about your Rackspace Private Cloud.

1. Manage Jenkins
1. Configure System
1. Go to the __Cloud__ section
1. In the __Add a new cloud__ drop down, choose Cloud (jclouds)
1. Fill in the following properties:
 1. Profile: RPC
 1. Provider Name: openstack-nova
 1. End Point URL: https://my-rpc-identity-server.com:5000/v2.0/
 1. Max. No. of Instances: 10
 1. Retention Time: 5
 1. Identity: my-tenant-name:my-user-name
 1. Credential: my-password
 1. RSA Private Key: -----BEGIN RSA PRIVATE KEY----- ...
 1. Public Key: ssh-rsa ...
 1. Click __Test Connection__

You can click on the ? beside each field to get more information.

The End Point URL is the URL to the Identity (Keystone) server in your Rackspace Private Cloud.

The Identity is your tenant name followed by a ':' followed by your user name.

If you don't have a Private/Public Key handy, you can create one with the command `ssh-keygen -t rsa -N '' -f .ssh/id_rsa`. Copy the contents of `.ssh/id_rsa` into RSA Private Key and the contents of `.ssh/id_rsa.pub` into Public Key.

## Add a Cloud Instance Template

Now you'll need at least one template to create instances of your workers. You can create templates focused on running a specific job or more generalized templates that could build many kinds of jobs.

1. In the __Cloud Instance Templates__ section, click __Add__
1. Fill in the following properties:
 1. Name: jclouds
 1. Labels: java-builder
 1. Number of Executors: 1
 1. Hardware ID: (select an appropriate flavor)
 1. Image ID: Select __Specify Image Name Regex__
   1. Image Name Regex: (use an appropriate name regex)
   1. Click __Check Image Name Regex__
1. Click __Advanced__
1. Fill in the following properties:
 1. Location ID: (same region as your Hardware ID)
 1. Init script:
  1. `sudo apt-get update`
  1. `sudo apt-get -y install openjdk-7-jdk maven git`
  1. `# Or include whatever software you need to build your project`
1. Click __Save__

You can click on the ? beside each field to get more information.

Note that the Hardware Options and Image/OS Options are region specific. If you're specifying the ID directly, you'll need to prefix the ID with `[region]/`. e.g. `RegionOne/60178c0f-4b59-44de-ba45-1ef18463eb92`

## Manual Instance Creation

Create an instance to test your template.

1. Manage Jenkins
1. Manage Nodes
1. In the __Provision via jclouds - OpenStack__ drop down, click __jclouds__

This manually provisions an instance you can run a build on. You can check the Dashboard (Horizon) to see the progress of the instance.

## Run a Build Job

Run a build job to test your instance.

1. Go to the job you created in [Using Rackspace Private Cloud to Support Your Software Development Lifecycle](TODO)
1. Click __Configure__
1. Fill in the property:
 1. Label Expression: java-builder
1. Click __Apply__
1. Click __Build Now__

If everything works, delete the instance you manually provisioned.

1. Manage Jenkins
1. Manage Nodes
1. Click the Configure (tools) icon for that node
1. Click __Delete Slave__

## Configure Dynamic Instance Creation

To dynamically create an instance on demand to run a build job you need to change the job configuration.

1. In the __Build Environment__ section, check __jclouds Instance Creation__
1. Choose __Select Template from List__
1. Pick the template you created
1. Click __Apply__
1. Click __Build Now__

You can check the Dashboard (Horizon) to see the progress of the instance. Once the instance is running, go to the __Manage Nodes__ screen to and your new instance will (eventually) appear there. On the left-hand side of the screen you can watch the build job progress in the __Build Executor Status__ section.

After the Retention Time (set in the __Configure the jclouds Plugin__ above) has expired, the instance will automatically be deleted.

## Conclusion

If you want to increase the capacity of your continuous integration pipeline, using the Jenkins jclouds plugin to dymically create (and delete) instances on-demand to run build jobs will easily parallelize your builds.
