---
layout: post
title: Automate creating Rackspace Cloud Load Balancer
date: '2014-11-17 23:59'
comments: true
author: Walter Bentley
published: true
categories:
  - Ansible
---

Recently I embarked on a customer project where they wanted to dynamically create (automate) a complete application stack, starting from the base server provisioning all the way up to the application deployment.  One piece of the puzzle, previously seen as something to be done manually but now considered as part of the stack, is load balancers and any configurations related to load balancing.  

There was an earlier blog post from Jesse Keating on [Rolling Deployments with Ansible and Cloud Load Balancers](https://developer.rackspace.com/blog/rolling-deployments-with-ansible-and-cloud-load-balancers/), which also covered automating creating load balancers with Ansible.  The major difference with this post is adding in the additional capability to not only create the load balancer but, also a DNS record to associate with it, enable SSL termination and adding an SSL certificate to that load balancer.

<!-- more -->
**In this exercise, we step through the automation process:**
   * Create a Cloud Load Balancer
   * Create a DNS subdomain associated with the load balancer
   * Enable SSL Termination and add an SSL certificate


Currently, my favorite automation tool is Ansible, so the following discussion uses Ansible and Rackspace Cloud-specific modules to demonstrate using Load Balancers.

####Rackspace Modules for Ansible

The folks over at Ansible did a lot of forward thinking and decided to include numerous modules which integrate, out of the box, into Ansible.  The full list of modules can be found at:  [Ansible Modules](https://docs.ansible.com/modules_by_category.html)

The cloud-specific modules can be found under the category of Cloud Modules.  At that point, you can pick your provider of choice.  Of course, my favorite provider is Rackspace.

The modules we will be using for this exercise are the following:


	rax_clb - create/delete a load balancer in Rackspace Cloud
	rax_dns_record - Manage DNS records on Rackspace Cloud DNS

Before getting started, I have a few disclaimers that need to be mentioned.


  1. Most load balancers are tied to subdomains and, based on that thought, I assumed that you have already created a root domain in Cloud DNS.  Please make sure you have created a root domain already, as you will need to reference it when creating the subdomain.
  2. The current Ansible modules do not allow for enabling SSL termination and adding SSL certificates.  In order to accomplish this, you have to utilize the Rackspace Cloud DNS API’s.


Let’s get started!

---
#####Step #1: Clone Repo

Clone the repo below to pull down the roles you will need.  Consider this a working example that you can later alter for your specific needs.

	$ git clone --recursive https://github.com/wbentley15/rax-ansible-lb.git

#####Step #2: Examine roles and populate variables


Take a look at the roles and familiarize yourself with the steps.  All the variables you will need to supply values for can be found below and are located in the group_vars directory within the localhost file:

     lbname: name of load balancer
     lbport:  load balancer port
     lbproto:  load balancer protocol
     lbalgo:  load balancer algorithm
     domain:  root domain name
     lbfqdn:  friendly DNS name for load balancer
     raxkey:  Rackspace API key
     raxuser:  Rackspace Username
     raxregion:  Rackspace region
     raxid: Rackspace Account ID (1)
     ssljson:  location to JSON file with certificate details

*1: You can find this in the API output when authenticating, and this value does not change.*

#####Step #3: Give it a try


Now it is time to give it a try.  Do not forget to edit the `/rax-ansible-lb/group_vars/localhost` file.  

The tricky part in all of this is creating the JSON file used to upload your SSL certificates.  I have provided a example that can be found in the root of the /rax-ansible-lb directory called **add_sslterm.json**.  Add the certificate in text format and have a `\n` inserted at every line return.  Take your time with this part because, one extra character, or a removed space, makes the certificate unusable.  The SSL certificates are validated before being added to the load balancer.  Also, the variable `ssljson` needs to be the full path to where the JSON certificate file exists.  Another note to keep in mind is that your load balancer must be configured with the HTTP protocol and with the port set to 80 in order to add an SSL certificate.

Assuming you already have Ansible install, you can execute the playbook:

	$ cd ~/rax-ansible-lb/
	$ ansible-playbook -i hosts base.yml

Once completed, you should find the newly created load balancer, the SSL certificate added to the load balancer, the SSL redirect enabled, and a corresponding DNS record within the Cloud Control Panel.

You can find detailed reference material on the Rackspace Cloud Load Balancer and Cloud DNS under the Network Services heading here:  https://docs.rackspace.com/
