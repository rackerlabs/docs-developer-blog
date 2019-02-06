---
layout: post
title: 'Rackspace Deployment services: Blueprints to easily launch your apps'
date: '2013-06-25 13:00'
comments: true
author: Ziad Sawalha
published: true
categories:
  - General
---

Early last year, a project code-named Checkmate was created by Rackers to make
it easy for them to deploy complex cloud configurations, such as scalable
WordPress with Cloud Servers, Cloud Databases and a Cloud Load Balancer, with
one-click for our customers. The goal of the project was to provide a way for
Rackers to share and collaborate on these best practices using common
collaboration tools like GitHub.

Rackers across the company have a lot of experience running real-world applications
in the cloud. We wanted to take this knowledge and not only crowd-source that
information into best-practice "blueprints," but also expose that information
publically, enabling customers to easily deploy a configuration built on these
best practices. We knew that it would be a win-win: customers would have access
this expertise without having search for it on the web, and Rackers would get to
contribute their knowledge to a broader audience of customers.

Checkmate now powers a new feature we are exposing for preview in the Cloud
Control Panel today called Rackspace Deployment Services.

<!-- more -->

We're adding a "Create Deployment" button alongside Cloud Servers so customers
can launch multi-server solutions. We're also adding a "Deployments" tab to the
Cloud Control Panel so customers can view all of their deployments in real time.

Here are the blueprints that are ready for customers today:

* WordPress – Single Server and Multi-Server Options
* Drupal – Single Server and Multi-Server Options
* PHP - Single Server and Multi-Server Options

And some that we are working on:

* Ruby on Rails – Single Server and Multi-Server Options
* MySQL Master-Slave – Multi-Server Replication
* MongoDB
* Cassandra

We recognize that you, our customers, already have a lot of experience running
applications on our cloud and we'd like you to contribute to these blueprints
as well. We're looking for some early testers to launch these blueprints on
their cloud accounts to test them out. Do they have all the functionality you
expect? Do they meet your performance expectations? What other blueprints to do
you want to see (Apache Tomcat, Django, Node.js)? Etc... Your feedback will help
us make Rackspace Deployment services even more helpful to you.

For questions and to contact the team working on Checkmate find us on **freenode**
at #checkmate.

### Checkmate and OpenStack Heat

Rackspace is investing in and supporting the development of Heat; the
orchestration and configuration management service in OpenStack. Part of the
team working on Checkmate transitioned in June to work on Heat to get it to the
level of stability and capability that would allow us to eventually run the
deployments feature using Heat as the engine behind it. At the last OpenStack
Summit in Portland, we also proposed the Checkmate API and blueprint syntax as
the new open API for Heat and are working with the OpenStack community to
implement that. We believe the experience we have gained in developing and
running Checkmate will help us make valuable contributions to the development
of Heat's capabilities and API. Our intent is that the two projects will
converge in the future and we are putting resources behind making that happen.

