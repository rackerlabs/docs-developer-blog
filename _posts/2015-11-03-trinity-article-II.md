---
layout: post
title: 'Docker, Elastic Beanstalk and Git: a useful trinity for agile development? Part II'
date: '2015-11-03 00:00'
comments: true
author: Duncan Rutland
bio: Duncan Rutland is a Sr. Solution Architect at Rackspace within the Fanatical Support for AWS team.
published: true
categories:
  - Docker
  - aws
authorIsRacker: true
---

### I - Introduction

In [Part I](https://developer.rackspace.com/blog/trinity-article-I/) of this series, we depicted a fictional scenario for agile development using a simple "Hello World" application composed of just a single UI layer. During this fanciful (albeit contrived) exposition, we glossed over many of the underlying details for the sake of brevity. In this article, we will take a little peek under the covers and explain in more depth how we achieved rapid, automated deployments of immutable application containers to remote test environments.

<!-- more -->

**Disclaimer**: The demonstration code in the corresponding [repository] (https://github.com/djrut/trinity) is for illustrative purposes only and may not be sufficiently robust for production use. Users should carefully inspect sample code before running in a production environment. Use at your own risk.

**Disclosure**: The idea of a Makefile mechanism to automate container preparation, build, push etc. was inspired by [this](http://victorlin.me/posts/2014/11/26/running-docker-with-aws-elastic-beanstalk) excellent article by Victor Lin.

### II - Workflow

We will begin by outlining the workflow when working with Docker, EB, and Git in this scenario. The high-level steps are as follows:

1. Initial Git Steps
	- Pull from remote repository
	- Create feature/bug-fix branch
2. Create Elastic Beanstalk Environment
	- Create new Elastic Beanstalk test
	- Bind to branch
	- Test initial deployment
3. Feature/bugfix Development
	- Write code for new feature or bug-fix
	- Commit changes to feature/bug-fix branch
4. Docker container build
	- Build new Docker image
	- Push to remote repository
5. Deploy to test EB Environment

Let us now delve deeper into the inner-workings within each of these steps.

### III - Initial Git steps

The first two steps involve pulling (or cloning if a fresh start is required) the repository and creating a feature/bug-fix branch. Pretty straightforward stuff, there are no surprises here so no need to expand further, _although_ I would like to take this opportunity to describe some of the Git-specific configuration required.

#### Git Configuration: .gitignore

~~~bash
*.swp
.bundle
Docker/*.tar
.DS_Store

# Elastic Beanstalk Files
.elasticbeanstalk/*
!.elasticbeanstalk/*.cfg.yml
!.elasticbeanstalk/*.global.yml
~~~

The pertinent line here is `Docker/*.tar` which instructs Git to ignore any tar balls, which were created by `git archive` to be included in the Docker image in later steps, and _not_ to ignore the entire `Docker/` directory, which contains configuration state in the form of one (or more) Dockerfile(s) that we would like to manage under revision control.

**NOTE:** Additional configuration state contained in `.ebextensions/` directory will *not* be ignored since it resides at root of project.

#### Git Configuration: .gitattributes

Some special merge behavior is required for a single file in the project: `Dockerrun.aws.json`. This file contains the configuration that Elastic Beanstalk uses to deploy containers and branch-specific state (namely a pointer to specific Docker image for each environment).

~~~
Dockerrun.aws.json merge=ours
~~~

The raison d'etre of this little morsel of configuration is to prevent merge conflicts when we, for example, perform a `git merge master` inside our feature/big branch, which (as good CI citizens) we should be doing frequently to remain in sync with the mainline/trunk. Since each branch will have it's own version of `Dockerrun.aws.json`, we want any merge of master to retain the local branch version.

**NOTE:** This configuration needs to be inserted into the project's `.git/config` file using the following command:

~~~bash
git config merge.ours.driver true
~~~

### IV - Create Elastic Beanstalk Environment

If this is a newly created branch, we will need to instruct Elastic Beanstalk to build a new environment and bind it to the branch.

This is easily done using the `eb create [REPOSITORY]-[BRANCH] --branch_default` command as shown here:

~~~bash
eb create trinity-bug-002 --branch_default
~~~

This command kicks-off the `createEnvironment` workflow inside Elastic Beanstalk Service that:

- Creates an initial application archive and uploads to S3
- Points the env config to S3
- Creates security groups
- Creates auto-scale groups and EC2 instances
- Creates CloudWatch alarms
- Pulls Docker images from remote repository onto the EC2 instances
- Launches containers

Verify that the environment launch was successful by checking the Status and Health indicators using the `eb status` command:

~~~bash
prompt> ~/trinity/bug-002: eb status
Environment details for: trinity-bug-002
  Application name: trinity
  Region: us-west-2
  Deployed Version: v1_1-15-gc685
  Environment ID: e-psxs3vh7t2
  Platform: 64bit Amazon Linux 2015.03 v2.0.2 running Docker 1.7.1
  Tier: WebServer-Standard
  CNAME: trinity-bug-002-rbp4qmz5i4.elasticbeanstalk.com
  Updated: 2015-10-15 01:34:05.054000+00:00
  Status: Ready
  Health: Green
~~~

Green is good! Note that this configuration is persisted in the `branch-defaults:` section of the `.elasticbeanstalk/config.yml` located in the project root. Here is an example:

~~~bash
branch-defaults:
  bug-002:
    environment: trinity-bug-002
  issue-001:
    environment: trinity-test-001
  master:
    environment: trinity-prod
global:
  application_name: trinity
  default_ec2_keyname: null
  default_platform: Docker 1.7.1
  default_region: us-west-2
  profile: eb-cli
  sc: git
~~~

### V - Feature/Bugfix Development

We will not go into much detail here. Suffice to say that development of _some_ feature of bug fix takes places. The important thing to note is that a commit of the changes **MUST** take place before proceeding to create the new Docker image, since, as we shall see, the make process uses `git archive` to roll-up the application for inclusion in the image.

### VI - Docker container build

Now we get to the meat of the process. In [Part I](https://developer.rackspace.com/blog/trinity-article-I/) of this series, we showed how two simple commands `make` and `eb deploy` were all that was required to create a brand new immutable Docker image and deploy to an external Elastic Beanstalk Environment. Let's now delve into the `make` component.

Those that are familiar with C/C++ development in Unix/Linux will be familiar with the [make](https://www.gnu.org/software/make/) utility. As originally conceived in the 1970s, `make` was intended to standardize and simplify the process of compiling and linking large C projects with lots of interdependencies. Due to it's venerable status and tenure, the make utility is present by default in most Unix/Linux distributions.

HOWEVER: for our purposes, it can also be used to provide a simple way to group shell commands and enforce a (very basic) workflow. This turns out to very handy when working with container builds a things can (and do) fail from time-to-time.

Most of the magic happens in the [Makefile](https://www.gnu.org/software/make/manual/html_node/Makefiles.html), a simple text configuration file that resides in the project root. Here is the `Makefile` we used in this scenario:

~~~
USER		:= "djrut"
REPO		:= "trinity"
BUILDDIR	:= "Docker"
VERSION		:= $(shell git describe --tags)
IMAGE		:= $(USER)/$(REPO):$(VERSION)

.PHONY: all prep build push commit clean

all:	| prep build push commit clean

prep:
	@echo "+\n++\n+++ Building Git archive..."
	@git archive -o $(BUILDDIR)/$(REPO).tar HEAD

build:
	@echo "+\n++\n+++ Performing build of Docker image..."
	@docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)

push:
	@echo "+\n++\n+++ Pushing image to Dockerhub..."
	@docker push $(IMAGE)

commit:
	@echo "+\n++\n+++ Committing updated Dockerrun.aws.json..."
	@Docker/build_dockerrun.sh > Dockerrun.aws.json
	@git add Dockerrun.aws.json
	@git commit --amend --no-edit

clean:
	@echo "+\n++\n+++ Cleaning-up... "
	@rm -v $(BUILDDIR)/$(REPO).tar
~~~


Let's break this down section by section. First up: Variable definitions.

#### Makefile Variable Definitions

~~~
USER        := "djrut"
REPO        := "trinity"
BUILDDIR    := "Docker"
VERSION     := $(shell git describe --tags)
IMAGE       := $(USER)/$(REPO):$(VERSION)
~~~

We set variables for use throughout the `Makefile` in the first block. This is familiar syntax, but one thing to note is the `:=` operator, which implies "[simple](https://www.gnu.org/software/make/manual/html_node/Setting.html#Setting)" variable expansion. In this case, the left-hand operand (e.g. VERSION) is immediately set to the expanded result of the right-hand operand. This is in contrast with the recursive expansion `=` operator, where the value of the left-hand operand is not set until the time of reference.

- **USER:** This is the name of Git/DockerHub username, which in our case are identical
- **REPO:** The name of the Git and Dockerhub repository, again these are identical
- **BUILDDIR:** This identifies the directory path under project root that will contain the Dockerfile used to build the image and also where the Git archive is dumped.
	- **NOTE:** For this scenario, it is necessary for a Dockerfile **not** to reside in project root otherwise EB create/deploy will build a fresh image each time using _that_ `Dockerfile` instead of simply referencing an existing image defined in the `Dockerrun.aws.json` configuration file (see below).
- **VERSION:** This variable contains the version tag to apply to the Docker image. In this case, we use the builtin `shell` command to run `git describe --tags`. This ensures that we have a consistent mapping between a version of the application in Git, Docker, and ElasticBeanstalk. NOTE: Alternative naming strategies are possible also, including using the branch name.
- **IMAGE:** This is a simple concatenation of USER, REPO and VERSION.

Now, let's dig into the individual targets within the `Makefile`.

#### Makefile Rule Syntax

Makefiles are composed of one or more "rules", which follow this basic syntax:

~~~
targets : prerequisites
	recipe
~~~

It is instructive to now show an example `Makefile` from a C project (the "edit" binary), to illustrate how make was _originally_ intended to be used:

~~~
edit : main.o kbd.o command.o display.o \
       insert.o search.o files.o utils.o
        cc -o edit main.o kbd.o command.o display.o \
                   insert.o search.o files.o utils.o

main.o : main.c defs.h
        cc -c main.c
kbd.o : kbd.c defs.h command.h
        cc -c kbd.c
command.o : command.c defs.h command.h
        cc -c command.c
display.o : display.c defs.h buffer.h
        cc -c display.c
insert.o : insert.c defs.h buffer.h
        cc -c insert.c
search.o : search.c defs.h buffer.h
        cc -c search.c
files.o : files.c defs.h buffer.h command.h
        cc -c files.c
utils.o : utils.c defs.h
        cc -c utils.c
clean :
        rm edit main.o kbd.o command.o display.o \
           insert.o search.o files.o utils.o
~~~

This Makefile depicts a C project "edit", which is composed of a number of modules. There is a **target** defined for each module (e.g. search.o), certain **pre-requisite** files (for example .c source file and .h header files), and a **recipe**, which invokes the C compiler to compile each module (with linking disabled). The target for "edit" effectively links all these modules into a single binary.

As you can see, our use of make deviates from this original purpose but takes advantage of the tool to enforce a simple workflow of shell commands.

#### Makefile Target: .PHONY

~~~
.PHONY: all prep build push commit clean
~~~

This first curious target is a built-in make convention that is used to define targets that do not _actually_ represent files. Since we are using targets to represent **labels in a workflow**, and they do not get compiled, we should define all of the targets in the `Makefile` as "[.PHONY](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html)". This prevents problems in the (remote, but not impossible) event that a file with the same name as one of the targets is created. If this were to occur, make would never run that recipe, thinking that the target had already been built.

#### Makefile Target: all

~~~
all:	prep dry-run build push commit clean
~~~

In this example `all` is the default "target" that is built when the `make` utility is invoked without any arguments. This results in the recipes for each of the prerequisites being invoked from left to right (so `prep` runs first, followed by `dry-run` and so on). This allows us to create a simple workflow that follows a chain of dependent actions and halts upon error.

#### Makefile Target: prep

~~~
prep:
    @echo "+\n++\n+++ Building Git archive..."
    @git archive -o $(BUILDDIR)/$(REPO).tar HEAD
~~~

The first step of the workflow is to create a consistent snapshot of the application artifacts for inclusion in the Docker image. Git provides a nice way of doing this using the [git archive](https://git-scm.com/docs/git-archive) command. Here we tell Git to dump the archive in our `Docker/` directory using `-o` option, and we tell Git to use the snapshot that `HEAD` currently points to (e.g. the last commit of our current working branch). This mechanism, as opposed to the ordinary `tar` command, ensures that we do unintentionally corrupt the build with contents from a dirty working directory.

**NOTE:** The `@` sign is another make convention that prevents the command itself being echoed to STDOUT. I elected to do this to reduce visual clutter.

#### Makefile Target: build

~~~
build:
	@echo "+\n++\n+++ Performing build of Docker image..."
	@docker build -t $(IMAGE) --force-rm $(BUILDDIR)
~~~

As the name suggests, this is where we invoke the docker build command. Nothing outside of the ordinary here: we pass `-t` to specify a repository/name:tag for the image and always remove intermediate containers (`--force-rm`) after a build, whether it is successful or not. Note that this option does not affect the layer cache used for image build.

#### Makefile Target: push

~~~
push:
	@echo "+\n++\n+++ Pushing image to Dockerhub..."
	@docker push $(IMAGE)
~~~

Assuming the build was successful, we now push the newly created image to Dockerhub. This makes the image available to Elastic Beanstalk. I'm using a public repository for this example, but private repos are also supported by Elastic Beanstalk.

**HINT:** To prevent being prompted for Dockerhub credentials every time, I would suggest running `docker login` to create a persistent authorization token in `~/.docker/config.json`

**NOTE:** Coming later this year, the AWS EC2 Container Registry (ECR) will enable developers to store container images within a scalable, secure and performant registry, which is hosted on AWS and integrates with IAM, ECS and other AWS services.

#### Makefile Target: commit

~~~
commit:
	@echo "+\n++\n+++ Committing updated Dockerrun.aws.json..."
	@Docker/build_dockerrun.sh > Dockerrun.aws.json
	@git add Dockerrun.aws.json
	@git commit --amend --no-edit
~~~

After a successful push, we can safely update the Docker configuration file that ElasticBeanstalk uses. In the single-container example for this article, this file is called [Dockerrun.aws.json](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker_image.html). Here is what ours looks like:

~~~
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "djrut/trinity:v1.1-20-g6b54b6e",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "80"
    }
  ],
  "Logging": "/var/log/"
}
~~~

The AWS docs [here](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker_image.html) give a full description of this configuration, which I will not duplicate here; however, some things to note are:

- `"AWSEBDockerrunVersion": "1"` -> Version for single container deployments. Multi-container deployments will use a different format in Version 2.
- `"Name": "djrut/trinity:v1.1-20-g6b54b6e"` -> This is our container name!
- `"ContainerPort": "80"` -> Which port to EXPOSE from the container, for use by the EB reverse proxy service running on the container host.

So... how did our container name get inserted into `Dockerrun.aws.json`? A quick'n'dirty shell script named `build_dockerrun.sh`. Here is the relevant target from the `Makefile` again:

~~~
commit:
	@echo "+\n++\n+++ Committing updated Dockerrun.aws.json..."
	@Docker/build_dockerrun.sh > Dockerrun.aws.json
	...
~~~

The script `Docker/build_dockerrun.sh` is run, and the output is redirected to the `Dockerrun.aws.json` file.

The script itself is nothing special:

~~~bash
#!/usr/bin/env bash
USER="djrut"
REPO="trinity"
VERSION=$(git describe --tags)

cat << EOF
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "$USER/$REPO:$VERSION",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "80"
    }
  ],
  "Logging": "/var/log/"
}
EOF
~~~

This script simply injects the correct image path into a `Dockerrun.aws.json` template and spits out to STDOUT.

The following two lines in the `commit` target actually execute the commit:

~~~
	@git add Dockerrun.aws.json
	@git commit --amend --no-edit
~~~

We stage only the `Dockerrun.aws.json` file, since there may be other changes in the working directory that we do not want to stage.

**NOTE:** The `--amend` and `--no-edit` options allow the previous (probably more meaningful) commit message to be retained *and* result in the minor version number of the tag also being retained, instead of being incremented as with a normal commit. This behavior is desirable, since we want strict correlation between git branch tag, docker image tag, and the Elastic Beanstalk application version.

#### Makefile Target: clean

~~~
clean:
	@echo "+\n++\n+++ Cleaning-up... "
	@rm -v $(BUILDDIR)/$(REPO).tar
~~~

Finally, we do some housekeeping and remove the Git archive tar file created during the `prep` stage.

This step concludes the tasks performed by the make workflow, and we should now have a freshly built immutable Docker image that encapsulates the latest feature/bug-fix committed in the local branch available remotely for use by Elastic Beanstalk (or any other system).

### VII - Deploy to test EB environment

The final step in this example is to deploy the new application version to a test environment. This turns out to be very simple (and fast) with the help of the Elastic Beanstalk `eb deploy` command.

~~~
~/trinity/issue-001 > eb deploy
Creating application version archive "v1_1-39-ge3b6".
Uploading trinity/v1_1-39-ge3b6.zip to S3. This may take a while.
Upload Complete.
INFO: Environment update is starting.
~~~

This command pushes the new `Dockerrun.aws.json` out to our Elastic Beanstalk environment and signals the host manager on each EC2 instance to perform an update of the running container. A quick check of `eb status` or `eb health` will show that the new deploy was successful and took around 20 seconds.

**NOTE:** In practice, this step could also be automated for feature/bug branches within the Makefile using a `deploy` step that follows a successful `push`. We could even take this a step further and implement a Git commit hook to trigger the make automatically, resulting in a fresh container build and updated remote test environment with nothing more than a `git commit`.

### VIII - Conclusion

In this article, we probed a little deeper into the internals of the simple scenario outlined in [Part I](https://developer.rackspace.com/blog/trinity-article-I/). This was hopefully a useful demonstration of _one possible scenario_ depicting how using EB, Docker, and Git together can drastically simplify the development process and reduce the risk of broken dependencies between environments.