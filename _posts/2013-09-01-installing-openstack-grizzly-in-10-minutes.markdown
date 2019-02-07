---
layout: post
title: Installing OpenStack Grizzly in 10 minutes
date: '2013-09-01 08:00'
comments: true
author: Kord Campbell
published: true
categories:
  - OpenStack
---

The [OpenStack](http://www.openstack.org/software/) provides a way to turn bare metal servers into a private cloud. It's been over a year since I published the first [Install OpenStack in 10 Minutes](http://www.stackgeek.com/guides/gettingstarted.html) guide and now, nearly 10K installs later, I'm pleased to announce the quickest and easiest way yet to get an OpenStack cluster running.

The scripts provided in this guide build a Chef server inside a [Vagrant box](http://vagrantup.com/), which ends up acting as a sort of 'raygun' to blast OpenStack onto the nodes.  Everyone knows [rayguns](https://www.google.com/search?q=raygun+beam&tbm=isch) are awesome, and so is the screencast:

[![ScreenShot](https://raw.github.com/rackerlabs/vagrantstack/master/openstack_movie.png)](http://vimeo.com/73001135)

<!-- more -->

Before we drop into the guide, I'd like to thank [Blue Chip Tek](http://bluechiptek.com) for providing hardware, advice and setup assistance, [Dell Computers](http://dell.com/) for donating the test hardware, and the awesome folks at [Rackspace](http://rackspace.com/) for writing and supporting the [Chef scripts](https://github.com/rcbops/chef-cookbooks) which are used for the bulk of the setup process.

### Prerequisites for installation

The new install scripts are [available for download](https://github.com/rackerlabs/vagrantstack) from Github.

Before you start, make sure you have a minimum of one bare metal node running [Ubuntu Server 12.04](http://www.ubuntu.com/download/server).  If you are installing on more than one node, make sure all the nodes are on the [same private IP block](http://en.wikipedia.org/wiki/Private_network) and are able to talk to each other before proceeding.  All nodes will need Internet access via NAT provided by a DHCP server/router.

If you don't have Vagrant installed on your computer (desktop/laptop) yet, you'll need to download both [Vagrant](http://vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/):

* Install VirtualBox 4.2.16 for [Windows](http://download.virtualbox.org/virtualbox/4.2.16/VirtualBox-4.2.16-86992-Win.exe) or [OSX](http://download.virtualbox.org/virtualbox/4.2.16/VirtualBox-4.2.16-86992-OSX.dmg)

* Install Vagrant 1.2.7 for [Windows](http://files.vagrantup.com/packages/7ec0ee1d00a916f80b109a298bab08e391945243/Vagrant_1.2.7.msi) or [OSX](http://files.vagrantup.com/packages/7ec0ee1d00a916f80b109a298bab08e391945243/Vagrant-1.2.7.dmg).

Double click each package to run through the installation on your local machine.

### Download the install scripts

Start a terminal on your local machine and make sure you have *git* installed.  If you don't, you can [download it here](http://git-scm.com/downloads).  Make and move yourself into a directory called *openstack*:

    mkdir openstack; cd openstack

Next, clone the scripts from the repo:

    git clone https://github.com/rackerlabs/vagrantstack.git

Now move into the scripts directory and take a gander at the scripts:

    cd vagrantstack; ls

### Create the setup file

The setup script provided in the repository will prompt you for a few variables, including the number of nodes for the cluster, the node IPs and names, and the network you'll be using for instances.  Start the setup script by typing the following:

    ./openstack_setup.sh

Once the setup script finishes, you will have a *setuprc* file that will look something like this:

    export NUMBER_NODES=3
    export NODE_1_HOSTNAME=nero
    export NODE_1_IP=10.0.1.73
    export NODE_2_HOSTNAME=spartacus
    export NODE_2_IP=10.0.1.93
    export NODE_3_HOSTNAME=invictus
    export NODE_3_IP=10.0.1.94
    export ROOT_PASSWD=af5b015ab50472e2368cdef95dfda120
    export PUBLIC_NETWORK=10.0.1.0
    export PRIVATE_NETWORK=10.0.55.0
    export BRIDGE_INTERFACE=eth0

Before you continue with the install, double check the network interface names on your nodes:

	kord@nero:~$ ifconfig -a |grep Ethernet
	br100     Link encap:Ethernet  HWaddr d4:3d:7e:33:f7:31
	eth0      Link encap:Ethernet  HWaddr d4:3d:7e:33:f7:31

If your primary interface name is different than **eth0**, be sure to edit the *setuprc* file and change the **BRIDGE_INTERFACE** value to the correctly named interface.  Things will go horribly wrong later if you don't do this now!

*Note: If you are using a Windows box, and [can't run bash scripts](http://www.cygwin.com/), you can move the*  **setuprc.example** *file  to*  **setuprc** *and edit as needed:*

    move setuprc.example setuprc
    notepad setuprc
    dos2unix setuprc

### Provision the Chef server

The Chef server is built and started by the Vagrant manager and should take 5-10 minutes to build on a fast box and connection.  Start the server by typing:

    vagrant up

*Note: If you have multiple network interfaces on your desktop or laptop, you will be prompted to choose one for the bridge that is created for the Vagrant server.*

Once the Chef server is provisioned, ssh into it:

    vagrant ssh

Once you are logged into the server, become root and change into the *vagrantstack* directory:

    sudo su
    cd /root/vagrantstack

Now run the install script to print out the node configuration commands:

    ./openstack_install.sh

### Configuring the nodes

You need to do some manual configuration of your nodes now.  The install script you just ran will dump out instructions and commands you can use to cut and paste and save time.

**1. Begin by setting a temporary root password on each node:**

    root@chef-server# ssh user@hostname
    user@hostname$ sudo passwd root
    [sudo] password for user:
	Enter new UNIX password:
	Retype new UNIX password:
	passwd: password updated successfully
    user@hostname$ exit
    ...

You need to replace the **user** and **hostname** appropriate for your nodes and repeat these steps for each and every node you specified in the setup.  For each node, you will be prompted for your user password twice and the new root password twice.

*Note: The scripts will take care of disabling the temporary root password after the keys are installed.*

**2. Next, push the root key to each node from the Chef server:**

    ssh-copy-id root@hostname
    ...

As above, you will need to replace **hostname** with the node's actual hostname and then repeat this for each and every node in your cluster.  You will be prompted by the nodes for the root password you set in step 1 above.

### Deploy the nodes

The deploy script installs the Chef client on all the nodes you specified in the *setuprc* file.  After the deploy script is done, manually running the chef-client command kicks off the install of OpenStack.  Start the install of the client by typing the following from the Chef server:

    ./openstack_deploy.sh

Once the deployment script completes, ssh to each node and manually run the Chef client command:

    root@chef-server# ssh root@hostname
    root@hostname# chef-client
    ...

As you did earlier, replace **hostname** here with the actual hostname of each node.  Repeat this for each and every node in your cluster.  **You may run these commands simultaneously on all nodes to speed up the install process.**

The first node in your cluster will be configured as an all-in-one controller.  This node will host the database for OpenStack, provide authentication, host the web UI, and perform network coordination.  The all-in-one node will also serve as a nova-compute node.  If you have more than one node in your cluster, the remainder of the nodes will be deployed as nova-compute nodes.

### Start the instances

After the all-in-one node is provisioned, you should be able to log into the web UI for OpenStack.  Enter the IP address of the all-in-one node, which should be the **NODE_1_IP** variable in your Chef server environment:

    http://10.0.1.73

The default user for the web UI is **admin** and the default password is **secrete**.

You can refer to the [video guide](http://vimeo.com/41807514) for getting started using the UI.

### Create a floating IP pool

If you want your instances to have external IPs, simply create a floating IP pool for them from the command line on the all-in-one instance:

    root@nero# nova-manage floating create --pool=mylocalips --ip_range=10.0.1.225/27

Be sure to block these addresses out of your existing DHCP server or router as the Nova process will be managing them for you!

### Troubleshooting

If anything goes wrong with the install, be sure to ask for help.  The easiest way to get help is to [post in the forums](https://groups.google.com/forum/?fromgroups#!category-topic/stackgeek/openstack/_zbeGoOBg-Q).  Here are a few simple suggestions you can try:

**1. Check you can ping your nodes by name from the Chef server:**

    root@chef-server# ping nero
	64 bytes from nero (10.0.1.100): icmp_req=1 ttl=64 time=0.463 ms
	^C
	--- nero ping statistics ---
	1 packets transmitted, 1 received, 0% packet loss, time 0ms
	rtt min/avg/max/mdev = 0.463/0.463/0.463/0.000 ms

**2. Check you can ping your Chef server by name from a node:**

	root@chef-server# ssh nero
	root@nero# ping chef-server
	PING chef-server (10.0.1.57) 56(84) bytes of data.
	64 bytes from chef-server (10.0.1.57): icmp_req=1 ttl=64 time=0.455 ms
	^C
	--- chef-server ping statistics ---
	1 packets transmitted, 1 received, 0% packet loss, time 0ms
	rtt min/avg/max/mdev = 0.455/0.455/0.455/0.000 ms

**3. Check you can remotely execute commands on the nodes from the Chef server:**

    root@chef-server# ssh nero uptime
    09:59:04 up 12 days, 15:04,  0 users,  load average: 0.10, 0.14, 0.14

**4. See what nodes Chef knows about:**

	root@chef-server# knife node list
	invictus
	nero
	spartacus

**5. Run a sync on the environment for the nodes:**

    root@chef-server# knife exec -E 'nodes.transform("chef_environment:_default") { |n| n.chef_environment("grizzly") }'

**6. Rerun the chef-client on each node:**

    root@chef-server# ssh nero
    root@nero# chef-client

**7. Check the OpenStack services are running normally:**

    root@nero:~# nova-manage service list
	Binary           Host                Zone             Status     State Updated_At
	nova-scheduler   nero                internal         enabled    :-)   2013-08-23 17:10:45
	nova-conductor   nero                internal         enabled    :-)   2013-08-23 17:10:49
	nova-cert        nero                internal         enabled    :-)   2013-08-23 17:10:48
	nova-consoleauth nero                internal         enabled    :-)   2013-08-23 17:10:48
	nova-network     nero                internal         enabled    :-)   2013-08-23 17:10:48
	nova-compute     nero                nova             enabled    :-)   2013-08-23 17:10:49
	nova-network     invictus            internal         enabled    :-)   2013-08-23 17:10:51
	nova-compute     invictus            nova             enabled    :-)   2013-08-23 17:10:47
	nova-network     spartacus           internal         enabled    :-)   2013-08-23 17:10:52
	nova-compute     spartacus           nova             enabled    :-)   2013-08-23 17:10:49
