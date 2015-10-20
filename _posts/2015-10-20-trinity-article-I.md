---
layout: post
title: "Docker, Elastic Beanstalk and Git: a useful trinity for agile development?"
date: 2015-10-20 05:00
comments: true
author: Duncan Rutland
bio: Duncan Rutland is a Sr. Solution Architect at Rackspace within the Fanatical Support for AWS team.
published: true
categories:
- AWS
- Docker
- Git
- Elastic Beanstalk
authorIsRacker: true
---

## I - Introduction

This is the first of a multi-part series that demonstrates a pain-free solution a developer could use to transition code from laptop to production. The fictional deployment scenario depicted in this post is one method that can significantly reduce operational overhead on the developer. This series will make use of technologies such as Git, Docker, Elastic Beanstalk, and other standard tools.

<!-- more -->

In this first article, we will tackle some fundamental building blocks that will underpin a more realistic use-case in subsequent articles:

1. Environment setup
2. Elastic Beanstalk configuration
3. Manual environment deployment
4. Deploying a feature release to local container
5. Transitioning feature release to test Elastic Beanstalk environments

**Caveat**: The current version of this project imposes a deliberately simplified dummy application, release workflow (i.e. no automated tests) and environment layout (just local dev and test) in order to illustrate the key concepts behind running Git, Docker, and Elastic Beanstalk as an integrated unit. Later articles in this series will tackle a realistic use-case that contains an application with multiple components and incorporation into a CICD workflow.

**Disclaimer**: The demonstration code in the corresponding [repository] (https://github.com/djrut/trinity) is for illustrative purposes only and may not be sufficiently robust for production use. Users should carefully inspect sample code before running in a production environment. Use at your own risk.

**Disclosure**: The idea of a Makefile mechanism to automate container preparation, build, push etc. was inspired by [this](http://victorlin.me/posts/2014/11/26/running-docker-with-aws-elastic-beanstalk) excellent article by Victor Lin.

---

## II - Design Principles

The following fundamental design principles will be followed during the course of this adventure:

1. **Simplicity** - adhere to the principles of [KISS] (https://en.wikipedia.org/wiki/KISS_principle) and [Occam's Razor] (https://en.wikipedia.org/wiki/Occam's_razor)
2. **Agility** - switching between environments and deploying application releases should use only a single _simple_ shell command
3. **Immutability** -  consider container images as immutable. This eliminates dependency issues when deploying applications across environments. The local development runtime environment should thus be very close to production.
4. **Automation** - Nirvana is a fully automated deployment of application releases triggered by Git workflow events

**NOTE:** Strictly speaking the kernel and container supporting services _could_ differ between hosts; however, the impact on most applications would be minimal given that most dependencies exist within the runtime environment.

## III Prerequisites

This series of articles, and the corresponding demonstration code, has some dependencies on local environment and accounts with Docker, Github and AWS. You will need the following:

1. Ruby and Python interpreters
2. Unix "Make" utility
3. Elastic Beanstalk CLI tools (eb-cli)
4. Local Git binaries
5. AWS Account with default Public/Private/NAT VPC configured
6. AWS IAM user with appropriate policy set
5. Github account
6. DockerHub account
6. Local Docker host (e.g. via Docker Toolbox for OS X)

## IV - Demonstration

Rather than launch right into the details of how to set this up in your own environment, I decided to move that stuff to the Appendices at the end of this article and to dive straight into the demonstration. In order to replicate the demonstration, you need to first successfully install & configure the dependencies as described in Appendix A, and setup a local environment as per Appendix B.

### Setting the scene

Your latest application version is running in production, as a quick check with "eb status" confirms:

~~~bash
~/trinity/master> eb status

Environment details for: trinity-prod
  Application name: trinity
  Region: us-west-2
  Deployed Version: v1_1-1-g5bf2
  Environment ID: e-pi9ycc8gfs
  Platform: 64bit Amazon Linux 2015.03 v2.0.2 running Docker 1.7.1
  Tier: WebServer-Standard
  CNAME: trinity-prod-vw9hejjzuh.elasticbeanstalk.com
  Updated: 2015-09-28 01:14:36.798000+00:00
  Status: Ready
  Health: Green

~/trinity/master>
~~~

You decide to take a look in your browser, using the "eb open" command:

~~~bash
~/trinity/master> eb open
~~~

![Prod](https://s3-us-west-2.amazonaws.com/dirigible-images/trinity-prod.png)

### New "feature" request
---

It seems that some extra-terrestrial users (close acquaintances of HAL, I am led to believe) took offense at the rather limited scope of the greeting and made complaints to the customer service team. An issue was raised to this effect and assigned to you.

### Start work in feature branch
---

Eager to put this issue to bed, you create a feature branch and start work immediately:

~~~bash
~/trinity/master> git checkout -b issue-001 master
Switched to a new branch 'issue-001'
~~~

You make the necessary changes to app.rb and commit:

~~~bash
~/trinity/issue-001> git commit -a -m "Fixed #1 - Greeting message scope offensive to extra-terrestrials"
[issue-001 76f9252] Fixed #1 - Greeting message scope offensive to extra-terrestrials
 1 file changed, 1 insertion(+), 1 deletion(-)
~~~

### Create new application container
---

Since this is a Dockerized application, you can create a new container image and test this image locally before pushing to remote staging environment. You just need a simple "make" command to build the container and push to Docker hub:

~~~bash
~/trinity/issue-001> make
+
++ Building Git archive of HEAD at Docker/trinity.tar...
+
+
++ Performing build of Docker image djrut/trinity:v1.1-39-ge3b62fe...
+
Sending build context to Docker daemon  3.69 MB
Step 0 : FROM ruby:slim
 ---> c80da6b5b71b
Step 1 : MAINTAINER Duncan Rutland <duncan.rutland@gmail.com>
 ---> Using cache
 ---> 0d47bd3b0475
Step 2 : RUN mkdir -p /usr/src/app
 ---> Using cache
 ---> 04d15bc0ba0e
Step 3 : WORKDIR /usr/src/app
 ---> Using cache
 ---> 2d4736c6ab50
Step 4 : ADD trinity.tar /usr/src/app
 ---> 00915d05d730
Removing intermediate container f6f88d91ee75
Step 5 : RUN bundle install --deployment
 ---> Running in 5faed9595c09
[...SNIP...]

~/trinity/issue-001>
~~~



### Test new application container locally
---

Now that you have a new Docker image containing the recent commit, you decide to first perform a quick test on your local Docker host using the eb-cli tool "eb local run" command to spin-up the new container:

~~~bash
~/trinity/issue-001> eb local run
v1.1-39-ge3b62fe: Pulling from djrut/trinity
843e2bded498: Already exists
[...SNIP...]
3b8cf611759b: Already exists
Digest: sha256:c8c32d75e78a240130f4bc559d96d03e384623a127ab2dd17eeeea758e16c3b0
Status: Image is up to date for djrut/trinity:v1.1-39-ge3b62fe
Sending build context to Docker daemon 3.734 MB
Step 0 : FROM djrut/trinity:v1.1-39-ge3b62fe
 ---> 3b8cf611759b
Step 1 : EXPOSE 80
 ---> Running in 3e9cfa2be561
 ---> 532e52378fb9
Removing intermediate container 3e9cfa2be561
Successfully built 532e52378fb9
[2015-10-19 20:53:01] INFO  WEBrick 1.3.1
[2015-10-19 20:53:01] INFO  ruby 2.2.3 (2015-08-18) [x86_64-linux]
== Sinatra (v1.4.6) has taken the stage on 80 for development with backup from WEBrick
[2015-10-19 20:53:01] INFO  WEBrick::HTTPServer#start: pid=1 port=80
~~~

You open a browser window and connect to the Docker host IP and port that is running the new application version (in this case, http://192.168.99.100/):

![Local](https://s3-us-west-2.amazonaws.com/dirigible-images/trinity-local.png)

Success! The new greeting message is working as expected. The next step is to run the new container images in a true AWS test environment to see how this would work in production.

### Test new application container in test environment
---

A simple "eb create" command is all that is needed to bind this branch (using the --branch_default option) and spin-up this new version into a fresh staging environment in your accounts default VPC:

~~~bash
~/trinity/issue-001> eb create trinity-test-001 --branch_default
~~~

This time the "eb open" command can be run to fire up a browser window pointing to the test environment:

~~~bash
~/trinity/issue-001> eb open
~~~

...and voila! The new application image is running successfully in staging.

![Test](https://s3-us-west-2.amazonaws.com/dirigible-images/trinity-test.png)

**NOTE:** For longer running branches (such as those that wrap entire versions/milestones), this staging environment is persistent and only requires an "eb deploy" to push newer versions, after committing changes and running "make".

## V - Conclusion

During this demonstration, we examined a simplified use-case that enabled an easy-to-use and agile deployment mechanism with immutable application containers. The developer used three simple shell commands ("git commit", "make", and "eb deploy") to build a new immutable container and to push to the appropriate environment. This approach dramatically reduced the likelihood of broken dependencies as application releases are progressed from developer laptop onto to staging and production.

In **Part II** of this series this series, we take a peek under the covers to examine how we integrated Docker, Elastic Beanstalk and Git to enable the simple example above.

In **Part III**, we bring this closer to a real production scenario by adding some additional components (and external dependencies) to the application and introduce unit tests.

In **Part IV**, we show how this application can integrate into a fully automated CI/CD workflow.

Thank-you for your time and attention!

---

## Appendix A - Dependencies

The following section outlines the steps needed to setup a local environment on Max OS X.

### Install Homebrew
~~~bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
~~~
### Install Python
~~~bash
sudo brew install python
~~~
### Install eb-cli
~~~bash
sudo pip install eb-cli
~~~

### Install Docker Toolbox
Follow the instructions [here] (https://docs.docker.com/installation/mac/) to install and configure Docker host running in a VirtualBox VM on OS X.

NOTE: _I had issues with connectivity to the host starting after initial install (I was getting "no route to host"). After some troubleshooting, this was remedied by a restart of OS X. It is not necessary, as some older issues relating to this problem indicate, to create manual NAT table entries_

### Setup Git

Most modern Unix variants have the Git package already installed. Follow the instructions [here] (https://help.github.com/articles/set-up-git/) to setup Git. There are some useful instructions [here] (https://help.github.com/articles/caching-your-github-password-in-git/) to setup credential caching to avoid having to frequently re-type your credentials.

### Configure AWS credentials

I prefer to populate the .aws/credentials file as follows:

~~~bash
[default]
aws_access_key_id = [ACCESS KEY]
aws_secret_access_key =  [SECRET]
~~~

You need either an IAM role assigned to this user or a containing group that assigned to this user or containing group that has adequate permissions to IAM, EB, EC2, S3 etc... Since this is my playground account, I used a wide open admin policy:

~~~
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
~~~

Caveat: This IAM policy is **not** recommended for production use, which should utilize a fine-grained IAM policy.

## Appendix B - Environment Setup

There are number steps involved here to get the environment setup, but remember that these are _one time_ actions that you will not need to repeat again unless you need to recreate the environment from scratch.

### Step 1 - Choose a name for your application
You need to create a unique name for your forked version of the trinity application, because Elastic Beanstalk DNS CNAME records must be globally unique. We shall refer to this name as *APP_NAME* henceforth.

### Step 2 - Fork & clone Git repository
The first step is to fork and clone the demo Git repository. Full details on how do to this can be found [here](https://help.github.com/articles/fork-a-repo/) however the basic steps are:

1. On GitHub, navigate to the [djrut/trinity](https://github.com/djrut/trinity) repository
2. In the top-right corner of the page, click **Fork**. You now have a fork of the demo repository in your Github account.
3. Create local clone, substituting your Github USERNAME

~~~bash
git clone https://github.com/[USER_NAME]/trinity.git
~~~
 4. Create upstream repository to allow sync with original project

~~~bash
git remote add upstream https://github.com/djrut/trinity.git
~~~

### Step 2 - Docker Hub setup


1. Create a Docker Hub account and create a repository for *APP_NAME*
2. Edit "Makefile"
2. Substitute USER value (currently set to "djrut") with your Docker Hub username.
3. Substitute REPO value (currently set to "trinity") with your newly created *APP_NAME*
4. Login to Docker hub (this will permanently store your Docker Hub credentials in ~/.docker/config.json)

~~~ bash
docker login
~~~

### Step 3 - Initialize Elastic Beanstalk environments

NOTE: This step requires either that you have a default VPC configured with public/private NAT configuration _or_ that you explicitly specify the VPC and subnet IDs during Elastic Beanstalk environment configuration step. I use the latter mechanism to supply a previously saved configuration to the "eb create" command.

#### a) Initialize the Elastic Beanstalk Application

~~~bash
eb init [APP_NAME] --region us-west-2 --platform "Docker 1.7.1"
~~~

If this succeeds, you should see a message like "Application [APP_NAME] has been created."

#### b) Create "production" Elastic Beanstalk environment

Ensure that you are currently in the up-to-date "master" branch of the application:

~~~bash
prompt> git status
On branch master
Your branch is up-to-date with 'origin/master'.
nothing to commit, working directory clean
~~~

Run the "eb create", substituting *APP_NAME* for your application name:

~~~bash
eb create [APP_NAME]-prod --branch_default
~~~

You should now see a trail of events as Elastic Beanstalk launches the environment. Here is a snippet from mine:

~~~bash
Creating application version archive "v1_1".
Uploading trinity/v1_1.zip to S3. This may take a while.
Upload Complete.
Environment details for: trinity-prod
  Application name: trinity
  Region: us-west-2
  Deployed Version: v1_1
  Environment ID: e-pi9ycc8gfs
  Platform: 64bit Amazon Linux 2015.03 v2.0.2 running Docker 1.7.1
  Tier: WebServer-Standard
  CNAME: UNKNOWN
  Updated: 2015-09-27 19:24:42.760000+00:00
Printing Status:
INFO: createEnvironment is starting.
INFO: Using elasticbeanstalk-us-west-2-852112010953 as Amazon S3 storage bucket for environment data.
INFO: Created security group named: sg-d47aebb0
INFO: Created load balancer named: awseb-e-p-AWSEBLoa-XUW9PIDWF5JH
INFO: Created security group named: sg-d27aebb6
INFO: Created Auto Scaling launch configuration named: awseb-e-pi9ycc8gfs-stack-AWSEBAutoScalingLaunchConfiguration-1SUHKGKXB0C01
INFO: Environment health has transitioned to Pending. There are no instances.
INFO: Added instance [i-7b176ca0] to your environment.
INFO: Waiting for EC2 instances to launch. This may take a few minutes.
~~~

At this stage, you can safely CTRL-C and wait a few minutes for the environment to be spun up. This takes longer for the first deployment, since the full Docker image needs to be downloaded. Subsequent deployments of newer versions of the application be faster, since only the modified layers of the image need to be downloaded.

You can check periodically with "eb status" and wait for "Health: Green" to indicate that all is well:

~~~bash
prompt> eb status
Environment details for: trinity-prod
  Application name: trinity
  Region: us-west-2
  Deployed Version: v1_1
  Environment ID: e-pi9ycc8gfs
  Platform: 64bit Amazon Linux 2015.03 v2.0.2 running Docker 1.7.1
  Tier: WebServer-Standard
  CNAME: trinity-prod-vw9hejjzuh.elasticbeanstalk.com
  Updated: 2015-09-27 19:32:43.591000+00:00
  Status: Ready
  Health: Green
~~~

Finally, there is a handy command "eb open" that opens the current environment in your browser for a quick eye test:

~~~bash
eb open
~~~
