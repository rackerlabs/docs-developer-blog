---
layout: post
title: Slumlord hosting with Docker
date: '2013-08-30 08:00'
comments: true
author: Hart Hoover
published: true
categories:
  - Docker
---
{% img right 2013-08-19-slumlord-hosting/slumlord.jpg 200 %}
Since becoming a Racker back in 2007, one of my all time favorite websites has
been [slumlordhosting.com][1]. Slumlord Hosting is a parody of really bad shared
hosting environments, advertising some amazing features:

* Dedicated space on a "High Density Floppy Storage Area Network Device"
* A duel (sic) channel ISDN line for maximum bandwidth
* 10MB of dedicated space

On top of the features listed above, the website itself is glorious. Looking at
it recently, I began to think to myself, "If I were running a business like this,
what could I use to squeeze every possible resource out of a server and offer
it up for shared hosting?" Enter [Cloud Servers][2] and [Docker][3]. My strategy
is simple: build a Cloud Server, install Docker, and then create as many containers
as possible. I've decided to use WordPress containers since WordPress is extrememly
popular.

*Running a hosting business based on how many containers you can squeeze on a
server is definitely NOT RECOMMENDED and is more for fun while we play with Docker.*

<!-- more -->

### What is Docker?

Docker is a very, VERY popular open source project. Since the project was open
sourced only a few months ago, Docker has over 4800 stars, 490 forks, and over
300 watchers [on GitHub][9]. There are over 100 contributors. So what does
Docker do? From the Docker website:

>Docker is an open-source engine that automates the deployment of any application
as a lightweight, portable, self-sufficient container that will run virtually
anywhere.

> Docker containers can encapsulate any payload, and will run consistently on
and between virtually any server. The same container that a developer builds and
tests on a laptop will run at scale, in production, on VMs, bare-metal servers,
OpenStack clusters, public instances, or combinations of the above.

Now that we know what Docker is, let's look at how to implement it for our
purposes as a hosting slumlord.

### Install Docker

To install Docker, I need a Rackspace Cloud Server. I'm starting with Ubuntu 13.04
and my SSH key for easy login:

```
nova boot --image 1bbc5e56-ca2c-40a5-94b8-aa44822c3947 --flavor 2 --key-name mykey slumlord
```

Notice that I used the smallest server available: 512M of RAM. This is way too
much by slumlord standards, but at least I can have more containers. After the
server comes up, install Docker:

```
apt-get update
apt-get install linux-image-extra-`uname -r`
apt-get install software-properties-common git

# Add the Docker repository key to your local keychain
curl http://get.docker.io/gpg | apt-key add -

# Add the Docker repository to your apt sources list.
echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list

# update
apt-get update

# install
apt-get install lxc-docker
```

If you want to know more about what you just did, take a look at the [Docker documentation][4].
Now that Docker is installed, I need to create a WordPress Docker container.

### Create a WordPress container

For this, I forked a project on GitHub called "[docker-wordpress][5]" (written
by John Fink). Why fork? To use Ubuntu 13.04 of course! To create a WordPress
container, run the following commands:

```
# Build the container
docker build -t slumlord/wordpress git://github.com/hhoover/docker-wordpress.git

# Start it up
docker run -d slumlord/wordpress

# Check your port
docker port <container-id> 80
```

This builds a WordPress docker container and runs it. Browse to the Cloud Server
IP address and port that Docker provides to get a WordPress installation page.
Let's take a look at the Dockerfile that makes the magic happen:

```
FROM boxcar/raring
MAINTAINER Hart Hoover <hart.hoover@gmail.com>
RUN apt-get update # DATE Thu Aug 22 10:22:19 EDT 2013
RUN apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install mysql-client mysql-server apache2 libapache2-mod-php5 pwgen python-setuptools vim-tiny php5-mysql openssh-server sudo
RUN easy_install supervisor
ADD ./start.sh /start.sh
ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf
RUN echo %sudo	ALL=NOPASSWD: ALL >> /etc/sudoers
RUN rm -rf /var/www/
ADD http://wordpress.org/latest.tar.gz /wordpress.tar.gz
RUN tar xvzf /wordpress.tar.gz
RUN mv /wordpress /var/www/
RUN chown -R www-data:www-data /var/www/
RUN chmod 755 /start.sh
RUN chmod 755 /etc/apache2/foreground.sh
RUN mkdir /var/log/supervisor/
EXPOSE 80
EXPOSE 22
CMD ["/bin/bash", "/start.sh"]
```

Basically, this Dockerfile installs packages we need, puts scripts in place for
us, and downloads and unpacks WordPress. The `start.sh` script sets up a
WordPress MySQL database and generates passwords, while the `foreground.sh`
script starts Apache. Docker doesn't let you start services using
`service some_service start` or `/etc/init.d/serviced start`, so we use `supervisord`
to start services for us. The Dockerfile also makes sure that port 80 is available
externally for our web server, and 22 is open so we can SSH to the container.
These ports are connected to a port on the host machine.

You can see a lot of information about the running container with the following
`inspect` command.

```
docker inspect <container-id>
```

Now, it's time to make this available for customers! Go ahead and kill this
Docker contatiner. Our application will make more later:

```
docker stop <container-id>
```

### Slumlord dashboard

The [Slumlord WordPress dashboard][6] is also a forked project on GitHub. The
original project was a proof-of-concept [SaaS application for Memcached][7].
We use it here for our nefarious slumlord purposes. First, we need to install
dependencies:

```
apt-get install libxslt-dev libxml2-dev build-essential libpq-dev
curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3
source /usr/local/rvm/scripts/rvm
```

After you have the dependencies installed, clone the front-end repository:

```
git clone https://github.com/hhoover/slumlord-wordpress /var/www
cd /var/www # accept when you see the RVM message
bundle install
```

Then, we need to create the database and start the rails server:

```
rake db:migrate
rails server
```

You can set this application up to run with an app server if you like (such as
Unicorn, Passenger, Thin, or whatever), but that setup is outside the scope of
this post. Navigate to the IP address of your server on port 3000 and marvel at
Slumlord WordPress.

{% img center 2013-08-19-slumlord-hosting/slumlord_frontend.png %}

When a user clicks the "Sign Up Now" button and creates an account, a Docker
container with Apache, PHP, MySQL and WordPress is created from the template
container we made earlier.

### The unthinkable

What if a customer wanted to leave Slumlord WordPress and migrate away? While
the probability of this is close to zero, Docker makes it easy:

```
docker commit <container-id> customer/wordpress
```

The container in its current state can then be moved to a different server running
Docker and restarted. Lucky for the slumlord, if a customer wants to sign up with
your service, this helps you as well!

### Want more information?

If you want to learn more about Docker, the [documentation][8] is a great place
to start. Docker is also actively looking for [contributions to the project][9]!

[1]: http://slumlordhosting.com
[2]: http://www.rackspace.com/cloud/servers/
[3]: http://docker.io
[4]: http://docs.docker.io/en/latest/installation/ubuntulinux/#ubuntu-raring
[5]: https://github.com/jbfink/docker-wordpress
[6]: https://github.com/hhoover/slumlord-wordpress
[7]: https://github.com/jbarbier/SaaS_Memcached
[8]: http://docs.docker.io/en/latest/
[9]: https://github.com/dotcloud/docker
