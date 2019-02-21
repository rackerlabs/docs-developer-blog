---
layout: post
title: 'Playing with CoreOS, Fleet and Docker'
date: '2015-06-17 13:00'
comments: true
author: Sri Rajan
bio: >
  Sriram (Sri) Rajan is an Principal Engineer at Rackspace and has more than
  a decade of professional experience working with computer systems, networks,
  programming and security. Prior to joining Rackspace, Sri worked as a systems
  programmer at Texas State University, from where he also earned his masters
  degree in computer science. He studied and lived in the United States for
  a total of nine years before relocating to the UK for work in 2010.
published: true
categories:
  - docker
---

In this post, we look at Docker, CoreOS & Fleet and demonstrate how one
could use all of them in an application scenario.

<!-- more -->

 * Before you start, you need the following: A Rackspace cloud account.

 * If you don't have an account, you can still follow this and do it on your own servers, but the process will need some customizations.

 * If using Rackspace Cloud, ensure that you have novaclient installed. Refer to [Installing Nova](https://support.rackspace.com/how-to/installing-python-novaclient-on-linux-and-mac-os/) for more details.

 * Next, clone this repo which is needed for the examples below.

  ```
  git clone https://github.com/srirajan/coreos-docker
  ```

 * Lets build a CoreOS cluster. To do that, first get a discovery URL for your cluster. CoreOS uses etcd, a service running on each machine, to handle messages between the cluster nodes. For a group of CoreOS machines to form a cluster, their etcd instances need to be connected. [See Cluster Discovery](https://coreos.com/docs/cluster-management/setup/cluster-discovery/) if you want to read more about how this works.

  ```
  curl -w "\n" https://discovery.etcd.io/new
  ```

 * IMPORTANT: Edit the cloud init file named cloudinit.yaml. Replace the token url from above otherwise things fail futher down.

  ```
  discovery: https://discovery.etcd.io/013df4e1ea978bf64bef2396c3096b90
  ```

 * If you have not done this, add your SSH key to the cloud setup

  ```
  nova keypair-add --pub-key <pub-key> demo-key
  ```

 * Decide which Rackspace cloud flavor you are using. For the image, we will be using CoreOS (Stable)

  ```
  flavor=general1-1
  image=cfb643d5-f48d-4988-9ca8-8689c1fc877b
  key=demo-key
  cloudinit=cloudinit.yaml
  ```

 * Boot 4 servers for our CoreOS cluster. Here we pass the cloud init file via the config-drive option. This typically takes about 3-5 minutes to complete. The min number of nodes is three, but having four helps maintain the cluster if you are upgrading or changing one of them.

  ```
  nova boot --flavor $flavor --image $image  --key-name $key \
  --config-drive true --user-data $cloudinit core01

  nova boot --flavor $flavor --image $image  --key-name $key \
  --config-drive true --user-data $cloudinit core02

  nova boot --flavor $flavor --image $image  --key-name $key \
  --config-drive true --user-data $cloudinit core03

  nova boot --flavor $flavor --image $image  --key-name $key \
  --config-drive true --user-data $cloudinit core04

  nova list
  ```

 * In the above steps, we should have created four CoreOs servers, which are in a cluster. The discovery URL we passed in Cloudinit binds them to the cluster and starts the required services like etcd and fleet.

 * Now, lets play with CoreOS, etcd, and Fleet. This should list all four machines in the cluster. Fleet, a distributed cluster management tool, relies on etcd, which is a distributed key value store for operation. It also works with systemd files and behaves like a distributed systemd in a multi-node setup.

  ```
  nova ssh core01 --network=public
  fleetctl list-machines
  ```

  Expected output:

  ```
  MACHINE   IP    METADATA
  5c978db9... 10.181.202.96 -
  b3f88d86... 10.181.202.94 -
  b4a07126... 10.181.202.97 -
  f35b7443... 10.181.202.100  -
  ```

 * Now, inside one of the CoreOS node (e.g. core01), clone the git repo

  ```
  cd /home/core
  git clone https://github.com/srirajan/coreos-docker
  ```

 * Load all the services. We wlll go into details of each service in following steps.

  ```
  cd /home/core/coreos-docker/fleet-services
  fleetctl submit *.service
  ```

  ```
  fleetctl list-unit-files
  ```

  Expected output:

  ```
  UNIT          HASH  DSTATE    STATE   TARGET
  db.service        fbf415a launched  launched  -
  dbhelper.service  747c778 inactive  inactive  -
  mondb.service     a4f50cc inactive  inactive  -
  monweb@.service   d5ed242 inactive  inactive  -
  web@.service      0ac8be5 inactive  inactive  -
  ```

 * Each of these services starts a Docker container for a particular use. You can review the respective Docker files to build these yourselves. Here's a quick summary
   * db - Standard mysql image from Docker registry. Sets the mysql root password. There is no Docker file for this.
   * dbhelper - Custom container that configures the db container. See [Docker file](https://github.com/srirajan/coreos-docker/blob/master/docker-images/dbhelper/Dockerfile)
   * mondb - There is no Docker image here. It just uses systemd to run etcd commands to set values in etcd
   * web - Custom container that configures the web container. This configures Nginx, copies some PHP code, and installs supervisord. See [Docker file](https://github.com/srirajan/coreos-docker/blob/master/docker-images/web/Dockerfile)
   * monweb - Similar to mondb but sets values for the web containers. Things like IP and port numbers are monitored and added to etcd.


 * Run the db service. This is a simple service that runs a mysql container on one of the hosts. Note that Fleet decides which host to run the container on, so it may be on any of the four nodes.

  ```
  fleetctl start db.service
  fleetctl list-units
  ```

 * Wait for this service to start before proceeding. This will typically take a few minutes as you are downloading the Docker image from the public registry.

 * dbhelper.service uses container linking to install the mysql world database and configure some users for our application. The systemd configuration tells fleet to run on the same host as the db.service. mondb.service is not a container but uses systemd to run a script that updates etcd with the information about the db service. In this case, we are just pushing private IPs to etcd, but this can be leveraged to do other things as well.

  ```
  fleetctl start dbhelper.service

  fleetctl start mondb.service
  ```

 * Run fleetctl again to see where our containers are deployed. Because of our systemd definition file, fleet will ensure they run on the same host.

  ```
  fleetctl list-units
  ```

 * You can also login to the host running the dbhelper service and review the journal (logs) for the service.

  ```
  fleetctl journal dbhelper
  -- Logs begin at Mon 2014-11-10 21:00:41 UTC, end at Thu 2014-11-13 14:23:43 UTC. --
  Nov 11 05:22:51 core04.novalocal systemd[1]: Stopped DB Helperservice.
  Nov 11 05:22:51 core04.novalocal systemd[1]: Unit dbhelper.service entered failed state.
  -- Reboot --
  Nov 13 14:22:43 core04 systemd[1]: Starting DB Helperservice...
  Nov 13 14:22:43 core04 docker[22239]: Pulling repository srirajan/dbhelper
  Nov 13 14:23:00 core04 systemd[1]: Started DB Helperservice.
  Nov 13 14:23:06 core04 docker[22272]: Creating the world database
  Nov 13 14:23:13 core04 docker[22272]: Creating application user
  Nov 13 14:23:13 core04 docker[22272]: Counting rows in world.city
  Nov 13 14:23:13 core04 docker[22272]: COUNT(*)
  Nov 13 14:23:13 core04 docker[22272]: 4079
  ```

 * Now, let's move on the web containers. Start the one container from the web service. In systemd, a service with @ is generic service, and you can append values to start as many of them as you want. The first container will take a little bit of time, as it is downloading the image, but subsequent ones are quick.

  ```
  fleetctl start web@01.service

  fleetctl list-units
  ```

  Expected output:

  ```
  UNIT      MACHINE       ACTIVE    SUB
  db.service        2aa4e35a.../10.208.201.253  active   running
  dbhelper.service  2aa4e35a.../10.208.201.253  active   running
  mondb.service     2aa4e35a.../10.208.201.253  active   running
  web@01.service    6847f4f7.../10.208.201.226  active   running
  ```

 * Start 9 more web containers. Fleet will disribute them across the different hosts.

  ```
  fleetctl start web@{02..10}.service

  fleetctl list-units
  ```

  Expected output:

  ```
  UNIT      MACHINE       ACTIVE  SUB
  db.service        2aa4e35a.../10.208.201.253  active  running
  dbhelper.service  2aa4e35a.../10.208.201.253  active  running
  mondb.service     2aa4e35a.../10.208.201.253  active  running
  web@01.service    6847f4f7.../10.208.201.226  active  running
  web@02.service    ee5398cf.../10.208.201.250  active  running
  web@03.service    6847f4f7.../10.208.201.226  active  running
  ...so on
  ```

 * Start the monweb services. These are similar to the mondb.service and update etcd with different values from the running containers.

  ```
  fleetctl start monweb@{01..10}.service

  fleetctl list-units
  ```

 * Wait for the services to start and then query etcd for values. This will return the IP addresses and ports of the web containers

  ```
  for i in {01..10}; do  \
   etcdctl get /services/web/web$i/unit; \
   etcdctl get /services/web/web$i/host; \
   etcdctl get /services/web/web$i/public_ipv4_addr; \
   etcdctl get /services/web/web$i/port; \
   echo "-----" ;\
   done
  ```

 * Test the sites on one of the container using the IP addresses and ports returned above. world.php connects to the world database on the db container and runs some queries.

  ```
  curl http://162.242.255.73:18010/
  curl http://162.242.255.73:18010/home.php
  curl http://162.242.255.73:18010/world.php
  ```

At this point, we have a database container running and a bunch of web containers running on different hosts. The communication between them has been established, and we have an working PHP app. An optional step which I have working, but skipped in this post was to run a service that watches these containers and adds them to a load balancer.  This is fairly trivial to do but would be specific to the load balancer service you are using.

This covers our exploration of Docker, CoreOS and Fleet.  There is more these tools can do to help with tighter integration, but, overall, this combination is a good way to manage docker containers and run workloads on it.


Some additional commands that help:


 * Build without cache. This burnt me the first time. Ubuntu removes old package versions from their repos, and, if a cached image has that version, apt-get install will try to pull that and fail. Needless to say --no-cache will take longer to build.

  ```
  docker build --no-cache
  ```

 * Review logs of etcd and fleet

  ```
  journalctl -u etcd
  journalctl -u fleet
  ```

 * Delete all containers

  ```
  docker stop $(docker ps -a -q)
  sleep 2
  docker rm $(docker ps -a -q)
  ```

 * Delete all images

  ```
  docker rmi $(docker images -q)
  ```

 * Cleanup fleet

  ```
  fleetctl destroy $(fleetctl list-units -fields=unit -no-legend)
  fleetctl destroy $(fleetctl list-unit-files -fields=unit -no-legend)
  sleep 5
  fleetctl list-unit-files
  fleetctl list-units
  ```

 * Restart Fleet

  ```
  sudo systemctl restart fleet.service
  ```
