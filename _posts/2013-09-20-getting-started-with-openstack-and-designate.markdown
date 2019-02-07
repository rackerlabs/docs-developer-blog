---
layout: post
title: Getting started with OpenStack and Designate
date: '2013-09-20 09:18'
comments: true
author: Tim Simmons
published: true
categories:
  - OpenStack
---

**Note**: This guide has been merged into the official Designate documentation. You can see that document here:
<https://designate.readthedocs.org/en/latest/getting-started.html>

A few weeks ago my team at Rackspace began investigation into the DNS as a Service application of Openstack, [Designate][1]. I’d like to share the method that my team and I formulated for getting a development environment for Designate up and running quickly. This set-up doesn’t include an OpenStack installation so there is no integration with Keystone or Nova. It’s the simplest possible installation, a great way for anyone to get started in contributing to OpenStack. Credit to the folks working on Designate for the original document.<!-- more -->

### Initial setup


The first thing you need is an Ubuntu Server (12.04). I recommend spinning up a [Cloud Server][2] with Rackspace. It’s relatively inexpensive and very slick. Assuming you have access to a server we can start installation.

### Install Designate


**1) Install system package dependencies:**

    $ apt-get install python-pip python-virtualenv

    $ apt-get install rabbitmq-server

    $ apt-get build-dep python-lxml

**2) Clone the Designate repo off of Stackforge:**

    $ git clone https://github.com/stackforge/designate.git

    $ cd designate

**3) Setup virtualenv:**

    $ virtualenv --no-site-packages .venv

    $ . .venv/bin/activate

**4) Install Designate and it’s dependencies**

    $ pip install -r requirements.txt -r test-requirements.txt

    $ python setup.py develop

**Note**: Everything from here on out should take place in or below your designate/etc folder

**5) Copy sample config files to edit yourself**

    $ cd etc/designate

    $ ls *.sample | while read f; do cp $f $(echo $f | sed

    "s/.sample$//g"); done

**6) Install the DNS server choose between**

PowerDNS

```
$DEBIAN_FRONTEND=noninteractive apt-get install pdns-server pdns-backend-sqlite3
#Update path to SQLite database to /root/designate/powerdns.sqlite or wherever your top level designate directory resides
$ editor /etc/powerdns/pdns.d/pdns.local.gsqlite3
#Change the corresponding line in the config file to mirror:
gsqlite3-database=/root/designate/pdns.sqlite
#Restart PowerDNS:
$ service pdns restart
```

**7. If you intend to run Designate as a non-root user, then sudo permissions need to be granted:**
```
$ echo "designate ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/90-designate

$ sudo chmod 0440 /etc/sudoers.d/90-designate
```

**8. Make the directory for Designate’s log files:**
```
$ mkdir /var/log/designate
```

### Configure Designate

```
$ editor designate.conf
```

Copy or mirror the configuration from this sample file [here][3].


#### Start the central services

```
#Initialize and sync the Designate database:
$ designate-manage database-init
$ designate-manage database-sync
#Initialize and sync the PowerDNS database:
$ designate-manage powerdns database-init
$ designate-manage powerdns database-sync
#Restart PowerDNS or bind9
$ service pdns restart
#Start the central service:
$ designate-central
```

**NOTE**: If you get an error of the form: ERROR [designate.openstack.common.rpc.common] AMQP server on localhost:5672 is unreachable: Socket closed
Run the following command:
```
$ rabbitmqctl change_password guest guest
#Then try starting the service again
$ designate-central
```

You’ll now be seeing the log from the central service.

### Start the API service

Open up a new ssh window and log in to your server (or however you’re communicating with your server).

    $ cd root/designate
    #Make sure your virtualenv is sourced
    $ . .venv/bin/activate
    $ cd etc/designate
    #Start the API Service
    $ designate-api
    #You may have to run root/designate/bin/designate-api


You’ll now be seeing the log from the API service.

### Exercising the API


Calls to the Designate API can be made using the following format:

    http://IP.Address:9001/v1/command

Enter in a web browser, curl statement, or ReST client any of the
commands listed in the Designate Documentation.

You can find the IP Address of your server by running:

```
 wget http://ipecho.net/plain -O - -q ; echo
```

If you'd like to see an instance in action, go here: <http://162.209.9.99:9001/v1/>

A couple of notes on the API:

* Before domains are created, you must create a server.
* You can read the ReST API Documentation [here][4]

Happy Designating! If you would like to contribute to Designate, come and [join us][5].

### About the author

Tim Simmons is a Rackspace intern on the Cloud DNS team. Recently, the
team evaluated the OpenStack DNSaaS solution, Designate. Tim took an
active role in the investigation; he wrote a "Getting Started" guide
which is published above. He also wrote a guide on using Designate, which will be
published here next week. Tim continues to play en essential role in our
next generation DNS offering.

[1]: https://wiki.openstack.org/wiki/Designate
[2]: http://www.rackspace.com/cloud/servers/
[3]: https://gist.github.com/TimSimmons/6596014
[4]: https://designate.readthedocs.org/en/latest/rest.html
[5]: https://designate.readthedocs.org/en/latest/getting-involved.html