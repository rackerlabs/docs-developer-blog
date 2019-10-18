---
layout: post
title: Using pyrax to deploy the DevOps Blog
date: '2013-02-15 13:17'
comments: true
author: Justin Phelps
categories:
  - Cloud Files
  - Python
---
_This is a guest post written by Justin Phelps, a Rackspace Cloud support Racker. You can follow him on [LinkedIn](http://www.linkedin.com/in/linuturk), [@Linuturk](http://twitter.com/linuturk) on twitter, or find him on [Google+](https://plus.google.com/112828903529889228389/posts)_

Initially, when Hart [migrated to Octopress from WordPress](http://devops.rackspace.com/the-new-devops-blog.html) he was using Swiftly to push new posts to Cloud Files. Swiftly, a tool written by Cloud Files developer [Gregory Holt](https://github.com/gholt), provides a Client class and a command line tool for common Swift functions. Since Rackspace Cloud Files is based on Swift, it made a great tool to sync our working Octopress directory to a CDN-enabled Cloud Files container.
<!-- more -->
##Why Switch?

Swiftly was and still is great, but it uses version 1.0 of the API. We wanted to move to v2.0, and we wanted to use the [Official Rackspace SDKs](https://developer.rackspace.com). I decided to use the Python SDK, [pyrax](https://github.com/rackspace/pyrax), to deploy using the v2.0 API.

##Before and After
The Jenkins server still watches our GitHub repository for changes, only now uses a script I wrote that takes advantage of pyrax's container sync capability. Here are the Jenkins builds, before and after:

**Before**:

```
bundle install
rake install['classic']
rake generate
export SWIFTLY_AUTH_URL="https://auth.api.rackspacecloud.com/v1.0"
export SWIFTLY_AUTH_USER="USERNAME"
export SWIFTLY_AUTH_KEY="API_KEY"
swiftly put public -i public -d
```

**After**:
```
bundle install
rake install['classic']
rake generate
cf_sync
```

The `cf_sync` command is a script I wrote that uses the `pyrax` library. It was originally written to handle [my personal blog](http://www.onitato.com), but also works for the DevOps Blog, or any directory you need to sync with a container. You can download the script for container sync [here](https://github.com/Linuturk/www.onitato.com/blob/5dd41e1003a43db4ec6c0d6b651c55e227c58f4e/cf_pyrax.py).
