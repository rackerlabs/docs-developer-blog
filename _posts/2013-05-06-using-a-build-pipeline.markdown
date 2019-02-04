---
layout: post
title: Using A build pipeline
date: '2013-05-07 08:00'
comments: true
author: Hart Hoover
published: true
categories:
  - Jenkins
---
As [discussed previously](http://devops.rackspace.com/the-new-devops-blog.html),
this blog is hosted entirely in [Cloud Files](http://www.rackspace.com/cloud/files/).
It is powered by [Octopress](http://octopress.org), which means it is static -
perfect for hosting in an object store. Our "architecture" looks like this:

{% img center 2013-05-06-using-a-build/workflow.png 500 500 %}

Previously, deploying the blog was a one-and-done job. A single Jenkins job that
upon a push to GitHub, would install our Ruby gems, install the theme, generate
the site, and push the site to Cloud Files. This worked well, for a while. Then
Murphy got involved.

<!-- more -->

### If anything can go wrong...

Using a single Jenkins job to perform multiple tasks is not ideal. This is
especially true when you don't perform error checking in your scripts. Jenkins
isn't smart enough on it's own to know that step three of your five step process
was a failure and it should probably stop working.

Rake tasks would fail on the install of the theme, or installs of gems, or even
generating the site. Problems arose when Jenkins would sync those failures to our
public cloud files container. Since nothing would be there to sync, Jenkins would
sync nothing - taking the site down in the process and giving you the reader a
very bland 404 page. On top of that, I'd get an email from
[Cloud Monitoring](http://www.rackspace.com/cloud/monitoring/) plus a few more
from Rackers wondering if the site was down on purpose (Hint: it's never down
on purpose).

### That sounds... irresponsible.

Yes. It was horribly irresponsible... to leave it that way. Recently, I have
implemented a build pipeline using several plugins from Jenkins:

* [Build Pipeline Plugin](https://github.com/jenkinsci/build-pipeline-plugin):
   This plugin renders upstream and downstream connected jobs that typically
   form a build pipeline. In addition, it offers the ability to define manual
   triggers for jobs that require intervention prior to execution, e.g. an
   approval process outside of Jenkins.
* [Clone Workspace SCM Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Clone+Workspace+SCM+Plugin):
   This plugin makes it possible to archive the workspace from builds of one
   project and reuse them as the SCM source for another project.

Using these two together allows me to split each task into its own job. Now our
build pipeline looks like this:

{% img center 2013-05-06-using-a-build/devops_blog_buildpipe.png 700 700 %}

As you can see, some jobs are successful, some jobs fail, but NOTHING gets pushed
to Cloud Files without passing through each gate successfully. This also allows
me to run reporting at each step in parallel to the build task. Check out the
preceding plugins for your Jenkins jobs and **get more modular**.