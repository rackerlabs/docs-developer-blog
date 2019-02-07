---
layout: post
title: Zero to Peanut Butter Docker time in 78 seconds
date: '2013-11-11 12:00'
comments: true
author: Jesse Noller
published: true
categories:
  - docker
---

{% img right 2013-11-11-peanut-butter-docker-time/Peanut-Butter-and-Jelly-Time-Family-Guy.gif 300 %}

With the launch of our new [Performance Cloud Servers][1] - we've got speed. Lots of speed. Oodles of speed. I've got more benchmarks and data to post, but one of the things I've been meaning to do prior to this launch is to show how quickly you can get up and running with something else that's rocking the tech world: [Docker][2].

Two cool things - [Performance Cloud Servers][1] and [Docker][2] - what I want to show you today is how quickly you can go from zero to full on Docker setup. (tl;dr: **78 seconds**.)

<!-- more -->

### First, what is Docker

{% img center 2013-11-11-peanut-butter-docker-time/docker-transparent.png 400 %}

From their lovely page:

>Docker is an open-source project to easily create lightweight, portable, self-sufficient containers from any application. The same container that a developer builds and tests on a laptop can run at scale, in production, on VMs, bare metal, OpenStack clusters, public clouds and more.

Ok, so containers are cool. They are a light weight system to create isolated instances of the individual daemons, components and other pieces that might make up your application, CI/CD system, etc. The [Docker][2] [community][3] itself is vibrant, and growing at an astounding rate.

* [Docker: Learn More][4]
* [Docker: Documentation][5]
* [Docker: Community Stats][6]

This is all pretty amazing - and not to mention the latest Nova release in [OpenStack Havana][7] actually supports Docker as an option for the underlying hypervisor (ala Xen) which means:

{% img center 2013-11-11-peanut-butter-docker-time/yodawg.jpg 500 %}

### Let's do this.

Ok, so I'm going to ride the command line like a cowboy - using the [rackspace-novaclient][8] configured like this:

    [rack] pug:~ jesse$ pip install rackspace-novaclient
    ... stuff ...

    [rack] pug:~ jesse$ cat ~/.bash_profile
    export OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
    export OS_AUTH_SYSTEM=rackspace
    export OS_REGION_NAME=IAD
    export OS_USERNAME=<my username>
    export OS_TENANT_NAME=" "
    export NOVA_RAX_AUTH=1
    export OS_PASSWORD=<my api key, momma didn't raise no fool>
    export OS_NO_CACHE=1

**Note**: As pointed out in the [Performance Cloud Servers][1] post - currently the IAD region is the only one with the full rollout, all other regions following within the month.

So, let's boot a 1GB performance server (and pass in an SSH key via --key_name) and time it:

    [rack] pug:~ jesse$ time nova boot Docker1GB --flavor performance1-1 --image 62df001e-87ee-407c-b042-6f4e13f5d7e1 --key_name my_key --poll
    ...stuff...
    Instance building... 100% complete
    Finished

    real	0m42.404s
    user	0m0.335s
    sys	0m0.122s

42 seconds to boot the image - now let's update and install docker, following the [Ubuntu 13.04][9] instructions for Docker and this little gist:

<script src="https://gist.github.com/jnoller/7416128.js"></script>

Go go go go:

    root@docker1gb:~# chmod a+x setup_docker.sh
    root@docker1gb:~# time ./setup_docker.sh
    ...snip...
    ldconfig deferred processing now taking place
    Unable to find image 'ubuntu' (tag: latest) locally
    Pulling repository ubuntu
    8dbd9e392a96: Download complete
    b750fe79269d: Download complete
    27cf78414709: Download complete
    root@55c7a4c11356:/# exit
    exit

    real	0m36.510s
    user	0m3.384s
    sys	0m0.532s

And there you have it; 36 seconds to apt-get update, and install Docker and then exit the test shell it executes.

If I'm doing my math right - which is always questionable - that's 42 seconds to boot the image, and 36 seconds to install and run Docker. **78 seconds ~ a minute and a half**.

{% img center 2013-11-11-peanut-butter-docker-time/mind_blown.gif %}

### Doing something neat-o

Ok. So using our new [Performance Cloud Servers][1] - and the awesome packaging/installation work of the Docker team, you can boot a Docker server in under two minutes. Let's go and check out the [Docker Registry][10] for something cool to deploy. Doing a quick search, let's just deploy [Ken Cochrane's] [example Django application][11]:

    root@docker1gb:~# docker pull kencochrane/django-docker
    root@docker1gb:~# docker run -d -p :8000 kencochrane/django-docker
    f14248d20f70

And now we use the **docker port** command with the image ID to find the public port that Docker exposes with NAT:

    root@docker1gb:~/django-docker# docker port f14248d20f70 8000
    0.0.0.0:49154

{% img center 2013-11-11-peanut-butter-docker-time/finished.png 900 %}

You now have the perfect Django Polls application running in docker, in OpenStack, on [crazy fast][1] machines. All in minutes - not hours.

Looking at some of the cool Docker images you could play with:

* [Postgresql](https://index.docker.io/u/zaiste/postgresql/)
* [redis](https://index.docker.io/u/johncosta/redis/)
* [mysql, apache and sshd Wordpress stack](https://index.docker.io/u/jbfink/wordpress/)
* [nginx, php and Wordpress](https://index.docker.io/u/wayhome/wordpress/)

All of these fit into the 1GB Performance Cloud Server (~20,000 average IOPS/second) easily - and at $29.20/month it fits easily into the Rackspace [Developer Discount][13].

So many IOPS. So Docker. Wow.

Any questions, comments or concerns? You can reach out to me ([Jesse Noller][1]) on [Twitter][2], ping [@Rackspace](https://twitter.com/Rackspace) on Twitter, or even reach out to [help@rackspace.com](mailto:help@rackspace.com).


[1]: http://developer.rackspace.com/blog/welcome-to-performance-cloud-servers-have-some-benchmarks.html
[2]: http://www.docker.io/
[3]: https://www.docker.io/community/
[4]: https://www.docker.io/learn_more/
[5]: http://docs.docker.io/en/latest/
[6]: http://blog.docker.io/2013/11/docker-project-community-stats/
[7]: https://wiki.openstack.org/wiki/Docker
[8]: https://pypi.python.org/pypi/rackspace-novaclient/
[9]: http://docs.docker.io/en/latest/installation/ubuntulinux/#ubuntu-raring
[10]: https://index.docker.io/
[11]: https://github.com/kencochrane/django-docker
[12]: http://kencochrane.net/
[13]: http://developer.rackspace.com/devtrial/
