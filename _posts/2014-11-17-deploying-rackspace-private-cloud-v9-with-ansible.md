---
layout: post
title: Deploying Rackspace Private Cloud v9.0 with Ansible
date: '2014-11-17 23:59'
comments: true
author: Walter Bentley
published: true
categories:
  - rackspace-private-cloud
  - Ansible
  - OpenStack
  - architecture
bio: 'Walter Bentley – Rackspace Private Cloud Solutions Architect – Walter is a new Racker with a diverse background in Production Systems Administration and Solutions Architecture. He brings over 15 years of experience across numerous industries such as Online Marketing, Financial, Insurance, Aviation, Food Industry and Education. In the past, always being the requestor, consumer and advisor to companies to use technologies such as OpenStack, now promoter of OpenStack technology and Cloud educator. You can find him on Twitter as @djstayflypro'
---

In the newest release of the Rackspace Private Cloud (RPC v9.0), we made changes to the reference architecture for improved stability. These changes included a different approach for deploying the cloud internally, which may also interest anyone looking into running the Rackspace private cloud.  The decision to use Ansible going forward was based on two major thoughts: ease of deployment and flexible configuration.  Ansible made it very easy for Rackspace to simplify the overall deployment and give users the ability to reconfigure the deployment as needed to fit their environments.  Are you familiar with Ansible?  If yes…skip the next paragraph and if not, please read on.

<!-- more -->

####What is Ansible?
**Ansible** is an IT automation tool that can be used to configure, deploy and orchestrate many different Infrastructure based tasks.  For example, use Ansible for: system configuration, software deployment, application or infrastructure orchestration, and yes, to eventually replace most infrastructure folks…*just kidding…maybe*?  With my many years of supporting Production based applications, with tools like Ansible on the rise, the writing would have certainly been on the wall.  <u>Major word of advice for Infrastructure engineers…LEARN one of the many orchestration tools and begin to love the term DevOps.</u>

As stated in Ansible’s main delivery statement:
>first and foremost is simplicity and maximum ease of use.

They have certainly accomplished this in a great way!  My time spent working and learning Ansible has been time very well spent.

Here are a few facts about Ansible that is useful to know:

   * It is an Open Source project, with the source available on GitHub
   * No remote daemon or agent is required
   * Manages systems using Secure Shell (SSH) and prefers pre-shared keys (a very cloudy approach, and yes, it does work with traditional authentication also)
   * Code is organized into something called "playbooks" that are written in the standard YAML language
   * Has built in modules that work with various cloud providers (including Rackspace) and that do many administrative tasks
   * If you run into an issue and/or potential bug, do not be shy…report it to them via GitHub…you will be shocked in how quickly they respond

You can find more information about Ansible on their [Intro](http://docs.ansible.com/intro.html) and [Best Practices](http://docs.ansible.com/playbooks_best_practices.html) page.
</br>
####How do you get started?
Since all the OpenStack deployment and environment configuration playbooks are already created, you need to start by provisioning your environment.

**To run RPC v9.0 you need a minimum of:**


   * Deployment Node
   * Infrastructure Node (Control Plane)
   * Logging Node
   * Compute Node
   * Storage Node *(optional, and only needed if you're going to try out Cinder block storage)*

Personally, I have found a few creative ways of doing this locally on my workstation.  For this article, we use the 100% Open Source approach by using **VirtualBox**, **Vagrant** and of course **Ansible**.

Follow the steps below to install Rackspace Private Cloud v9.0.  Keep in mind the full installation guide can be found at: http://docs.rackspace.com/rpc/api/v9/bk-rpc-installation/content/rpc-common-front.html

</br>
####Step 0: Prerequisites


   * The machine where RPC is being deployed must have internet connectivity
   * Machine with at least 8GB RAM, processors with hardware virtualization capability
   * Git, [Virtualbox](https://www.virtualbox.org/manual/ch02.html), [Vagrant](https://docs.vagrantup.com/v2/installation/index.html) and [Ansible](http://docs.ansible.com/intro_installation.html) installed

####Step 1: Provision Target Environment

Clone the following two repositories to pull down the preconfigured Vagrant files:

	$ git clone --recursive https://github.com/wbentley15/vagrant-rpcv901_deploy.git
	$ git clone --recursive https://github.com/wbentley15/vagrant-rpcv901.git

Change directory to ‘vagrant-rpcv901’ and execute the 'vagrant up' command:

    $ vagrant up

This will provision the deployment, infrastructure, and logging node.  It also installs required base software and configuration needed to deploy RPC to target hosts.  Feel free to adjust the Vagrant file to increase RAM available for a particular node and/or add vCPU capacity.  If you plan to deploy with Cinder also, please refer to the full installation guide for details on how to do that.

####Step 2: Provision Deploy Environment

Change directory to ‘vagrant-rpcv901_deploy’ and execute the ‘vagrant up’ command:

	$ vagrant up

This will provision the deployment node.  It also installs base required software and configuration need to deploy RPC to target hosts.

*There are two RPC configuration files that you can configure to change how your RPC environment is deployed and to modify the default values for setting up OpenStack and supporting software (i.e. MariaDB and RabbitMQ).  Those two configuration files are found on the deployment node in the '/etc/rpc_deploy’ directory and are named: rpc_user_config.yml and user_variables.yml. No changes are needed if you are following these instructions.*

####Step 3: Start RPC Deployment

SSH into the deployment node (deploy1) and change directory to  /opt/ansible-lxc-rpc/rpc_deployment/ directory:

	$ vagrant ssh deploy1
    $ sudo su
	$ cd /opt/ansible-lxc-rpc/rpc_deployment/


Ensure internet connectivity by running test FTP commands to all target hosts from the deployment node:

	$ fping 172.29.236.2 172.29.236.5 172.29.236.6 172.29.236.10



If the response to all target hosts was successful, start executing the following playbooks.


The first playbook performs setup for the target hosts with the required software repos, creates the LXC containers, and validates network configuration: *(runtime 15-20 minutes)*

	$ ansible-playbook -e @/etc/rpc_deploy/user_variables.yml playbooks/setup/host-setup.yml

Since the v9.0 reference architecture expects a distributed control plane with a Load Balancer in front, we need to install a load balancer (this playbook installs HAProxy and configures required OpenStack backends): *(runtime 5 minutes)*

	$ ansible-playbook -e @/etc/rpc_deploy/user_variables.yml playbooks/infrastructure/haproxy-install.yml

This playbook installs all support software required to run OpenStack and any additional tools used with RPC: *(runtime 20-25 minutes)*

	$ ansible-playbook -e @/etc/rpc_deploy/user_variables.yml playbooks/infrastructure/infrastructure-setup.yml

The final playbook builds and installs OpenStack components: *(runtime 30-35 minutes)*

	$ ansible-playbook -e @/etc/rpc_deploy/user_variables.yml playbooks/openstack/openstack-setup.yml


As soon as all play books finish with no failures, your environment should be up and running...**Congratulations!**

Now, from your browser, connect to the deployment node (default IP address for the deployment node is 172.29.236.7, unless changed in the Vagrant file) for the “Horizon" dashboard:  https://172.29.236.7.  The default username is “admin” and default password can be found in the `/etc/rpc_deploy/user_variables.yml` file on the deployment node.
</br>

---
####Issues and Trouble Spots
The first clear message I want to deliver is this: if you run into deployment issues please make sure to ask for help and/or report the bug.  This can be done via our GitHub page for Rackspace Private Cloud: http://rcbops.github.io/ansible-lxc-rpc/

</br>
#####Playbooks continuously fail:
If you find that the playbooks continuously fail in different places, you should probably adjust how many parallel tasks Ansible is allowed to run.  This can be done by editing `/opt/ansible-lxc-rpc/rpc_deployment/ansible.cfg` and changing the following values (the default value is 25 but, I normally adjust it to 5)

	from: forks = 25
	to: forks = 5

#####Ansible SSH failure connecting to target hosts:
This issue is usually the result the developer attempting multiple failed deployments and possibly re-provisioning the environment. Never fear, you can fix this easily! On the local machine, remove the ‘known_hosts’ file located in the ‘~/.ssh’ directory. Do not worry, you will not miss this file :).

	$ rm ~/.ssh/known_hosts