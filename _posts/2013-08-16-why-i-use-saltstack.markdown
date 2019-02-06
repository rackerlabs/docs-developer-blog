---
layout: post
title: Why I use SaltStack
date: '2013-08-16 08:00'
comments: true
author: Allen Oster
published: true
categories:
  - General
---

{% img right 2013-07-12-join-the-great-salt-sprint/saltstack_logo.jpg 200 %}

I am part of a team (along with Bruce Stringer and Jason Swindle) working on an
internal application called Graffiti, which provides an easy way for front-line
Rackers to record interactions with customers and provide valuable data with
each interaction. It also creates a much simpler way for leads to be passed
from the front line to the IB sales team here in SMB cloud.

We knew from the start that we wanted this to be an agile cloud application that
utilizes all the things a cloud should be. We had some limitations which meant
we had to home grow a few solutions. Since this is an internal application, we
could not rely on third-party solutions for off loading workloads. We also had
to be careful with our security practices, of course. We ended up going with a
configuration that utilizes our internal nova solution for hosting in Cloud
Servers. The downside to this is that we have no automated backups, no load
balancers and no Cloud Files - much to my dismay.

<!-- more -->

The configuration we are building out consists of an Nginx load balancer, two
web servers running Nginx and a master-master pair of PostgreSQL database servers
using pgbouncer for replication. We also utilize a Redis server for some caching
and as a sort of rate limiting feature for our API.

### So, why SaltStack?

We use SaltStack for many reasons, but the most important are ease of
configuration style, open source (no "pay for the pro features;" it’s all free),
and a vibrant developer community that has been easy to reach and quick to patch
any bugs we found.

We use SaltStack in combination with saltcloud to automagically deploy our
infrastructure. We have a single server setup as a Salt Master, with saltcloud
configured on it. We configured the states that each server should be in and
what each server’s roles should be. With saltcloud, all we have to do is
configure a map file that shows what servers should be online and anything else
specific about the servers that we need them to have. Here is an example of a
map file for saltcloud:

```
openstack_2GB:
  - stag­redis­n001­graffiti:
    grains:
      env: stag
      newrelic_env: staging
      datacenter: dfw
      node_type: redis
```

That example would tell saltcloud that there should be a 2GB server,
**stagredisn001graffiti**, with the listed salt "grains" configured. With
saltcloud all new servers will get kicked with the Salt minion agent already
installed and configured to talk to the Salt Master.

If we keep adding servers to that map file, we can have a map of how our entire
infrastructure should look, and when we need another node spun up we just add it
to that file and run saltcloud again.

### The power of grains

Another reason we use SaltStack is that it is incredibly powerful for how simple
the configuration can be. We use grains heavily because we need nodes to be able
to configure their services based on the way other nodes are configured. For
example, we need our load balancer to automatically fetch the IP of any web
server and add that IP to its pool. We accomplish this with grains.

When a new server comes online we set four main grains:

```
env
newrelic_env
datacenter
node_type
```

With these grains set, the load balancer is configured through SaltStack to look
for any servers with the web server node_type and that has the SAME env type.
This means that we can spin up dev, staging and production servers without having
to specifically tell the correct load balancer to add or remove that node. If a
new staging node comes online only the other staging nodes look for it and add
it to their configuration. That means we can redeploy all three of our environments
from nothing to fully functional in minutes. We also have SaltStack configured
to load everything from our GitHub repository using release tags, so it is easy
to push new changes as well. With this type of setup, any and all changes can be
version controlled through git and properly QC'd before running a simple command
from the master servers and bringing all of our environments up to date.

That's the power of a DevOps mentality and the power of properly using version
control with infrastructure automation. SaltStack for the win!


### About the author

Allen Oster is a DevOps Engineer at Rackspace. You can put him in a circle
[on Google+][3] or follow him on twitter [@OsterCloud][4].


[3]: https://plus.google.com/116303852061385832110/
[4]: https://twitter.com/OsterCloud
