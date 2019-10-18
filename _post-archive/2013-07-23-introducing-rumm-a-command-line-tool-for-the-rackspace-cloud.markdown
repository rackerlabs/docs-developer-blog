---
layout: post
title: 'Introducing rumm: a Command Line Tool for the Rackspace Cloud'
date: '2013-07-23 16:00'
comments: true
author: Damon Cali
published: true
categories:
  - DevOps
  - OpenStack
  - Cloud Servers
---

When building a non-trivial application, you will need to manage assets in the cloud. Servers, files, containers, load balancers, databases - setting these up and maintaining them is a part of your day-to-day work. You can use the Rackspace control panel to spin up a server. Or you can use the Rackspace API, and write a quick script to do what you need. Each of these tools has its ups and its downs, depending on your point of view and how you like to work.

As Ruby developers, we've become accustomed to doing a lot from the command line. In fact, there is so little that isn't done with a CLI (or editor), jumping over to the GUI of the control panel feels both jarring and limiting. So we decided to build [rumm](https://rackerlabs.github.io/rumm) - a command line tool for working with the Rackspace cloud.<!-- more -->

Rumm is at its core pretty simple. It's a ruby gem that you can install like any other. You can log in, create servers, attach volumes, and generally do the things you expect to be done. The commands are straight forward and predictable, based on the typical CRUD actions we know and love as well as a few specialty commands

```
rumm create server

rumm destroy server

rumm attach volume volume-name to server server-name
```
Each of the above commands does pertty much what it says. That in itself is a win. No more control panels!

But it gets better. 

```
rumm railsify server server-name
```

The `railsify server` command, for example, will install the full production Ruby on Rails stack to the specified server with a single command. Type it and grab some coffee. Now, we realize that this sort of functionality is not always going to be exactly what you need in exactly the way you need it. It's included as an example of what can be accomplished with rumm because of the way rumm was written.

Rumm is written in Ruby, and based on a new framework called [MVCLI](https://github.com/cowboyd/mvcli). As such, you'll be able to dig into the code and see a familiar MVC-style architecture with models, views, controllers, and routes. It feels very much like Rails in some ways, except that you wind up with a command line tool rather than a web app. But many of the concepts are the same. There is a middleware stack, a routes.rb file that maps commands to controllers, and models that contain business logic. You no longer have to awkwardly spew output with `puts` - MVCLI supports proper view templates.

There is currently in development a plugin system akin to a Rails engine - which means developers can create their own MVCLI plugins that extend rumm and distribute them as ruby gems. So if rumm's default `railsify server` doesn't do what you want, you can write your own version. You'll be able to add your own commands, or even extend existing commands with your own custom options.

Gone are the hastily written, brittle scripts that we have all had too much experience fighting with. Rumm and MVCLI provide a stable, familiar architecture that allows extensions to be developed, shared and maintained in a sane manner. You get all the command line luxuries for free: help, option parsing, input validation, and more.

Rumm is new - and currently under heavy development, but we're pretty excited about its potential. It's open source, and we'd love for you to step up and contribute. We think you'll find it to be a wide-open opportunity to really dig into some meanigful code. Contact us through the [Github page](https://github.com/rackerlabs/rumm) if you would like to help.
