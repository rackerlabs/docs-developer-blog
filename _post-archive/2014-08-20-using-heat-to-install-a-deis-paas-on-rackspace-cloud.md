---
layout: post
title: Using Heat to install a DEIS PAAS on Rackspace Cloud.
date: 2014-08-16T00:00:00.000Z
comments: true
author: Paul Czarkowski
published: true
categories: []
bio: "Paul Czarkowski is a Systems Engineer working at Rackspace \non the Solum Project.\n"
---
### Introduction
Platform As A Service (PAAS) is an important topic right now. [Docker](https://docker.io)
and related technologies have created a surge in the number of people offering ways to provide application-centric infrastructure. The end-game of cloud is to allow developers using the cloud to care
less about the actual infrastructure ( VMs, Load Balancers, Databases, etc) and more about
the construction and functionality of their application.

<!-- more -->

PAAS is good step in that direction. Unfortunately, running a PAAS has been as hard as, if not harder than, running
than running the underlying IAAS infrastructure itself. This is slowly changing as the innovators
in the field are starting to push the complexity further away from the user by using smart tooling.

One such innovator, [DEIS](https://deis.io), combines Docker and [CoreOS](https://coreos.com/), along with
associated systems, to simplify the process and reduce the operations overhead incurred by running it. DEIS is currently 
pre 1.0 and still needs some work before anybody but the truly bleeding-edge users would be comfortable
running production workloads on it; however it's perfect for building out development environments,
which lets developers test and demonstrate their work quickly and early in the development cycle.

This ability to quickly spin up demonstration environments allows for fast feedback and very lean / agile
development processes. Within minutes of adding a new feature, a developer can deploy and request feedback.
You can see an excellent short demo of this on the [DEIS blog](https://deis.io/demo-deis-pull-in-action/).

### Installing DEIS

DEIS requires at least three servers running CoreOS and benefits greatly from being fronted by a load balancer.  The
installation process is relatively straight forward, but it requires a number of steps, some of which are wrapped inside scripting. I
was doing some testing and found myself destroying and recreating DEIS environments dozens of times, as well as making errors 
during some of the steps. This rework made for a frustrating experience.

#### Rackspace Cloud Orchestration ( Heat )

After going through these steps a number of times, I became quite familiar with them and decided to try using Rackspace's 
relatively new Orchestration system, which is based on Openstack Heat. I quickly discovered that Heat is a very powerful 
templating language used for quickly describing and building infrastructure. After a few hours of prototyping, I found myself 
with a reliable way to create and destroy DEIS environments with a single command.

Instructions for installing the Heat client, including setting up authentication credentials, can be found in [The Rackspace Orchestration documentation](https://docs.rackspace.com/orchestration/api/v1/orchestration-getting-started/content/Install_Heat_Client.html). 

The heat template that I came up with can be found [here](https://gist.github.com/paulczar/6f773bc1c98395f0a2d4).
It takes several inputs, such as the etcd discovery url (unique for each install), the number of servers, the flavor of servers, and the version of Deis, to perform the installation ( master by default ). 

Assuming you have the Heat client installed, you can start DEIS by simply running the following command ( from an OSX or linux box):

```sh
$ export ETCD=$(curl -s https://discovery.etcd.io/new)
$ export TEMPLATE=https://gist.githubusercontent.com/paulczar/6f773bc1c98395f0a2d4/raw/f3e3a5c0623e0f108b01d0d39c88b2e1d3181f0e/deis.yaml
$ heat stack-create deis --template-url=$TEMPLATE \
 -P flavor='2 GB Performance' -P count=3 \
 -P name=DEIS -P etcd_discovery="$ETCD" -P deis_version='v0.10.0'
```

The preceding commands will download the heat template and create a private key, three coreos servers, and a load balancer. Once the servers are online, one of the servers will install DEIS itself, and, after a few minutes, you should have a completed installion. You can check the status of the install by running the following command:

```sh
$ heat stack-list
-----------------------------------------------------------------------------------------
| id | stack_name | stack_status | creation_time |
-----------------------------------------------------------------------------------------
| 2e74c93d-e3d7-474c-ac3a-cba178840238 | deis | CREATE_COMPLETE | 2014-08-16T16:13:13Z |
-----------------------------------------------------------------------------------------

```

If the stack_status shows a value of CREATE_COMPLETE, then your stack is online.

Now, you'll want to download and set up your SSH key. You can retrieve it from Heat and save it to your home directory like this:

```sh
$ eval `ssh-agent`
$ DEIS_KEY=$(heat output-show deis private_key | sed 's/"//g') && printf $DEIS_KEY > ~/deis_key
$ chmod 0600 ~/deis_key
$ ssh-add ~/deis_key
```

Next you can get a list of IP addresses of your Load Balancer and your CoreOS servers:

```sh
$ export LB=$(heat output-show deis lb_public_ip | sed 's/"//g') && echo $LB
23.253.147.246
$ heat output-show deis deis_networks
[
 {
 "public": [
 "104.130.16.176"
 ],
 "private": [
 "10.176.135.127"
 ]
 },
 {
 "public": [
 "104.130.16.174"
 ],
 "private": [
 "10.176.135.124"
 ]
 },
 {
 "public": [
 "104.130.16.177"
 ],
 "private": [
 "10.176.135.138"
 ]
 }
]

```

Pick one of your CoreOS hosts, and ssh to it via the Public IP. Then set up some environment variables so that you can talk to `fleet` and `etcd` using the private IP and check on the installation of DEIS itself. The following commands demonstrate this:

```sh
$ ssh -i ~/deis_key core@104.130.16.176

Welcome to Deis Powered by CoreOS
core@deis ~ $ export FLEETCTL_ENDPOINT=https://10.176.135.127:4001
core@deis ~ $ fleetctl list-machines
MACHINE IP METADATA
54979824... 104.130.16.174 -
571b5cd0... 104.130.16.176 -
5c87b852... 104.130.16.177 -
core@deis ~ $ fleetctl list-units
UNIT STATE LOAD ACTIVE SUB DESC MACHINE
deis-builder-data.service loaded loaded active exited deis-builder-data 571b5cd0.../104.130.16.176
deis-builder.service launched loaded activating start-post deis-builder 571b5cd0.../104.130.16.176
deis-cache.service launched loaded active running deis-cache 571b5cd0.../104.130.16.176
deis-controller.service launched loaded active running deis-controller 5c87b852.../104.130.16.177
deis-database-data.service loaded loaded active exited deis-database-data 571b5cd0.../104.130.16.176
deis-database.service launched loaded active running deis-database 571b5cd0.../104.130.16.176
deis-logger-data.service loaded loaded active exited deis-logger-data 5c87b852.../104.130.16.177
deis-logger.service launched loaded active running deis-logger 5c87b852.../104.130.16.177
deis-registry-data.service loaded loaded active exited deis-registry-data 5c87b852.../104.130.16.177
deis-registry.service launched loaded active running deis-registry 5c87b852.../104.130.16.177
deis-router.1.service launched loaded active running deis-router 571b5cd0.../104.130.16.176
deis-router.2.service launched loaded active running deis-router 5c87b852.../104.130.16.177
deis-router.3.service launched loaded active running deis-router 54979824.../104.130.16.174
```

You can see quite a number of services running spread across the three servers. In the example above, all systems apart from the `deis-builder` are online. After waiting a few more minutes,  the `deis-builder` process should also flip over to `active`. Log out of the CoreOS server before going any further.

#### Installing secondary Load Balancer

We could not use Heat to create a second Load Balancer, which shares the VIP of the first load balancer, for `SSH` access (this is coming soon to Heat). Instead, you can do this via the [Rackspace MyCloud Portal](https://mycloud.rackspace.com) . Go to the Load Balancer and click Create and use following settings as a guide:

```
 DEIS-SSH
 Virtual IP Shared VIP on Another Load Balancer (select DEIS)
 Port 2222
 Protocol TCP
```

Our last step is to set up DNS. If your domain is hosted by Rackspace, you can actually do that automatically as part of your HEAT template. Because this is just a temporary install of DEIS, I am going to cheat and use the `xip.io` wildcard dns resolver and save it to an environment variable using the following command:

```sh
export DEIS_DNS=$(heat output-show deis lb_public_ip | sed 's/"//g').xip.io && echo $DEIS_DNS
```

#### Use your new DEIS installation

Once installed, you should register your first user ( the admin user ) and upload a public key as shown here:

```sh
deis register https://deis.$DEIS_DNS
username: admin
password:
password (confirm):
email: <your_email_address>
$ deis keys:add
Found the following SSH public keys:
1) id_dsa.pub first_key
2) id_rsa.pub second_key
0) Enter path to pubfile (or use keys:add <key_path>)
Which would you like to use with Deis? 1
Uploading first_key to Deis...done

```

Next, we need to create a cluster ( a set of servers used to host applications ) that includes all of your CoreOS servers. Collect the private IPs from the output of the previous steps and use them in the following command:

```sh
$ deis clusters:create dev dev.$DEIS_DNS --hosts=10.176.135.127,10.176.135.124,10.176.135.138 --auth=~/deis_key
Creating cluster... done, created dev
```

Our final step is to deploy an example application, like the following example:

Deploy an example app:

```sh
$ git clone https://github.com/deis/helloworld.git
$ cd helloworld
$ deis create
Creating application... done, created twenty-woodshed
Git remote deis added
$ git push deis master
..
..
remote:
remote: -----> kabuki-gatepost deployed to Deis
remote: https://kabuki-gatepost.dev.104.130.42.40.xip.io
$ curl https://kabuki-gatepost.dev.104.130.42.40.xip.io
Welcome to Deis!
See the documentation at https://docs.deis.io/ for more information.
```

At this point, you might want to disable new user registration and
[manage users manually](https://docs.deis.io/en/latest/managing_deis/managing_users/) as follows:

```sh
$ ssh -i ~/deis_key core@104.130.16.176 'etcdctl --peers=10.176.135.127:4001 set --ttl=0 /deis/controller/registrationEnabled 0'
```

### What next?

We've stood up a DEIS based PAAS running on the cloud. This is probably enough for an example or development environment, but you may want to look at [running an HA database](https://docs.deis.io/en/latest/managing_deis/ha_database/), or, at the very least, doing [periodic backups](https://docs.deis.io/en/latest/managing_deis/backing_up_data/) of your data containers.
