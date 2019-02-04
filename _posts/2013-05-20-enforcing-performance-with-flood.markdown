---
layout: post
title: Enforcing performance with Flood
date: '2013-05-20 08:00'
comments: true
author: Ian Good
published: true
categories:
  - node.js
  - Jenkins
---

As we describe our release frequencies with "times per day" instead of "times
per year", clunky performance testing solutions that require interaction or
supervising no longer fit in the deployment pipeline. In [Email & Apps][1], our
latest and greatest code commits are hammered to their limits to enforce strict
standards of performance.

The basic idea starts with Jenkins pulling the latest performance testing
scripts from [GitHub][2] and submitting them to machines running [Flood][3], a
Node.js  tool written in-house. These jobs can do anything Node.js can do; a
typical use-case is sending requests to an HTTP endpoint. When the results come
back, Jenkins can decide whether to fail the build, produce graphs, or whatever
your desired behavior may be.

<!-- more -->

### Behind the scenes

The included `flood` utility is a daemon that resides on one or more machines
waiting for HTTP requests. The payload of these requests is a Javascript file,
digitally signed for security. The headers contain how long to run the job as
well as other relevant information.

The `flood` machines will utilize each CPU on the machine to maximize output,
and most jobs will want to take advantage of the event-driven nature of Node.js
to produce tens, hundreds, or thousands of simultaneous requests per CPU.

Each job registers a set of named counters that it can increment, such as
"successes" or "404". The granularity at which these counters are tracked
throughout the test lifetime is configurable per-job.

Another utility called `flood-watch` is useful, though not mandatory, for
initiating simultaneous requests to `flood` machines and aggregating the
results. It also takes care of producing and attaching a digital signature of
each job to prevent execution of arbitrary code on `flood` machines.

Obviously I've glazed over the specifics of setting up your own [Flood][3]
tests. The [Flood README][4] will have the latest info and steps on how to do
just that.

### Setting up Jenkins

Now for the real question, how do we build a Jenkins job that runs our test,
produces a graph of performance-over-time, and fails if conditions aren't met?

Easy! Set up a Jenkins job that checks out your performance test scripts. The
`flood-watch` utility uses its own config file, `config.json`, in which we want
to add some extra keys that define the parameters for failure and what to plot.
For example, if you had a counter called `"test"`, you could add this to your
`config.json`:

    "fail": [
        "test average < 100",
        "test minimum < 40"
    ],
    "warn": [
        "test average >= 200",
        "test average < 150",
        "test minimum < 75"
    ],
    "plot": {
        "Averages": "test average",
        "Minimums": "test minimum",
        "Maximums": "test maximum"
    }

Now we can configure our Jenkins "Build" action with the following script:

{% img 2013-05-06-enforcing-performance-with-flood/flood-configure.png %}

And we'd love to see plots with a data point for each build, so we can pinpoint
when performance started to improve or degrade. This is easy with the Jenkins
[Plot Plugin][5]:

{% img 2013-05-06-enforcing-performance-with-flood/flood-plot-settings.png %}

Remember, as with all performance testing, data is only useful when you can
compare it to something! Keeping your performance testing environment on
consistent hardware (or VMs) and using Chef (or similar) to make sure your app
stays up-to-date are crucial to producing useful output.

{% img 2013-05-06-enforcing-performance-with-flood/flood-plot-output.png %}

[1]: http://www.rackspace.com/email-hosting/
[2]: https://github.com/
[3]: https://github.com/icgood/flood
[4]: https://github.com/icgood/flood/blob/master/README.md
[5]: https://wiki.jenkins-ci.org/display/JENKINS/Plot+Plugin

