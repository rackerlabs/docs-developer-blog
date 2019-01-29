---
layout: post
title: "A Simple AWS-based CICD for In-Development Terraform Providers"
ogTitle: "A Simple AWS-based CICD for In-Development Terraform Providers"
metaDescription: A simple AWS-based CICD that anyone can use to build a non-mainline Terraform Provider.
ogDescription: A simple AWS-based CICD that anyone can use to build a non-mainline Terraform Provider.
date: 2019-01-29 00:00
comments: true
author: Matthew Bonig
twitterCreator: "@mattbonig"
published: false
authorIsRacker: true
authorAvatar: https://s.gravatar.com/avatar/17fefeb3c1832175bf6fbe9841368292?s=128
bio: "As a Senior Software Engineer at Rackspace, Matthew draws upon his 15 years of web application development experience to help architect highly-available, fault-tolerant, scalable, and secure AWS environments composed of a wide range of services in the AWS portfolio, including Compute, Storage, Database, Networking, Developer Tools, and more. He is an AWS certified Solutions Architect. His hobbies include hiking the foothills of Colorado and walks with his wife and dogs."
categories:
  - aws
  - Developers
---

Terraform has gained a lot of popularity in the last couple years. Rackspace has standardized on it for many internal and client-facing operations to quickly spin up new architecture in AWS and Azure alike. However, with Amazon's lightning fast deployment of new features, it's become harder for the Providers to keep up. Developers are left waiting for new features to be developed and merged into the `master` branch before becoming available for general consumption.

Open Source to the rescue! Since the source for Terraform Providers are available via Github any new feature doesn't have to be in the mainline Provider before it can be leveraged by Terraform users.

This post will discuss a simple Terraform module that was developed to allow anyone to easily clone, build, and install a fork or branch of a Terraform Provider without having to setup a GOLANG build environment. 

## The Need

Currently (Jan 2019) there are over 1000 open issues with the [Terraform AWS Provider](). That's a lot of issues... and while Hashicorp works to make Terraform "2" available, it feels that some of this development work to get new features and bug fixes merged into `master` has slowed down. Thankfully the robust community has, in many cases, developed solutions and submitted PRs. Currently (Jan 2019) there are XXX outstanding PRs. That's a lot of PRs... 

Let's take a look at one specific issue, the [Amazon FSx Feature](). FSx was recently announced (Dec 2019) and is a drop-in replacement for Windows File Shares. Rackspace would like to make this available to our customers ASAP. However, we also prefer to use Terraform for all our infrastructure deployments. With this PR unmerged, we'd need to either fallback to CLI commands, or CloudFormation (which at the time of this writing is still not an option as even AWS has not released the CloudFormation changes required to support FSx), or manage this through the Console. None of these options are good long term.

However, since a nice user in the community created a PR, we can review that and decide if we want to use that code instead.

## The Problem

This is where the problem starts... All Terraform Providers are written in GOLANG, so cloning that fork, building, and deploying that to our environments to use instead of the mainline `terraform-provider-aws`, is not trivial.

Let's assume you've done GOLANG development before, then you pull the code, build it, run tests, then copy the resulting file to your `~/.terraform.d/plugins` directory, no problem.

Bit, if you're like me and had never done GOLANG, are you willing to spend the time to get things setup properly? Here's a tip that took me a couple of hours to figure out: GOLANG cares about your directory structure!

Either way, at the end I felt things could be easier.
  
## The Solution

So, here is a Terraform Module, Open Source and available on Github, that you can use to setup a CICD pipeline using CodePipeline and CodeBuild to build and deploy any fork or branch of a Terraform Provider to an S3 bucket for consumption. Here's how it works:

1. Execute the TF Module, providing the Github owner, repository, and branch to build, along with a couple of additional parameters.
2. CodePipeline pulls source from Github.
3. CodeBuild builds that source into a `darin_amd64` and `linux_amd64` binaries.
4. CodePipeline copies those two binaries to an S3 bucket for consumption.
5. Any user who wants to use this provider just copies the resulting binary to their own machine. (This is the only manual step)
 
Please review the README and feel free to open any issues or provide feedback.

## Conclusion

Using non-mainline Terraform Providers, built from a forked Github repository, is now simple ane easy with a little AWS and Terraform.
