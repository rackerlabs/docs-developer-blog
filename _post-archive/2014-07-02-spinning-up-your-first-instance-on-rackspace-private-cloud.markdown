---
layout: post
title: Spinning Up Your First Instance on Rackspace Private Cloud
date: '2014-07-02 14:09'
comments: true
author: James Thorne
published: true
categories:
  - OpenStack
  - Private Cloud
---
Last week, I presented a live webinar on how to use the OpenStack Horizon Dashboard to [spin up your first instance on Rackspace Private Cloud](http://youtu.be/YZModLNABhU). The Horizon Dashboard is a simple and intuitive way to begin consuming your OpenStack environment. But, what if you want to administer and use your OpenStack environment using the OpenStack Python command line tools?

In the following post, the second of several in the [RPC Insights series](http://www.rackspace.com/blog/welcome-to-rpc-insights/), I am going to detail how to do everything I did in the webinar using the Horizon Dashboard with the OpenStack Python command line tools.

<!-- more -->

In the webinar, I was working from a virtual Rackspace Private Cloud environment running on my workstation. That environment was created using these [multi-node Vagrantfiles](http://thornelabs.net/2013/12/17/deploy-rackspace-private-cloud-entirely-within-a-vagrantfile-on-virtualbox-or-vmware-fusion.html). The entirely of this post will assume you are using those multi-node Vagrantfiles as well. It is worth mentioning that most of the commands below will work just as well on other OpenStack environments. The main difference between other evironments will be the networking layout and configuration.

Log into the OpenStack Controller Node
--------------------------------------

Unless otherwise stated, the entirety of this post will assume you are logged into your OpenStack controller node and are running the commands from it.

Start by logging into your OpenStack controller node:

```sh
vagrant ssh controller1
```

Log in as the root user and stay logged in as root throughout this post (the root password is __vagrant__):

```sh
su -
```

In root’s home directory is an __openrc__ file which contains the necessary credentials to use the OpenStack APIs. Source this file into your environment:

```sh
source ~/openrc
```

Upload Images to Glance
-----------------------

A base Rackspace Private Cloud install does not include any OpenStack images and without any images you will not be able to boot any OpenStack Instances. There are many [pre-built OpenStack images](http://docs.openstack.org/image-guide/content/ch_obtaining_images.html) available from all of the major Linux distributions.

In this post you will be uploading the __CirrOS 0.3.2 x86_64 OpenStack cloud image__ into the Glance Repository.

Upload the CirrOS OpenStack cloud image by running the following command:

```sh
glance image-create --name cirros-0.3.2-x86_64 --is-public true --container-format bare --disk-format qcow2 --copy-from http://download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img
```

You can monitor the upload progress by running `glance image-list`.

Add Rules to the default Neutron Security Group
-----------------------------------------------

Each OpenStack Instance you spin up is assigned to the __default__ Neutron Security Group, which essentially contains iptables rules. An OpenStack Instance can be assigned to as many Neutron Security Groups as needed, but for now you will focus on the __default__ Neutron Security Group.

By default, there are no rules in the __default__ Neutron Security Group. You will need to allow ICMP traffic to test network connectivity and SSH traffic to log into your OpenStack Instance.

Create rules to allow ICMP and SSH traffic by running the following commands:

```sh
neutron security-group-rule-create --direction ingress --ethertype IPv4 --protocol icmp default

neutron security-group-rule-create --direction ingress --ethertype IPv4 --protocol tcp --port-range-min 22 --port-range-max 22 default
```

Create a New Flavor
-------------------

Every OpenStack Instance you create will be assigned a flavor. A flavor designates how much CPU, RAM, and Storage to allocate to an OpenStack Instance. OpenStack comes with several default flavors. You can create your own flavors as well.

Create a new flavor called __m1.supertiny__ with an ID of __auto__, __256 MB__ of RAM, __1 GB__ of root disk space, and __1__ vCPU by running the following command:

```sh
nova flavor-create m1.supertiny auto 256 1 1
```

Create Your SSH Keypair
-----------------------

Most OpenStack cloud images have password-based log in turned off. This is partly a security measure so there are not OpenStack cloud images created and left running with default passwords. So, to log in to an OpenStack Instance you will need to create an SSH keypair.

_If you already have an SSH keypair created, you can skip this paragraph._ On your workstation, open your terminal application and run `ssh-keygen`. You can accept all of the default settings. I would recommend setting a password on your SSH private key, but for now create it without a password.

On your workstation, in your home directory, you should now have a __.ssh__ directory. Inside that directory will be two files: __id_rsa__ and __id_rsa.pub__. __id_rsa__ is the SSH private key and should only exist on your workstation. __id_rsa.pub__ is the SSH public key and can be copied to any server you want to access. Open __id_rsa.pub__ in a text editor and copy all of its contents to your clipboard.

On the OpenStack controller node, use __vim__, __nano__, or another command line text editor to create a file, copy the contents from your clipboard into the file, and save the file as __workstation.pub__.

Then, from the OpenStack controller node, upload the SSH public key to the nova keypair database by running the following command:

```sh
nova keypair-add --pub_key workstation.pub workstation
```

With this SSH public key in the nova keypair database, you can assign it to OpenStack Instances upon creation so you can log in via SSH.

Create Neutron Networks
-----------------------

Each OpenStack Instance you spin up must be attached to at least one network. There are two types of Neutron Networks in OpenStack: Neutron __Tenant__ Networks and Neutron __Provider__ Networks.

A whole book could be written describing exactly what each type of network is and does, but in summary, a Neutron Tenant Network is a software defined network that exists solely within the OpenStack environment and a Neutron Provider Network is a network that always maps to a physical network (flat or VLAN) that is terminated on a physical networking device such as a firewall, load balancer, or router. To learn more, I encourage you to read through [this post](https://developer.rackspace.com/blog/beginning-to-understand-neutron-provider-and-tenant-networks-in-openstack.html).

### Create a Neutron Tenant Network

You are going to create a Neutron Tenant Network to attach your OpenStack Instances to.

To create a Neutron Tenant Network, run the following commands:

```sh
neutron net-create tenant-network-1 --shared

neutron subnet-create tenant-network-1 --name tenant-subnet-1 10.240.0.0/24 --gateway 10.240.0.1 --allocation-pool start=10.240.0.100,end=10.240.0.150 --dns-nameservers list=true 8.8.8.8 8.8.4.4
```

### Create a Neutron Provider Network

In order for you to communicate with your OpenStack Instance, which will be attached to the Neutron Tenant Network you just created, you will need to also create a Neutron Provider Network. The Neutron Tenant Network will connect to this Neutron Provider Network through a Neutron Router (another piece of software defined virtual networking).

In this post you will be attaching your OpenStack Instance to the Neutron Tenant Network you just created, but you could also attach your OpenStack Instance to this Neutron Provider Network if you do not want to deal with the software defined networking.

To create a Neutron Provider Network, run the following commands:

```sh
neutron net-create provider-network-1 --provider:physical_network=ph-eth3 --provider:network_type=flat --shared --router:external=True

neutron subnet-create provider-network-1 192.168.244.0/24 --name provider-subnet-1 --gateway 192.168.244.10 --allocation-pool start=192.168.244.100,end=192.168.244.150 --dns-nameservers list=true 8.8.8.8 8.8.4.4
```

Create a Neutron Router and Attach the Neutron Provider and Tenant Networks
---------------------------------------------------------------------------

OpenStack Instances connected to a Neutron Tenant Network are only accessible within the Neutron Tenant Network's respective Network Namespace on the OpenStack network nodes (in this case the network nodes _are_ the controller nodes).

One way to provide external connectivity to those OpenStack Instances is to attach the Neutron Tenant Network to a Neutron Router which is also connected to a Neutron Provider Network (this gives the Neutron Router external connectivity). Once all of this is connected, and assuming the Neutron Provider Network connected to the Neutron Router has access to the internet, your OpenStack Instances will have access to the internet.

In addition, if you setup Neutron Floating IP addresses (which you will in the next section), you can access your OpenStack Instances externally.

To create a Neutron Router, run the following command:

```sh
neutron router-create router1
```

With the Neutron Router created, you can now attach many Neutron Tenant Networks and one Neutron Provider Network to it.

To attach the Neutron Tenant Network __tenant-subnet-1__ that you created above, run the following command:

```sh
neutron router-interface-add router1 tenant-subnet-1
```

To attach the Neutron Provider Network __provider-network-1__ as the default gateway for the Neutron Router, run the following command:

```sh
neutron router-gateway-set router1 provider-network-1
```

Create Neutron Floating IP Addresses
------------------------------------

The OpenStack Instances you spin up will be assigned IP address in the 10.240.0.0/24 network which is a Neutron Tenant Network isolated to your OpenStack environment; you cannot communicate with this network from your workstation and you will only be able to communicate with this network from within the Network Namespace on your OpenStack controller nodes.

However, you can communicate with the 192.168.244.0/24 network from your workstation. So, since you have already created a flat Neutron Provider Network and a Neutron Router (which has a default gateway on the 192.168.244.0/24 network), you can create floating IP addresses within the 192.168.244.0/24 network, assign them to your OpenStack Instances, and begin communicating with your OpenStack Instances from your workstation.

To create floating IP addresses from the __provider-network-1__ Neutron Provider Network, run the following command:

```sh
neutron floatingip-create provider-network-1
```

This command is a bit odd. If you need N number of floating IP addresses you run the command N number of times. 

To see all of the allocated floating IP addresses, run `neutron floatingip-list`.

You will attach one of these floating IP address to your OpenStack Instance in the __Communicate With Your OpenStack Instance__ section below.

Spin Up Your First OpenStack Instance
-------------------------------------

You are now ready to spin up your first OpenStack Instance.

First, you will need to get the ID of Neutron Tenant Network, __tenant-network-1__, you created earlier by running `neutron net-list`, and copying the __id__.

Second, create the OpenStack Instance by running the following command:

```sh
nova boot test1 --image cirros-0.3.2-x86_64 --flavor m1.supertiny --key-name workstation --nic net-id=ID_OF_TENANT_NETWORK_1
```

Because you are using software virtualization, it may take a couple of minutes for the OpenStack Instance to be created. You can monitor the progress by running `nova console-log test1`.

Assign a Floating IP Address to Your OpenStack Instance
-------------------------------------------------------

You already allocated N number of floating IP addresses, so now it is time to assign one of those floating IP addresses to your OpenStack Instance.

First, you will need to get the __id__ of one of the floating IP addresses. Run `neutron floatingip-list`. Choose any floating IP address that is not currently assigned to an OpenStack Instance and copy the __id__.

Second, you will need to get the __id__ of the Neutron Port your OpenStack Instance is connected to. Run `neutron port-list`, find the row with IP address __10.240.0.100__, and copy the __id__.

Now you can assign the floating IP address to your OpenStack Instance by running the following command:

```sh
neutron floatingip-associate ID_FLOATING_IP ID_NEUTRON_PORT
```

After a couple of seconds, the floating IP address will be assigned.

Communicate With Your OpenStack Instance
----------------------------------------

With your OpenStack Instance booted and a floating IP address assigned to it, you can communicate with it through its floating IP address or through its IP address inside of its Network Namespace.

### Communicate through its Floating IP Address

You should now be able to open the terminal application on your workstation and ping or SSH into your OpenStack Instance using the floating IP address you just assigned to it.

Log in via SSH as user __cirros__ with password __cubswin:)__.

### Communicate through its Network Namespace

In addition, because your OpenStack Instance is connected to a Neutron Tenant Network, the OpenStack Instance is isolated within a Network Namespace on the OpenStack controller node. If you did not have a floating IP address assigned to your OpenStack Instance, you would need to run ping and SSH to your OpenStack Instance from inside of the particular Network Namespace it is part of on the OpenStack controller nodes. 

On the OpenStack controller node, run `ip netns list`. There should be one entry returned that starts with __qdhcp__ followed by a __dash__ followed by a __UUID__ which matches the ID of the Neutron Tenant Network you created above. The network stack of the Neutron Tenant Network you created above runs within this Network Namespace and is isolated from everything else. If you created another Neutron Tenant Network, another Network Namespace would be created and it too would be isolated from everything else.

To run commands inside the Network Namespace, copy the name of the Network Namespace returned from the command above (I'm going to use __qdhcp-24cc7957-ee4b-4395-bb5b-c6d509b9db77__ as an example), and run `ip netns exec qdhcp-24cc7957-ee4b-4395-bb5b-c6d509b9db77 COMMAND`.

For example, to see the routing table inside the Network Namespace, run `ip netns exec qdhcp-24cc7957-ee4b-4395-bb5b-c6d509b9db77 route -n`. The output should look similar to the following:

```sh
root@controller1:~# ip netns exec qdhcp-24cc7957-ee4b-4395-bb5b-c6d509b9db77 route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.240.0.0      0.0.0.0         255.255.255.0   U     0      0        0 tapc8b4310c-d5
169.254.0.0     0.0.0.0         255.255.0.0     U     0      0        0 tapc8b4310c-d5
```

If you run `route -n` from your OpenStack controller node, the output would look completely different because your controller node has a completely different network stack compared to the network stack of the Network Namespace.

To ping the OpenStack Instance you created above, run `nova list` to obtain the IP address assigned to your OpenStack Instance (I'm going to use __10.240.0.100__ as an example), then run `ip netns exec qdhcp-24cc7957-ee4b-4395-bb5b-c6d509b9db77 ping 10.240.0.100`. Because you added a rule to the __default__ Neutron Security Group to allow ICMP, you should have a successful ping. 

To SSH into your OpenStack Instance run `ip netns exec qdhcp-24cc7957-ee4b-4395-bb5b-c6d509b9db77 ssh ubuntu@10.240.0.100`. Because you added a rule to the __default__ Neutron Security Group to allow SSH, you should be able to log in to the OpenStack Instance (for this to work you will need to put the SSH private key on your workstation into __/root/.ssh/id_rsa__ on the controller1 node and also run `chmod 600 /root/.ssh/id_rsa` on the controller1 node).

What's Next
-----------

At this point you have seen how to upload images to Glance, add rules to the default Neutron Security Group, create a new flavor, create your SSH keypair, create Neutron Networks, create a Neutron Router, attach Neutron Networks to Neutron Routers, create and attach Neutron Floating IP addresses, and, finally, how to spin up your first OpenStack Instance using the Horizon Dashboard and the OpenStack Python command line tools.

Being able to do all of these things using the Horizon Dashboard or the OpenStack Python command line tools gives you a fantastic foundation to administering and using your Rackspace Private Cloud.

This concludes the second of several posts in the [RPC Insights series](http://www.rackspace.com/blog/welcome-to-rpc-insights/).

Join us on July 30, 2014 at 10:00 AM CDT for a live webinar on [Using Rackspace Private Cloud to Host Your Web Tier Applications](http://go.rackspace.com/rpc-to-host-your-web-tier-applications.html).