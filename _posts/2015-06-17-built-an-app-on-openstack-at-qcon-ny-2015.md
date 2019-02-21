---
layout: post
title: Built an app on OpenStack at QCon NY 2015
date: '2015-06-17 14:00'
comments: true
author: Everett Toews
published: true
categories:
  - openstack
  - database
---

<img class="blog-post right" src="{% asset_path 2015-06-17-built-an-app-on-openstack-at-qcon-ny-2015/qcon.png %}"/>Last week I went to [QCon NY](https://qconnewyork.com/) 2015 to be both a student and a teacher in their tutorial track. They follow the standard pattern of having 2 days of tutorials prior to the conference proper. To understand QCon a bit better, here's their mission statement.

"QCon empowers software development by facilitating the spread of knowledge and innovation in the developer community.

A practitioner-driven conference, QCon is designed for technical team leads, architects, engineering directors, and project managers who influence innovation in their teams."

<!-- more -->

### Modern container orchestration

<img class="blog-post right" src="{% asset_path 2015-06-17-built-an-app-on-openstack-at-qcon-ny-2015/kubernetes.png %}"/>On the first day I was a student. I took a full day tutorial called Modern Container Orchestration: Kubernetes, CoreOS and More by [Kelsey Hightower](https://twitter.com/kelseyhightower). Great tutorial and very intensive. We deployed Kubernetes "by hand" (using Terraform) on Google Compute Engine (GCE) in order to understand the bits and pieces better before we might use a hosted solution like Google Container Engine. Then we created some apps, ran them on our Kubernetes cluster, and implemented patterns like Canary and Rolling Updates.

[Abstract](https://qconnewyork.com/ny2015/tutorial/modern-container-orchestration-kubernetes-coreos-and-more) | [Slides](http://go-talks.appspot.com/github.com/kelseyhightower/intro-to-kubernetes-tutorial/slides/talk.slide#1) | [Code](https://github.com/kelseyhightower/intro-to-kubernetes-tutorial)

### Build an application on an OpenStack Cloud

<img class="blog-post right" src="{% asset_path 2015-06-17-built-an-app-on-openstack-at-qcon-ny-2015/openstack.png %}"/>On the second day I was a teacher. I gave a half day tutorial called Build an Application on an OpenStack Cloud tutorial. The cloud being used was the Rackspace Cloud powered by OpenStack. The goal was to give the participants the foundation of building and deploying an application on OpenStack and to give them the confidence to use tools of a higher level of abstraction in the future. It was a similar approach to what Kelsey did as we deployed the app "by hand" (using the OpenStack CLI) on Rackspace in order to understand the bits and pieces better before they might use a tool like Ansible or Heat to automate the deployment.

I had a pretty good idea of what the audience would be like and my guess was reasonably accurate. Of the 20 people, most were Java and .NET devs with a few Ruby and Node.js devs in the mix. There was only 1 Python developer. They had never touched OpenStack before, were looking to kick the tires, or had just gotten started with it. I put more emphasis on the architecture of the app and deploying it on OpenStack and less emphasis on the app itself. That turned out to be the right balance for this audience.

About 16-17 of the 20 signed up for the [Rackspace developer+](https://developer.rackspace.com/signup/) program right then and there to go through the tutorial. I made a point of mentioning how I had signed up for GCE and put in a credit card for the Kubernetes tutorial the day before. I think that helped demonstrate that signing up for cloud accounts is a regular part of taking a tutorial. The few people that didn't care to sign up got temp accounts and that worked out fine too. All in all we got very good feedback on the tutorial. The in room organizers are very serious about getting a completed survey from each participant and our organizer said it was the highest rated tutorial he'd seen in his 3 years.

Another great aspect of all of this was being able to include some of our awesome NY Rackers. We were joined by [Nikki Tirado](https://twitter.com/nikkitirado) and [Walter Bentley](https://twitter.com/djstayflypro) (unfortunately [John Yi](https://twitter.com/jyidiego) couldn't make it that day). In addition to helping [Dana Bauer](https://twitter.com/geography76) roam the room and help participants, Nikki did an amazing job of making sure all of the developer+ sign ups went totally smoothly with the Cloud Launch team and Walter spoke about Ansible towards the end of tutorial. I can't say enough good things about our NY Rackers. :)

[Abstract](https://qconnewyork.com/ny2015/tutorial/build-application-openstack-cloud) | [Slides](http://everett-toews.github.io/app-on-openstack/presentation/) | [Code](https://github.com/everett-toews/app-on-openstack)

### Conclusion

Please feel free to run through the tutorial yourself! As I mentioned, the emphasis was more on the deployment and less on the app. I look forward to improving (or replacing) the app in future versions of this tutorial. Feedback is always welcome.
